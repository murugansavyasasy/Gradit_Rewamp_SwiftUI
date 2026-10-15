//
//  EventGalleryModels.swift
//  Gradit
//
//  Photos and videos an organiser shares after an event ends.
//  Design: canvas › 12 Events › Add media, Manage gallery, Gallery, Viewer.
//

import Foundation

nonisolated enum GalleryMediaKind: String, Codable, Sendable {
    case photo, video

    var title: String {
        switch self {
        case .photo: String(localized: "Photo")
        case .video: String(localized: "Video")
        }
    }
}

/// Placeholder colour used while a thumbnail loads (and for items without one).
nonisolated enum GalleryTint: String, Codable, Sendable, CaseIterable {
    case green, royal, ink, navy, amber, sand, blue, sky, mint
}

nonisolated struct GalleryItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var kind: GalleryMediaKind
    var caption: String
    /// "03:10" for videos.
    var duration: String?
    var thumbnailURL: URL?
    var mediaURL: URL?
    var tint: GalleryTint
    /// SF Symbol drawn on the placeholder.
    var symbol: String

    var accessibilityText: String {
        let base: String
        switch kind {
        case .photo: base = String(localized: "Photo")
        case .video: base = String(localized: "Video, \(duration ?? "")")
        }
        return caption.isEmpty ? base : "\(base): \(caption)"
    }
}

nonisolated struct EventGallery: Codable, Identifiable, Hashable, Sendable {
    let eventID: String
    var eventTitle: String
    /// "Sports Day 2026 – highlights"; falls back to the event title.
    var albumTitle: String
    var start: Date
    var end: Date
    var venue: String
    var coverID: String?
    var allowDownload: Bool
    var sharedBy: String
    var publishedAt: Date?
    var isPublished: Bool
    var views: Int
    var audienceCount: Int
    /// "Everyone who was invited · B.E. CSE Sem 5 A, B · Students and Parents"
    var audienceText: String
    var items: [GalleryItem]

    var id: String { eventID }

    var photoCount: Int { items.filter { $0.kind == .photo }.count }
    var videoCount: Int { items.filter { $0.kind == .video }.count }

    /// The chosen cover, or the first photo.
    var cover: GalleryItem? {
        items.first { $0.id == coverID && $0.kind == .photo } ?? items.first { $0.kind == .photo }
    }

    var displayTitle: String { albumTitle.isEmpty ? eventTitle : albumTitle }
}

/// Everything the organiser chose on Add media, sent when publishing.
nonisolated struct GalleryPublishRequest: Codable, Hashable, Sendable {
    nonisolated struct Item: Codable, Hashable, Sendable {
        /// Server id returned by `uploadMedia`.
        var uploadID: String
        var kind: GalleryMediaKind
        var caption: String
        var duration: String?
    }

    var eventID: String
    var albumTitle: String
    var items: [Item]
    var coverUploadID: String?
    var audience: AudienceSelection
    var allowDownload: Bool
    var publishAt: Date?
    var notifyPush: Bool
}

/// A file picked on the device, ready to upload.
nonisolated struct MediaUpload: Sendable {
    var kind: GalleryMediaKind
    var fileName: String
    var fileURL: URL?
    var data: Data?
}

/// Header of the event a gallery belongs to (Add media › event card).
nonisolated struct GalleryEventInfo: Codable, Hashable, Sendable {
    var eventID: String
    var title: String
    var start: Date
    var end: Date
    var isAllDay: Bool
    var venue: String
    var invitees: InviteeCounts
    /// "B.E. CSE Sem 5 A, B"
    var classesText: String
    /// An existing gallery (Add more) or nil for the first upload.
    var gallery: EventGallery?
}
