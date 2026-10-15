//
//  GalleryViewModels.swift
//  Gradit
//
//  Organiser gallery flows: Add photos and videos (upload, captions, order, cover,
//  audience, publish) and Manage gallery (edit, reorder, select, unpublish, delete).
//

import Foundation
import Observation
import UIKit
internal import os

// MARK: - Add media

@Observable
final class AddEventMediaViewModel {
    /// Where the organiser came from (sets the back target).
    enum Source: String, Hashable { case events, home, notification, detail, gallery }

    enum ItemState: Equatable {
        case uploading(Double)
        case uploaded(String)
        case failed
    }

    struct DraftItem: Identifiable, Equatable {
        let id: String
        let media: PickedMediaRef
        var caption = ""
        var state: ItemState = .uploading(0.08)
        let tint: GalleryTint

        var kind: GalleryMediaKind { media.kind }

        var asGalleryItem: GalleryItem {
            GalleryItem(id: id, kind: media.kind, caption: caption, duration: media.duration,
                        thumbnailURL: nil, mediaURL: media.fileURL, tint: tint,
                        symbol: media.kind == .photo ? "photo.fill" : "play.fill")
        }
    }

    struct Rejected: Identifiable, Equatable {
        let id = UUID().uuidString
        let name: String
        let reason: String
    }

    enum ViewMode: Hashable { case grid, list }
    enum AudienceScope: Hashable { case everyone, groups }

    static let gridPageSize = 12
    static let listPageSize = 6

    let eventID: String
    let source: Source
    private(set) var info: GalleryEventInfo?
    private(set) var options: EventFormOptions?
    private(set) var items: [DraftItem] = []
    private(set) var rejected: [Rejected] = []
    private(set) var coverID: String?
    private(set) var isLoading = false
    private(set) var isPublishing = false
    private(set) var groupCounts: InviteeCounts = .zero
    var errorMessage: String?

    var viewMode: ViewMode = .grid { didSet { showsAll = false } }
    var showsAll = false
    var albumTitle = ""
    var audienceScope: AudienceScope = .everyone
    var stream = "Engineering"
    var department = "CSE"
    var semester = "5"
    var division = "all"
    var roles: Set<EventAudienceRole> = [.students, .parents]
    var allowDownload = true
    var publishLater = false
    var publishAt: Date
    var notifyPush = true
    var showsErrors = false
    var toast: EventToastMessage?
    var editingItemID: String?
    private(set) var publishedGallery: EventGallery?

    private let service: EventServiceProtocol
    private var pickCounter = 1

    init(eventID: String, source: Source, service: EventServiceProtocol, now: Date = .now) {
        self.eventID = eventID
        self.source = source
        self.service = service
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        publishAt = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    func load() async {
        guard info == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let info = try await service.galleryEventInfo(eventID: eventID)
            options = try await service.formOptions()
            self.info = info
            if let gallery = self.info?.gallery {
                albumTitle = gallery.albumTitle
                allowDownload = gallery.allowDownload
            }
            await refreshCounts()
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Add media load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Audience

    var selection: AudienceSelection {
        AudienceSelection(scope: audienceScope == .everyone ? .eventInvitees : .groups, eventID: eventID,
                          stream: stream, department: department, yearSem: semester, section: division, roles: roles)
    }

    func refreshCounts() async {
        guard audienceScope == .groups else { return }
        groupCounts = (try? await service.audienceCounts(for: selection)) ?? .zero
    }

    var recipients: Int {
        audienceScope == .everyone ? (info?.invitees.total ?? 0) : groupCounts.total(for: roles)
    }

    var recipientsLine: String {
        if audienceScope == .everyone, let info {
            let parts = EventAudienceRole.allCases.compactMap { role -> String? in
                let count = info.invitees.count(for: role)
                return count > 0 ? "\(EventFormat.count(count)) \(role.title.lowercased())" : nil
            }
            return String(localized: "Same people as the event invite: \(info.classesText) · \(parts.joined(separator: " and ")).")
        }
        let parts = EventAudienceRole.allCases.filter { roles.contains($0) }
            .map { "\(EventFormat.count(groupCounts.count(for: $0))) \($0.title.lowercased())" }
        return parts.isEmpty ? String(localized: "Nobody selected yet") : parts.joined(separator: " · ")
    }

    func toggleRole(_ role: EventAudienceRole) {
        if roles.contains(role) { roles.remove(role) } else { roles.insert(role) }
    }

    var rolesError: Bool { showsErrors && audienceScope == .groups && roles.isEmpty }

    // MARK: Items

    var photoCount: Int { items.filter { $0.kind == .photo }.count }
    var videoCount: Int { items.filter { $0.kind == .video }.count }
    var uploadingCount: Int { items.filter { if case .uploading = $0.state { true } else { false } }.count }
    var failedCount: Int { items.filter { $0.state == .failed }.count }
    var uploadedCount: Int { items.filter { if case .uploaded = $0.state { true } else { false } }.count }

    var selectedCountText: String {
        items.isEmpty ? String(localized: "0 items") : EventFormat.mediaCount(photos: photoCount, videos: videoCount)
    }

    var effectiveCoverID: String? {
        if let coverID, items.contains(where: { $0.id == coverID }) { return coverID }
        return items.first { $0.kind == .photo }?.id
    }

    var visibleItems: [DraftItem] {
        let limit = viewMode == .grid ? Self.gridPageSize : Self.listPageSize
        return showsAll ? items : Array(items.prefix(limit))
    }

    var hasMore: Bool {
        !showsAll && items.count > (viewMode == .grid ? Self.gridPageSize : Self.listPageSize)
    }

    func index(of id: String) -> Int? { items.firstIndex { $0.id == id } }

    /// Adds picked files; rejected ones are listed with a reason. Valid ones start uploading.
    func add(_ picked: [PickedMedia], message: String? = nil) {
        var accepted: [GalleryMediaKind] = []
        for media in picked {
            if let reason = MediaRules.rejection(for: media) {
                rejected.append(Rejected(name: media.fileName, reason: reason))
                continue
            }
            guard items.count < MediaRules.maxItemsPerUpload else {
                rejected.append(Rejected(name: media.fileName,
                                         reason: String(localized: "Up to \(MediaRules.maxItemsPerUpload) items per upload.")))
                continue
            }
            let tints = GalleryTint.allCases
            let item = DraftItem(id: UUID().uuidString, media: PickedMediaRef(media), tint: tints[items.count % tints.count])
            items.append(item)
            accepted.append(media.kind)
            startUpload(item.id)
        }
        if !accepted.isEmpty {
            toast = EventToastMessage(text: message ?? Self.addedText(accepted))
        }
    }

    private static func addedText(_ kinds: [GalleryMediaKind]) -> String {
        let photos = kinds.filter { $0 == .photo }.count
        let videos = kinds.count - photos
        var parts: [String] = []
        if photos > 0 { parts.append(photos == 1 ? String(localized: "1 photo") : String(localized: "\(photos) photos")) }
        if videos > 0 { parts.append(videos == 1 ? String(localized: "1 video") : String(localized: "\(videos) videos")) }
        return String(localized: "\(parts.joined(separator: " and ")) added.")
    }

    func nextPickIndex() -> Int {
        defer { pickCounter += 1 }
        return pickCounter
    }

    func dismissRejected(_ id: String) {
        rejected.removeAll { $0.id == id }
    }

    private func setState(_ state: ItemState, for id: String) {
        guard let index = index(of: id) else { return }
        items[index].state = state
    }

    private func startUpload(_ id: String) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        let upload = MediaUpload(kind: item.kind, fileName: item.media.fileName, fileURL: item.media.fileURL, data: item.media.data)
        Task {
            let ticker = Task {
                var progress = 0.08
                while !Task.isCancelled, progress < 0.9 {
                    try? await Task.sleep(for: .milliseconds(150))
                    progress += 0.06
                    if case .some(.uploading) = self.items.first(where: { $0.id == id })?.state {
                        self.setState(.uploading(min(progress, 0.9)), for: id)
                    }
                }
            }
            do {
                let uploadID = try await service.uploadMedia(eventID: eventID, upload: upload)
                ticker.cancel()
                setState(.uploaded(uploadID), for: id)
            } catch {
                ticker.cancel()
                AppLogger.app.error("Media upload failed: \(error.localizedDescription)")
                setState(.failed, for: id)
            }
        }
    }

    func retry(_ id: String) {
        setState(.uploading(0.08), for: id)
        startUpload(id)
    }

    func remove(_ id: String) {
        items.removeAll { $0.id == id }
        if editingItemID == id { editingItemID = nil }
    }

    func move(_ id: String, by offset: Int) {
        guard let from = index(of: id) else { return }
        let to = from + offset
        guard items.indices.contains(to) else { return }
        items.swapAt(from, to)
    }

    func setCaption(_ caption: String, for id: String) {
        guard let index = index(of: id) else { return }
        items[index].caption = caption
    }

    func setCover(_ id: String) {
        guard let item = items.first(where: { $0.id == id }), item.kind == .photo else { return }
        coverID = id
        let number = (index(of: id) ?? 0) + 1
        toast = EventToastMessage(text: String(localized: "Cover photo set: \(item.caption.isEmpty ? String(localized: "photo \(number)") : item.caption)"))
    }

    // MARK: Publish

    var blockingBanner: String? {
        if failedCount > 0 {
            return failedCount == 1
                ? String(localized: "1 item failed to upload. Tap Retry or remove it before publishing.")
                : String(localized: "\(failedCount) items failed to upload. Tap Retry or remove them before publishing.")
        }
        guard showsErrors else { return nil }
        if uploadingCount > 0 { return String(localized: "Wait for uploads to finish, then publish.") }
        if !canPublish { return String(localized: "Fix the highlighted items before publishing.") }
        return nil
    }

    var itemsError: Bool { showsErrors && items.isEmpty }

    var canPublish: Bool {
        !items.isEmpty && uploadingCount == 0 && failedCount == 0 && !(audienceScope == .groups && roles.isEmpty)
    }

    var publishTitle: String { publishLater ? String(localized: "Schedule") : String(localized: "Publish") }

    var pushDescription: String {
        let name = info?.title ?? ""
        return String(localized: "“Photos from \(name) are now available” to \(EventFormat.count(recipients)) people")
    }

    private func request() -> GalleryPublishRequest {
        let uploaded: [GalleryPublishRequest.Item] = items.compactMap { item in
            guard case .uploaded(let uploadID) = item.state else { return nil }
            return GalleryPublishRequest.Item(uploadID: uploadID, kind: item.kind, caption: item.caption.trimmed,
                                              duration: item.media.duration)
        }
        let coverUpload = items.first { $0.id == effectiveCoverID }.flatMap { item -> String? in
            if case .uploaded(let uploadID) = item.state { return uploadID }
            return nil
        }
        return GalleryPublishRequest(eventID: eventID, albumTitle: albumTitle.trimmed, items: uploaded,
                                     coverUploadID: coverUpload, audience: selection, allowDownload: allowDownload,
                                     publishAt: publishLater ? publishAt : nil, notifyPush: notifyPush)
    }

    /// Validates first; on success `publishedGallery` is set.
    func publish() async -> Bool {
        guard canPublish else {
            showsErrors = true
            toast = nil
            return false
        }
        isPublishing = true
        defer { isPublishing = false }
        do {
            publishedGallery = try await service.publishGallery(request())
            return true
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
            return false
        }
    }

    func saveDraft() async {
        do {
            try await service.saveGalleryDraft(request())
            let time = EventFormat.time(.now)
            toast = EventToastMessage(
                text: String(localized: "Draft saved at \(time). Only you can see it. Open it again from \(info?.title ?? "") in My events."),
                tone: .info)
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
        }
    }

    /// Receiver preview built from the local selection.
    var previewGallery: EventGallery {
        EventGallery(
            eventID: eventID, eventTitle: info?.title ?? "", albumTitle: albumTitle.trimmed,
            start: info?.start ?? .now, end: info?.end ?? .now, venue: info?.venue ?? "",
            coverID: effectiveCoverID, allowDownload: allowDownload, sharedBy: String(localized: "You"),
            publishedAt: .now, isPublished: true, views: 0, audienceCount: recipients,
            audienceText: recipientsLine, items: items.map(\.asGalleryItem))
    }

    var localImages: [String: UIImage] {
        Dictionary(uniqueKeysWithValues: items.compactMap { item in item.media.thumbnail.map { (item.id, $0) } })
    }
}

/// Reference wrapper so draft items stay cheap to copy and compare.
nonisolated final class PickedMediaRef: Equatable {
    let kind: GalleryMediaKind
    let fileName: String
    let thumbnail: UIImage?
    let data: Data?
    let fileURL: URL?
    let duration: String?

    init(_ media: PickedMedia) {
        kind = media.kind
        fileName = media.fileName
        thumbnail = media.thumbnail
        data = media.data
        fileURL = media.fileURL
        duration = media.duration
    }

    static func == (lhs: PickedMediaRef, rhs: PickedMediaRef) -> Bool { lhs === rhs }
}

// MARK: - Manage gallery

@Observable
final class ManageGalleryViewModel {
    enum Mode: Hashable { case view, select, reorder }
    enum Dialog: Identifiable {
        case deleteItems, unpublish, deleteGallery
        var id: Self { self }
    }

    static let gridPageSize = 15
    static let reorderPageSize = 8

    let eventID: String
    private(set) var gallery: EventGallery?
    private(set) var isLoading = false
    private(set) var isWorking = false
    var errorMessage: String?

    var mode: Mode = .view { didSet { showsAll = false } }
    var tab: EventGalleryViewModel.Tab = .all { didSet { showsAll = false } }
    var selection: Set<String> = []
    var showsAll = false
    var toast: EventToastMessage?
    var dialog: Dialog?
    var editingItemID: String?
    var showsCoverPicker = false
    var pendingCoverID: String?

    private let service: EventServiceProtocol

    init(eventID: String, service: EventServiceProtocol) {
        self.eventID = eventID
        self.service = service
    }

    func load() async {
        isLoading = gallery == nil
        defer { isLoading = false }
        do {
            gallery = try await service.organiserGallery(eventID: eventID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Manage gallery load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    var items: [GalleryItem] { gallery?.items ?? [] }
    var coverID: String? { gallery?.cover?.id }

    func count(_ tab: EventGalleryViewModel.Tab) -> Int {
        switch tab {
        case .all: items.count
        case .photos: gallery?.photoCount ?? 0
        case .videos: gallery?.videoCount ?? 0
        }
    }

    var filtered: [GalleryItem] {
        guard mode != .reorder else { return items }
        switch tab {
        case .all: return items
        case .photos: return items.filter { $0.kind == .photo }
        case .videos: return items.filter { $0.kind == .video }
        }
    }

    var visible: [GalleryItem] {
        let limit = mode == .reorder ? Self.reorderPageSize : Self.gridPageSize
        return showsAll ? filtered : Array(filtered.prefix(limit))
    }

    var hasMore: Bool {
        !showsAll && filtered.count > (mode == .reorder ? Self.reorderPageSize : Self.gridPageSize)
    }

    func index(of id: String) -> Int? { items.firstIndex { $0.id == id } }

    var selectionText: String {
        let photos = items.filter { selection.contains($0.id) && $0.kind == .photo }.count
        let videos = items.filter { selection.contains($0.id) && $0.kind == .video }.count
        var parts: [String] = []
        if photos > 0 { parts.append(photos == 1 ? String(localized: "1 photo") : String(localized: "\(photos) photos")) }
        if videos > 0 { parts.append(videos == 1 ? String(localized: "1 video") : String(localized: "\(videos) videos")) }
        return parts.joined(separator: String(localized: " and "))
    }

    // MARK: Local edits (saved right away)

    private func persist(_ message: EventToastMessage? = nil) async {
        guard let gallery else { return }
        do {
            try await service.updateGallery(eventID: eventID, items: gallery.items, coverID: gallery.coverID)
            if let message { toast = message }
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
        }
    }

    func setCaption(_ caption: String, for id: String) {
        guard let index = index(of: id) else { return }
        gallery?.items[index].caption = caption
    }

    func commitCaptions() async { await persist() }

    func move(_ id: String, by offset: Int) {
        guard let from = index(of: id) else { return }
        let to = from + offset
        guard items.indices.contains(to) else { return }
        gallery?.items.swapAt(from, to)
    }

    func finishReorder() async {
        mode = .view
        await persist(EventToastMessage(text: String(localized: "New order saved. Receivers see it right away.")))
    }

    func setCover(_ id: String) async {
        guard items.first(where: { $0.id == id })?.kind == .photo else { return }
        gallery?.coverID = id
        editingItemID = nil
        showsCoverPicker = false
        await persist(EventToastMessage(text: String(localized: "Cover photo changed.")))
    }

    func toggleSelection(_ id: String) {
        if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
    }

    func startSelecting() {
        selection = []
        toast = nil
        mode = .select
    }

    func cancelSelecting() {
        selection = []
        mode = .view
    }

    func deleteItem(_ id: String) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.deleteGalleryItems(eventID: eventID, itemIDs: [id])
            gallery?.items.removeAll { $0.id == id }
            editingItemID = nil
            toast = EventToastMessage(text: String(localized: "Deleted 1 item. Receivers no longer see it."), tone: .danger)
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
        }
    }

    func deleteSelected() async {
        let ids = selection
        let text = selectionText
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.deleteGalleryItems(eventID: eventID, itemIDs: Array(ids))
            gallery?.items.removeAll { ids.contains($0.id) }
            selection = []
            mode = .view
            dialog = nil
            toast = EventToastMessage(text: String(localized: "Deleted \(text)."), tone: .danger)
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
        }
    }

    func setPublished(_ published: Bool) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.setGalleryPublished(eventID: eventID, published: published)
            gallery?.isPublished = published
            dialog = nil
            let audience = EventFormat.count(gallery?.audienceCount ?? 0)
            toast = EventToastMessage(text: published
                ? String(localized: "Gallery published again for \(audience) people.")
                : String(localized: "Gallery unpublished. Receivers can’t see it now."))
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
        }
    }

    /// Returns true when the gallery was deleted.
    func deleteGallery() async -> Bool {
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.deleteGallery(eventID: eventID)
            dialog = nil
            return true
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
            return false
        }
    }
}
