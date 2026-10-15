//
//  EventMediaSupport.swift
//  Gradit
//
//  System bridges for Events: picking photos / videos (library and camera),
//  checking file rules, saving to the Photos library and adding to Calendar.
//

import SwiftUI
import PhotosUI
import AVFoundation
import Photos
import EventKit
import EventKitUI
import UniformTypeIdentifiers

// MARK: - Picked media

/// A photo or video chosen on the device, before upload.
nonisolated struct PickedMedia: Identifiable {
    let id = UUID().uuidString
    let kind: GalleryMediaKind
    let fileName: String
    let fileExtension: String
    let byteCount: Int
    var thumbnail: UIImage?
    var data: Data?
    var fileURL: URL?
    /// "01:48" for videos.
    var duration: String?
}

/// File rules from Add media: photos JPG, PNG, HEIC up to 10 MB; videos MP4, MOV up to 200 MB.
enum MediaRules {
    static let photoExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "heif"]
    static let videoExtensions: Set<String> = ["mp4", "mov", "m4v"]
    static let maxPhotoBytes = 10 * 1024 * 1024
    static let maxVideoBytes = 200 * 1024 * 1024
    static let maxItemsPerUpload = 100

    /// Why a file can't be added, or nil when it's fine.
    static func rejection(for media: PickedMedia) -> String? {
        let ext = media.fileExtension.lowercased()
        let upper = ext.uppercased()
        switch media.kind {
        case .photo:
            if !photoExtensions.contains(ext) {
                return String(localized: "\(upper) isn’t supported. Use JPG, PNG or HEIC for photos.")
            }
            if media.byteCount > maxPhotoBytes {
                return String(localized: "Too large. Photos can be up to 10 MB.")
            }
        case .video:
            if !videoExtensions.contains(ext) {
                return String(localized: "\(upper) isn’t supported. Use MP4 or MOV for videos.")
            }
            if media.byteCount > maxVideoBytes {
                return String(localized: "Too large. Videos can be up to 200 MB. Trim it or split it into parts.")
            }
        }
        return nil
    }

    static func durationText(seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

/// Copies a picked movie out of the photo library into a temporary file.
nonisolated struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let destination = FileManager.default.temporaryDirectory
                .appending(path: "upload-\(UUID().uuidString)")
                .appendingPathExtension(ext)
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedMovie(url: destination)
        }
    }
}

enum MediaLoader {
    /// Loads a library item. Videos are copied to a temporary file; photos are kept in memory.
    static func load(_ item: PhotosPickerItem, index: Int) async -> PickedMedia? {
        let type = item.supportedContentTypes.first
        let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
        if isVideo {
            guard let movie = try? await item.loadTransferable(type: PickedMovie.self) else { return nil }
            return await videoMedia(at: movie.url, name: "VID_\(index)")
        }
        let ext = type?.preferredFilenameExtension ?? "jpg"
        guard let data = try? await item.loadTransferable(type: Data.self) else { return nil }
        let thumbnail = await UIImage(data: data)?.byPreparingThumbnail(ofSize: CGSize(width: 600, height: 600))
        return PickedMedia(kind: .photo, fileName: "IMG_\(index).\(ext)", fileExtension: ext, byteCount: data.count,
                           thumbnail: thumbnail, data: data, fileURL: nil, duration: nil)
    }

    static func photo(_ image: UIImage, index: Int) async -> PickedMedia? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let thumbnail = await image.byPreparingThumbnail(ofSize: CGSize(width: 600, height: 600))
        return PickedMedia(kind: .photo, fileName: "IMG_\(index).jpg", fileExtension: "jpg", byteCount: data.count,
                           thumbnail: thumbnail, data: data, fileURL: nil, duration: nil)
    }

    static func videoMedia(at url: URL, name: String) async -> PickedMedia {
        let asset = AVURLAsset(url: url)
        let seconds = (try? await asset.load(.duration)).map(CMTimeGetSeconds) ?? 0
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 600, height: 600)
        let frame = try? await generator.image(at: .zero).image
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        let ext = url.pathExtension.isEmpty ? "mov" : url.pathExtension
        return PickedMedia(kind: .video, fileName: "\(name).\(ext)", fileExtension: ext, byteCount: size,
                           thumbnail: frame.map { UIImage(cgImage: $0) }, data: nil, fileURL: url,
                           duration: MediaRules.durationText(seconds: seconds.isFinite ? seconds : 0))
    }
}

// MARK: - Camera

/// Camera capture for photos and videos (requires NSCameraUsageDescription and,
/// for video sound, NSMicrophoneUsageDescription).
struct EventCameraPicker: UIViewControllerRepresentable {
    enum Result {
        case photo(UIImage)
        case video(URL)
    }

    let onFinish: (Result?) -> Void

    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        picker.videoQuality = .typeHigh
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (Result?) -> Void

        init(onFinish: @escaping (Result?) -> Void) {
            self.onFinish = onFinish
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let url = info[.mediaURL] as? URL {
                let destination = FileManager.default.temporaryDirectory
                    .appending(path: "camera-\(UUID().uuidString)")
                    .appendingPathExtension(url.pathExtension.isEmpty ? "mov" : url.pathExtension)
                if (try? FileManager.default.copyItem(at: url, to: destination)) != nil {
                    onFinish(.video(destination))
                } else {
                    onFinish(nil)
                }
            } else if let image = info[.originalImage] as? UIImage {
                onFinish(.photo(image))
            } else {
                onFinish(nil)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish(nil)
        }
    }
}

// MARK: - Photos library

nonisolated enum PhotoLibrarySaverError: LocalizedError {
    case notAllowed, nothingToSave

    var errorDescription: String? {
        switch self {
        case .notAllowed: String(localized: "Allow GradIt to add photos and videos in Settings.")
        case .nothingToSave: String(localized: "This item can’t be saved yet.")
        }
    }
}

/// Saves a gallery item to the phone's Photos app (add-only access).
nonisolated enum PhotoLibrarySaver {
    static var needsPermissionPrompt: Bool {
        PHPhotoLibrary.authorizationStatus(for: .addOnly) == .notDetermined
    }

    static var isDenied: Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        return status == .denied || status == .restricted
    }

    static func requestAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status == .authorized || status == .limited
    }

    /// Downloads remote media first; file URLs are saved directly.
    static func save(mediaURL: URL?, kind: GalleryMediaKind, fallbackImage: UIImage?) async throws {
        if isDenied { throw PhotoLibrarySaverError.notAllowed }
        if let mediaURL {
            let fileURL: URL
            if mediaURL.isFileURL {
                fileURL = mediaURL
            } else {
                let (downloaded, _) = try await URLSession.shared.download(from: mediaURL)
                let ext = mediaURL.pathExtension.isEmpty ? (kind == .photo ? "jpg" : "mp4") : mediaURL.pathExtension
                fileURL = FileManager.default.temporaryDirectory.appending(path: "save-\(UUID().uuidString)").appendingPathExtension(ext)
                try FileManager.default.moveItem(at: downloaded, to: fileURL)
            }
            try await PHPhotoLibrary.shared().performChanges {
                if kind == .photo {
                    _ = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
                } else {
                    _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                }
            }
        } else if let fallbackImage, kind == .photo {
            try await PHPhotoLibrary.shared().performChanges {
                _ = PHAssetChangeRequest.creationRequestForAsset(from: fallbackImage)
            }
        } else {
            throw PhotoLibrarySaverError.nothingToSave
        }
    }
}

extension GalleryItem {
    /// Renders the placeholder tile, used when an item has no file yet (mock data).
    @MainActor
    func renderedPlaceholder(side: CGFloat = 1080) -> UIImage? {
        let renderer = ImageRenderer(content: GalleryTileView(item: self, cornerRadius: 0, symbolSize: side * 0.2)
            .frame(width: side, height: side))
        renderer.scale = 1
        return renderer.uiImage
    }
}

// MARK: - Calendar

/// Apple's "New Event" editor, prefilled. On iOS 17+ it needs no calendar permission.
struct AddToCalendarSheet: UIViewControllerRepresentable {
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let location: String
    var notes: String?
    let onFinish: (Bool) -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.isAllDay = isAllDay
        event.location = location
        event.notes = notes
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onFinish: (Bool) -> Void

        init(onFinish: @escaping (Bool) -> Void) {
            self.onFinish = onFinish
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            onFinish(action == .saved)
        }
    }
}

/// Link used when sharing an event or gallery item. Placeholder path — align with the web app.
enum EventShareLinks {
    static func event(_ id: String) -> URL {
        AppConfig.baseURL.appending(path: "share/events/\(id)")
    }

    static func galleryItem(eventID: String, item: GalleryItem) -> URL {
        if let url = item.mediaURL, !url.isFileURL { return url }
        return AppConfig.baseURL.appending(path: "share/events/\(eventID)/gallery/\(item.id)")
    }
}
