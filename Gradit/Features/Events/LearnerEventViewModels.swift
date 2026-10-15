//
//  LearnerEventViewModels.swift
//  Gradit
//
//  View models for students and parents: Events (list / calendar), Event detail
//  with RSVP, and the Gallery.
//

import Foundation
import Observation
import UIKit
internal import os

// MARK: - Events list

@Observable
final class LearnerEventsViewModel {
    enum Filter: Hashable, Identifiable {
        case all, week, month, gallery
        case category(EventCategory)

        var id: String {
            if case .category(let category) = self { return category.rawValue }
            return String(describing: self)
        }

        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .week: String(localized: "This week")
            case .month: String(localized: "This month")
            case .gallery: String(localized: "Gallery")
            case .category(let category): category.title
            }
        }

        var emptyTitle: String {
            switch self {
            case .all: String(localized: "No upcoming events")
            case .week: String(localized: "No events this week")
            case .month: String(localized: "No events this month")
            case .gallery: String(localized: "No galleries yet")
            case .category(.holiday): String(localized: "No holidays coming up")
            case .category(.workshop): String(localized: "No workshops")
            case .category(let category): String(localized: "No \(category.title.lowercased()) events")
            }
        }
    }

    enum Layout: String, CaseIterable { case list, calendar }

    enum Group: String, CaseIterable, Identifiable {
        case today, thisWeek, later, past
        var id: String { rawValue }
        var title: String {
            switch self {
            case .today: String(localized: "Today")
            case .thisWeek: String(localized: "This week")
            case .later: String(localized: "Later")
            case .past: String(localized: "Past")
            }
        }
    }

    static let filters: [Filter] = [.all, .week, .month, .gallery, .category(.cultural), .category(.sports),
                                    .category(.academic), .category(.workshop), .category(.holiday)]

    var filter: Filter = .all
    var searchText = ""
    var layout: Layout = .list
    var selectedDay: Date
    var displayedMonth: Date

    private(set) var events: [LearnerEvent] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var isOffline = false
    private(set) var savedAt: Date?
    private(set) var now: Date
    var errorMessage: String?

    private let service: EventServiceProtocol
    private let calendar = Calendar.current

    init(service: EventServiceProtocol, now: Date = .now) {
        self.service = service
        self.now = now
        selectedDay = Calendar.current.startOfDay(for: now)
        displayedMonth = now
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            events = try await service.learnerEvents()
            now = .now
            savedAt = now
            hasLoaded = true
            isOffline = false
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch let error as URLError where hasLoaded && error.code == .notConnectedToInternet {
            isOffline = true
        } catch {
            AppLogger.app.error("Events load failed: \(error.localizedDescription)")
            if hasLoaded {
                isOffline = true
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func retry() {
        errorMessage = nil
        Task { await load() }
    }

    var upcomingCount: Int { events.filter { !$0.hasEnded(now: now) }.count }

    private func matchesSearch(_ event: LearnerEvent) -> Bool {
        let query = searchText.trimmed.lowercased()
        return query.isEmpty || "\(event.title) \(event.venue)".lowercased().contains(query)
    }

    private func matchesFilter(_ event: LearnerEvent) -> Bool {
        let ended = event.hasEnded(now: now)
        switch filter {
        case .all: return true
        case .gallery: return ended && event.galleryItemCount != nil
        case .week: return !ended && calendar.isDate(event.start, equalTo: now, toGranularity: .weekOfYear)
        case .month: return !ended && calendar.isDate(event.start, equalTo: now, toGranularity: .month)
        case .category(let category): return !ended && event.category == category
        }
    }

    private var matching: [LearnerEvent] {
        events.filter { matchesFilter($0) && matchesSearch($0) }.sorted { $0.start < $1.start }
    }

    var featured: LearnerEvent? {
        guard filter == .all, searchText.isBlank else { return nil }
        return matching.first { $0.isFeatured && !$0.hasEnded(now: now) }
    }

    func group(of event: LearnerEvent) -> Group {
        if event.hasEnded(now: now) { return .past }
        if event.start <= now || calendar.isDate(event.start, inSameDayAs: now) { return .today }
        if calendar.isDate(event.start, equalTo: now, toGranularity: .weekOfYear) { return .thisWeek }
        return .later
    }

    var sections: [(group: Group, events: [LearnerEvent])] {
        let list = matching.filter { $0.id != featured?.id }
        return Group.allCases.compactMap { group -> (group: Group, events: [LearnerEvent])? in
            var items = list.filter { self.group(of: $0) == group }
            if group == .past { items.sort { $0.start > $1.start } }
            return items.isEmpty ? nil : (group, items)
        }
    }

    var isEmpty: Bool { hasLoaded && matching.isEmpty }

    var emptyMessage: String {
        if !searchText.isBlank { return String(localized: "Nothing matches “\(searchText.trimmed)”.") }
        if filter == .gallery { return String(localized: "Photos and videos from past events will show here.") }
        return String(localized: "New events from your college will show here.")
    }

    // MARK: Calendar

    private func days(of event: LearnerEvent) -> [Date] {
        var days: [Date] = []
        var day = calendar.startOfDay(for: event.start)
        let last = calendar.startOfDay(for: event.end)
        while day <= last, days.count < 31 {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    var dayMarks: [Date: Int] {
        var marks: [Date: Int] = [:]
        for event in events where matchesSearch(event) {
            for day in days(of: event) { marks[day, default: 0] += 1 }
        }
        return marks
    }

    var dayEvents: [LearnerEvent] {
        events.filter { matchesSearch($0) && days(of: $0).contains(calendar.startOfDay(for: selectedDay)) }
            .sorted { $0.start < $1.start }
    }

    func selectDay(_ day: Date) {
        selectedDay = calendar.startOfDay(for: day)
    }
}

// MARK: - Event detail (receiver)

@Observable
final class LearnerEventDetailViewModel {
    /// Why RSVP isn't offered.
    struct Block: Equatable {
        enum Tone { case neutral, danger }
        let title: String
        let message: String
        let tone: Tone
    }

    let eventID: String
    let isPreview: Bool
    private(set) var event: LearnerEvent?
    private(set) var gallery: EventGallery?
    private(set) var isLoading = false
    private(set) var isSubmitting = false
    var selection: RSVPResponse?
    var guests = 0
    var showsConfirmation = false
    var errorMessage: String?
    var toast: String?
    private(set) var now: Date

    private let service: EventServiceProtocol?

    init(eventID: String, service: EventServiceProtocol, now: Date = .now) {
        self.eventID = eventID
        self.service = service
        self.now = now
        isPreview = false
    }

    /// Organiser preview of a draft — nothing is sent.
    init(preview event: LearnerEvent, now: Date = .now) {
        eventID = event.id
        self.event = event
        service = nil
        self.now = now
        isPreview = true
    }

    func load() async {
        guard let service, event == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let event = try await service.learnerEvent(id: eventID)
            apply(event)
            now = .now
            errorMessage = nil
            if event.hasEnded(now: now), event.galleryItemCount != nil {
                gallery = try? await service.learnerGallery(eventID: eventID)
            }
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Event load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ event: LearnerEvent) {
        self.event = event
        selection = event.myResponse
        guests = event.myGuests
    }

    var hasEnded: Bool { event?.hasEnded(now: now) ?? false }

    var block: Block? {
        guard let event else { return nil }
        if event.hasEnded(now: now) {
            return Block(title: String(localized: "Ended"), message: String(localized: "This event has ended. RSVP is closed."), tone: .neutral)
        }
        if !event.rsvpRequired {
            return Block(title: String(localized: "No RSVP needed"),
                         message: String(localized: "This is for your information. Nothing to register."), tone: .neutral)
        }
        if event.isRegistrationClosed(now: now), event.myResponse == nil {
            let deadline = event.rsvpDeadline.map(EventFormat.day) ?? ""
            return Block(title: String(localized: "Registration closed"),
                         message: String(localized: "RSVP closed on \(deadline). The standing area is open to everyone."), tone: .neutral)
        }
        if event.isFull, event.myResponse == nil {
            return Block(title: String(localized: "Event full"),
                         message: String(localized: "All \(event.seatLimit ?? 0) seats are taken. We’ll notify you if a seat opens up."),
                         tone: .danger)
        }
        return nil
    }

    var showsRSVP: Bool { (event?.rsvpRequired ?? false) && block == nil }

    /// Chip next to the category ("Event full", "Registration closed", "Ended").
    var stateLabel: (String, Block.Tone)? {
        guard let event else { return nil }
        if event.hasEnded(now: now) { return (String(localized: "Ended"), .neutral) }
        if event.isRegistrationClosed(now: now) { return (String(localized: "Registration closed"), .neutral) }
        if event.isFull { return (String(localized: "Event full"), .danger) }
        return nil
    }

    var showsGuests: Bool { (event?.maxGuests ?? 0) > 0 && selection == .going }

    var seatsLine: String {
        guard let event else { return "" }
        if let seats = event.seatLimit {
            return String(localized: "\(EventFormat.count(event.goingCount)) of \(EventFormat.count(seats)) seats taken")
        }
        return String(localized: "\(EventFormat.count(event.goingCount)) people going so far")
    }

    var currentResponseText: String? {
        guard let response = event?.myResponse, !isPreview else { return nil }
        let guests = event?.myGuests ?? 0
        if response == .going, guests > 0 {
            return guests == 1 ? String(localized: "Going · 1 guest") : String(localized: "Going · \(guests) guests")
        }
        return response.title
    }

    var canSubmit: Bool {
        guard !isPreview, let selection else { return false }
        return selection != event?.myResponse || (selection == .going && guests != event?.myGuests)
    }

    var confirmTitle: String {
        event?.myResponse == nil ? String(localized: "Confirm RSVP") : String(localized: "Update response")
    }

    func changeGuests(by delta: Int) {
        guests = min(max(0, guests + delta), event?.maxGuests ?? 0)
    }

    func submit() async {
        guard let service, let selection, canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let updated = try await service.respond(eventID: eventID, response: selection, guests: selection == .going ? guests : 0)
            apply(updated)
            showsConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Gallery (receiver)

@Observable
final class EventGalleryViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case all, photos, videos
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .photos: String(localized: "Photos")
            case .videos: String(localized: "Videos")
            }
        }
    }

    enum State: Equatable {
        case loading, loaded, empty, offline, unavailable
        case failed(String)
    }

    let eventID: String
    let isPreview: Bool
    private(set) var gallery: EventGallery?
    private(set) var state: State = .loading
    var tab: Tab = .all
    /// Local images for a sender preview, keyed by item id.
    let localImages: [String: UIImage]

    private let service: EventServiceProtocol?

    init(eventID: String, service: EventServiceProtocol) {
        self.eventID = eventID
        self.service = service
        isPreview = false
        localImages = [:]
    }

    init(preview gallery: EventGallery, localImages: [String: UIImage]) {
        eventID = gallery.eventID
        self.gallery = gallery
        self.localImages = localImages
        service = nil
        isPreview = true
        state = gallery.items.isEmpty ? .empty : .loaded
    }

    func load() async {
        guard let service else { return }
        if gallery == nil { state = .loading }
        do {
            let gallery = try await service.learnerGallery(eventID: eventID)
            self.gallery = gallery
            state = gallery.items.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch EventServiceError.galleryUnavailable {
            state = .unavailable
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            state = .offline
        } catch {
            AppLogger.app.error("Gallery load failed: \(error.localizedDescription)")
            state = .failed(error.localizedDescription)
        }
    }

    func retry() {
        state = .loading
        Task { await load() }
    }

    func count(_ tab: Tab) -> Int {
        guard let gallery else { return 0 }
        switch tab {
        case .all: return gallery.items.count
        case .photos: return gallery.photoCount
        case .videos: return gallery.videoCount
        }
    }

    var visibleItems: [GalleryItem] {
        guard let gallery else { return [] }
        switch tab {
        case .all: return gallery.items
        case .photos: return gallery.items.filter { $0.kind == .photo }
        case .videos: return gallery.items.filter { $0.kind == .video }
        }
    }
}
