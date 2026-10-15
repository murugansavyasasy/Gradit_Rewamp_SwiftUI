//
//  EventService.swift
//  Gradit
//

import Foundation

/// My events header + rows for the signed-in organiser.
nonisolated struct StaffEventList: Codable, Hashable, Sendable {
    /// "Dr. Suresh Kumar · Principal"
    var ownerLine: String
    var events: [StaffEvent]
}

// Small request / response bodies for the live service.
nonisolated private struct IDResponse: Decodable { let id: String }
nonisolated private struct CountResponse: Decodable { let count: Int }
nonisolated private struct ExportResponse: Decodable { let fileName: String }
nonisolated private struct PendingMediaResponse: Decodable { let eventId: String? }
nonisolated private struct GalleryUpdateBody: Encodable { let items: [GalleryItem]; let coverId: String? }
nonisolated private struct GalleryDeleteBody: Encodable { let itemIds: [String] }

protocol EventServiceProtocol {
    // MARK: Organiser (management / faculty)
    func staffEvents(role: UserRole) async throws -> StaffEventList
    func staffEventDetail(id: String) async throws -> StaffEventDetail
    func formOptions() async throws -> EventFormOptions
    func audienceCounts(for selection: AudienceSelection) async throws -> InviteeCounts
    /// Prefills Create event for Edit (same id) or Duplicate (id cleared by the caller).
    func eventDraft(id: String) async throws -> NewEventDraft
    /// Returns the draft's id.
    func saveDraft(_ draft: NewEventDraft) async throws -> String
    func publish(_ draft: NewEventDraft) async throws -> StaffEvent
    /// Reminds everyone who hasn't replied; returns how many were reminded.
    func sendReminder(eventID: String) async throws -> Int
    /// Returns the exported file name.
    func exportAttendees(eventID: String) async throws -> String
    func cancelEvent(id: String, reason: String, notifyInvitees: Bool) async throws
    func deleteEvent(id: String) async throws

    // MARK: Gallery – organiser
    func galleryEventInfo(eventID: String) async throws -> GalleryEventInfo
    /// The most recent completed event without a gallery (Home › "… has ended" prompt).
    func latestEventNeedingMedia() async throws -> String?
    /// Uploads one picked file; returns its upload id.
    func uploadMedia(eventID: String, upload: MediaUpload) async throws -> String
    func saveGalleryDraft(_ request: GalleryPublishRequest) async throws
    func publishGallery(_ request: GalleryPublishRequest) async throws -> EventGallery
    func organiserGallery(eventID: String) async throws -> EventGallery
    func updateGallery(eventID: String, items: [GalleryItem], coverID: String?) async throws
    func deleteGalleryItems(eventID: String, itemIDs: [String]) async throws
    func setGalleryPublished(eventID: String, published: Bool) async throws
    func deleteGallery(eventID: String) async throws

    // MARK: Receiver (student / parent)
    func learnerEvents() async throws -> [LearnerEvent]
    func learnerEvent(id: String) async throws -> LearnerEvent
    func respond(eventID: String, response: RSVPResponse, guests: Int) async throws -> LearnerEvent
    /// Throws `EventServiceError.galleryUnavailable` once the organiser unpublishes or deletes it.
    func learnerGallery(eventID: String) async throws -> EventGallery
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class EventService: EventServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    private func jsonBody(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }

    private func post(_ path: String, _ value: some Encodable, method: HTTPMethod = .post) throws -> Endpoint {
        var endpoint = Endpoint(path: path, method: method)
        endpoint.body = try jsonBody(value)
        return endpoint
    }

    // MARK: Organiser

    func staffEvents(role: UserRole) async throws -> StaffEventList {
        try await client.send(Endpoint(path: "/events/mine"))
    }

    func staffEventDetail(id: String) async throws -> StaffEventDetail {
        try await client.send(Endpoint(path: "/events/\(id)/manage"))
    }

    func formOptions() async throws -> EventFormOptions {
        try await client.send(Endpoint(path: "/events/form-options"))
    }

    func audienceCounts(for selection: AudienceSelection) async throws -> InviteeCounts {
        try await client.send(post("/events/audience-count", selection))
    }

    func eventDraft(id: String) async throws -> NewEventDraft {
        try await client.send(Endpoint(path: "/events/\(id)/draft"))
    }

    func saveDraft(_ draft: NewEventDraft) async throws -> String {
        let saved: IDResponse = try await client.send(post("/events/drafts", draft))
        return saved.id
    }

    func publish(_ draft: NewEventDraft) async throws -> StaffEvent {
        try await client.send(post("/events", draft))
    }

    func sendReminder(eventID: String) async throws -> Int {
        let sent: CountResponse = try await client.send(Endpoint(path: "/events/\(eventID)/remind", method: .post))
        return sent.count
    }

    func exportAttendees(eventID: String) async throws -> String {
        let export: ExportResponse = try await client.send(Endpoint(path: "/events/\(eventID)/attendees/export", method: .post))
        return export.fileName
    }

    func cancelEvent(id: String, reason: String, notifyInvitees: Bool) async throws {
        let endpoint = try Endpoint.json("/events/\(id)/cancel",
                                         body: ["reason": reason, "notify": notifyInvitees ? "true" : "false"])
        try await client.sendRaw(endpoint)
    }

    func deleteEvent(id: String) async throws {
        try await client.sendRaw(Endpoint(path: "/events/\(id)", method: .delete))
    }

    // MARK: Gallery – organiser

    func galleryEventInfo(eventID: String) async throws -> GalleryEventInfo {
        try await client.send(Endpoint(path: "/events/\(eventID)/gallery/context"))
    }

    func latestEventNeedingMedia() async throws -> String? {
        let pending: PendingMediaResponse = try await client.send(Endpoint(path: "/events/gallery/pending"))
        return pending.eventId
    }

    func uploadMedia(eventID: String, upload: MediaUpload) async throws -> String {
        let boundary = "Boundary-\(UUID().uuidString)"
        let fileData: Data
        if let data = upload.data {
            fileData = data
        } else if let url = upload.fileURL {
            fileData = try Data(contentsOf: url)
        } else {
            fileData = Data()
        }
        let mime = upload.kind == .photo ? "image/jpeg" : "video/mp4"
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(upload.fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mime)\r\n\r\n".utf8))
        body.append(fileData)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))

        var endpoint = Endpoint(path: "/events/\(eventID)/gallery/uploads", method: .post)
        endpoint.headers = ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        endpoint.body = body
        let uploaded: IDResponse = try await client.send(endpoint)
        return uploaded.id
    }

    func saveGalleryDraft(_ request: GalleryPublishRequest) async throws {
        try await client.sendRaw(post("/events/\(request.eventID)/gallery/draft", request))
    }

    func publishGallery(_ request: GalleryPublishRequest) async throws -> EventGallery {
        try await client.send(post("/events/\(request.eventID)/gallery", request))
    }

    func organiserGallery(eventID: String) async throws -> EventGallery {
        try await client.send(Endpoint(path: "/events/\(eventID)/gallery/manage"))
    }

    func updateGallery(eventID: String, items: [GalleryItem], coverID: String?) async throws {
        try await client.sendRaw(post("/events/\(eventID)/gallery", GalleryUpdateBody(items: items, coverId: coverID), method: .put))
    }

    func deleteGalleryItems(eventID: String, itemIDs: [String]) async throws {
        try await client.sendRaw(post("/events/\(eventID)/gallery/items/delete", GalleryDeleteBody(itemIds: itemIDs)))
    }

    func setGalleryPublished(eventID: String, published: Bool) async throws {
        let endpoint = try Endpoint.json("/events/\(eventID)/gallery/visibility", method: .put,
                                         body: ["published": published ? "true" : "false"])
        try await client.sendRaw(endpoint)
    }

    func deleteGallery(eventID: String) async throws {
        try await client.sendRaw(Endpoint(path: "/events/\(eventID)/gallery", method: .delete))
    }

    // MARK: Receiver

    func learnerEvents() async throws -> [LearnerEvent] {
        try await client.send(Endpoint(path: "/events"))
    }

    func learnerEvent(id: String) async throws -> LearnerEvent {
        try await client.send(Endpoint(path: "/events/\(id)"))
    }

    func respond(eventID: String, response: RSVPResponse, guests: Int) async throws -> LearnerEvent {
        let endpoint = try Endpoint.json("/events/\(eventID)/rsvp",
                                         body: ["response": response.rawValue, "guests": "\(guests)"])
        return try await client.send(endpoint)
    }

    func learnerGallery(eventID: String) async throws -> EventGallery {
        do {
            return try await client.send(Endpoint(path: "/events/\(eventID)/gallery"))
        } catch APIError.httpStatus(let code) where code == 404 || code == 410 {
            throw EventServiceError.galleryUnavailable
        }
    }
}
