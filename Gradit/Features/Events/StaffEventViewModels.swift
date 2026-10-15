//
//  StaffEventViewModels.swift
//  Gradit
//
//  View models for the organiser flows: My events, Create event and Event detail.
//

import Foundation
import Observation
import UIKit
internal import os

// MARK: - My events

@Observable
final class StaffEventListViewModel {
    enum Sort: String, CaseIterable, Identifiable {
        case soonest, newest
        var id: String { rawValue }
        var title: String {
            switch self {
            case .soonest: String(localized: "Soonest first")
            case .newest: String(localized: "Newest created")
            }
        }
    }

    static let tabOrder: [EventStatus] = [.upcoming, .ongoing, .completed, .draft, .cancelled]

    let role: UserRole
    var tab: EventStatus = .upcoming
    var searchText = ""
    var category: EventCategory?
    var audience: EventAudienceRole?
    var sort: Sort = .soonest

    private(set) var ownerLine = ""
    private(set) var events: [StaffEvent] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var now: Date
    var errorMessage: String?

    private let service: EventServiceProtocol

    init(role: UserRole, service: EventServiceProtocol, now: Date = .now) {
        self.role = role
        self.service = service
        self.now = now
    }

    /// Search, category and audience applied; status not applied.
    private var filtered: [StaffEvent] {
        let query = searchText.trimmed.lowercased()
        return events.filter { event in
            (category == nil || event.category == category)
                && (audience == nil || event.roles.contains(audience!))
                && (query.isEmpty || "\(event.title) \(event.venue)".lowercased().contains(query))
        }
    }

    var tabs: [EventCountTab<EventStatus>] {
        let base = filtered
        return Self.tabOrder.map { status in
            EventCountTab(id: status, title: status.tabTitle, count: base.filter { $0.status(now: now) == status }.count)
        }
    }

    var visible: [StaffEvent] {
        let list = filtered.filter { $0.status(now: now) == tab }
        switch sort {
        case .soonest:
            return tab == .completed ? list.sorted { $0.end > $1.end } : list.sorted { $0.start < $1.start }
        case .newest:
            return list.sorted { $0.createdAt > $1.createdAt }
        }
    }

    var isEmpty: Bool { hasLoaded && events.isEmpty }
    var showsLoading: Bool { isLoading && !hasLoaded }
    var showsError: Bool { errorMessage != nil && !hasLoaded }

    /// First call shows the skeleton; later calls refresh quietly (e.g. coming back from Create).
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let list = try await service.staffEvents(role: role)
            ownerLine = list.ownerLine
            events = list.events
            now = .now
            hasLoaded = true
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("My events load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func retry() {
        errorMessage = nil
        Task { await load() }
    }
}

// MARK: - Event detail (organiser)

@Observable
final class StaffEventDetailViewModel {
    enum ResponseFilter: String, CaseIterable, Identifiable {
        case all, going, maybe, notGoing, noResponse
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .going: String(localized: "Going")
            case .maybe: String(localized: "Maybe")
            case .notGoing: String(localized: "Not going")
            case .noResponse: String(localized: "No response")
            }
        }

        func matches(_ response: RSVPResponse?) -> Bool {
            switch self {
            case .all: true
            case .going: response == .going
            case .maybe: response == .maybe
            case .notGoing: response == .notGoing
            case .noResponse: response == nil
            }
        }
    }

    enum Dialog: Identifiable {
        case cancel, delete
        var id: Self { self }
    }

    static let pageSize = 12

    let eventID: String
    private(set) var detail: StaffEventDetail?
    private(set) var isLoading = false
    private(set) var isWorking = false
    var errorMessage: String?

    var filter: ResponseFilter = .all { didSet { showsAll = false } }
    var searchText = "" { didSet { showsAll = false } }
    var showsAll = false
    var toast: EventToastMessage?
    var dialog: Dialog?
    var cancelReason = String(localized: "Speaker unavailable. A new date will be shared soon.")
    var notifyInvitees = true
    private(set) var now: Date

    private let service: EventServiceProtocol

    init(eventID: String, service: EventServiceProtocol, now: Date = .now) {
        self.eventID = eventID
        self.service = service
        self.now = now
    }

    var status: EventStatus { detail?.event.status(now: now) ?? .upcoming }
    var isPast: Bool { status == .completed }
    var canCancel: Bool { status == .upcoming || status == .ongoing }

    func count(_ filter: ResponseFilter) -> Int {
        detail?.attendees.filter { filter.matches($0.response) }.count ?? 0
    }

    private var matching: [EventAttendee] {
        guard let detail else { return [] }
        let query = searchText.trimmed.lowercased()
        let list = detail.attendees.filter { attendee in
            filter.matches(attendee.response)
                && (query.isEmpty || "\(attendee.name) \(attendee.regNo)".lowercased().contains(query))
        }
        guard filter != .noResponse else { return list }
        return list.sorted { ($0.respondedAt ?? .distantPast) > ($1.respondedAt ?? .distantPast) }
    }

    var matchingCount: Int { matching.count }

    var visibleAttendees: [EventAttendee] {
        showsAll ? matching : Array(matching.prefix(Self.pageSize))
    }

    var hasMore: Bool { !showsAll && matchingCount > Self.pageSize }

    func load() async {
        guard detail == nil else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = detail == nil
        defer { isLoading = false }
        do {
            detail = try await service.staffEventDetail(id: eventID)
            now = .now
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Event detail load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func remind() async {
        do {
            let count = try await service.sendReminder(eventID: eventID)
            toast = EventToastMessage(text: String(localized: "Reminder sent to \(count) people who haven’t replied."))
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
        }
    }

    func exportList() async {
        do {
            let file = try await service.exportAttendees(eventID: eventID)
            toast = EventToastMessage(text: String(localized: "Attendee list exported · \(file)"))
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
        }
    }

    func cancelEvent() async {
        guard let detail else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.cancelEvent(id: eventID, reason: cancelReason.trimmed, notifyInvitees: notifyInvitees)
            dialog = nil
            await refresh()
            let invited = EventFormat.count(detail.event.invitedCount)
            toast = EventToastMessage(
                text: notifyInvitees
                    ? String(localized: "Event cancelled. All \(invited) invitees were notified.")
                    : String(localized: "Event cancelled. Invitees were not notified."),
                tone: .danger)
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
        }
    }

    /// Returns true when the event was deleted.
    func deleteEvent() async -> Bool {
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.deleteEvent(id: eventID)
            dialog = nil
            return true
        } catch {
            toast = EventToastMessage(text: error.localizedDescription, tone: .danger)
            return false
        }
    }
}

// MARK: - Create event

@Observable
final class CreateEventViewModel {
    enum Mode: Hashable {
        case new
        case edit(String)
        case duplicate(String)
    }

    enum DateField: String, Identifiable {
        case start, end, rsvp, publish
        var id: String { rawValue }
        var title: String {
            switch self {
            case .start: String(localized: "Start date")
            case .end: String(localized: "End date")
            case .rsvp: String(localized: "RSVP deadline")
            case .publish: String(localized: "Publish on")
            }
        }
    }

    /// Hourly slots from the design, 08:00 AM – 06:00 PM, as minutes after midnight.
    static let timeSlots: [Int] = Array(stride(from: 8 * 60, through: 18 * 60, by: 30))

    let mode: Mode
    var draft: NewEventDraft
    var coverImage: UIImage?
    private(set) var options: EventFormOptions?
    private(set) var counts: InviteeCounts = .zero
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var isPublishing = false
    var showsErrors = false
    var savedNotice = false
    var errorMessage: String?
    var seatText = ""
    var schedulePublish = false
    var publishedEvent: StaffEvent?

    private let service: EventServiceProtocol
    private let calendar = Calendar.current
    let now: Date

    init(mode: Mode, service: EventServiceProtocol, now: Date = .now) {
        self.mode = mode
        self.service = service
        self.now = now
        draft = Self.blankDraft(now: now)
    }

    static func blankDraft(now: Date) -> NewEventDraft {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        let end = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        return NewEventDraft(
            id: nil, title: "", description: "", category: .academic, hasCover: false,
            start: start, end: end, isAllDay: false, venueKind: .campus, campusLocation: "",
            meetingLink: "",
            audience: AudienceSelection(scope: .groups, eventID: nil, stream: nil, department: "",
                                        yearSem: "", section: "", roles: [.students]),
            rsvpRequired: true, rsvpDeadline: start, seatLimit: nil, allowGuests: false, attachments: [],
            reminders: EventReminderSettings(dayBefore: true, hourBefore: true, push: true, sms: false),
            publishAt: nil)
    }

    var title: String {
        switch mode {
        case .edit: String(localized: "Edit event")
        default: String(localized: "Create event")
        }
    }

    // MARK: Loading

    func load() async {
        guard options == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let options = try await service.formOptions()
            self.options = options
            switch mode {
            case .new:
                draft.campusLocation = options.campusLocations.first ?? ""
                draft.audience.department = options.courses.first ?? ""
                draft.audience.yearSem = options.yearSems.first ?? ""
            case .edit(let id):
                draft = try await service.eventDraft(id: id)
            case .duplicate(let id):
                var copy = try await service.eventDraft(id: id)
                copy.id = nil
                copy.title = String(localized: "\(copy.title) (copy)")
                if copy.start < now {
                    let blank = Self.blankDraft(now: now)
                    copy.start = blank.start
                    copy.end = blank.end
                    copy.rsvpDeadline = blank.start
                }
                draft = copy
            }
            seatText = draft.seatLimit.map(String.init) ?? ""
            schedulePublish = draft.publishAt != nil
            await refreshCounts()
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Create event load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func refreshCounts() async {
        do {
            counts = try await service.audienceCounts(for: draft.audience)
        } catch is CancellationError {
            return
        } catch {
            counts = .zero
        }
    }

    // MARK: Audience

    var invitedTotal: Int { counts.total(for: draft.audience.roles) }

    func toggleRole(_ role: EventAudienceRole) {
        if draft.audience.roles.contains(role) {
            draft.audience.roles.remove(role)
        } else {
            draft.audience.roles.insert(role)
        }
    }

    var audienceChips: [String] {
        var chips: [String] = []
        if draft.audience.scope == .wholeCollege {
            chips.append(String(localized: "Whole college"))
        } else {
            chips.append(draft.audience.department)
            chips.append(draft.audience.yearSem)
            if !draft.audience.section.isEmpty { chips.append(Self.sectionTitle(draft.audience.section)) }
        }
        chips += EventAudienceRole.allCases.filter { draft.audience.roles.contains($0) }.map(\.title)
        return chips.filter { !$0.isEmpty }
    }

    var countLine: String {
        invitedTotal > 0 ? String(localized: "\(EventFormat.count(invitedTotal)) invited") : String(localized: "No one invited yet")
    }

    var countSubline: String {
        let parts = EventAudienceRole.allCases
            .filter { draft.audience.roles.contains($0) && counts.count(for: $0) > 0 }
            .map { "\(EventFormat.count(counts.count(for: $0))) \($0.title.lowercased())" }
        return parts.isEmpty ? String(localized: "Choose a section and at least one group") : parts.joined(separator: " · ")
    }

    static func sectionTitle(_ value: String) -> String {
        switch value {
        case "": String(localized: "Choose section")
        case "all": String(localized: "All sections (A, B)")
        default: String(localized: "Section \(value)")
        }
    }

    // MARK: Dates

    func date(for field: DateField) -> Date {
        switch field {
        case .start: draft.start
        case .end: draft.end
        case .rsvp: draft.rsvpDeadline
        case .publish: draft.publishAt ?? now
        }
    }

    /// Keeps the time of day and changes the day.
    func setDay(_ day: Date, for field: DateField) {
        func moved(_ original: Date) -> Date {
            let parts = calendar.dateComponents([.hour, .minute], from: original)
            return calendar.date(bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0, second: 0, of: day) ?? day
        }
        switch field {
        case .start:
            let length = draft.end.timeIntervalSince(draft.start)
            draft.start = moved(draft.start)
            if draft.end < draft.start || !calendar.isDate(draft.end, inSameDayAs: draft.start) && length < 86_400 {
                draft.end = draft.start.addingTimeInterval(max(length, 3600))
            }
            if draft.rsvpDeadline > draft.start { draft.rsvpDeadline = draft.start }
        case .end: draft.end = moved(draft.end)
        case .rsvp: draft.rsvpDeadline = moved(draft.rsvpDeadline)
        case .publish:
            let base = draft.publishAt ?? calendar.date(bySettingHour: 8, minute: 0, second: 0, of: day) ?? day
            draft.publishAt = moved(base)
        }
    }

    func minutes(of date: Date) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    func setTime(_ minutes: Int, start: Bool) {
        let target = start ? draft.start : draft.end
        let value = calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: target) ?? target
        if start { draft.start = value } else { draft.end = value }
    }

    func timeOptions(including date: Date) -> [Int] {
        let current = minutes(of: date)
        return Self.timeSlots.contains(current) ? Self.timeSlots : (Self.timeSlots + [current]).sorted()
    }

    static func timeLabel(_ minutes: Int) -> String {
        var parts = DateComponents()
        parts.hour = minutes / 60
        parts.minute = minutes % 60
        let date = Calendar.current.date(from: parts) ?? .now
        return EventFormat.time(date)
    }

    // MARK: Validation

    var titleError: String? {
        draft.title.isBlank ? String(localized: "Add an event title.") : nil
    }

    var audienceError: String? {
        if draft.audience.roles.isEmpty { return String(localized: "Invite at least one group: Students, Parents or Staff.") }
        if draft.audience.scope == .groups && draft.audience.section.isEmpty {
            return String(localized: "Choose a section, or switch to All.")
        }
        return nil
    }

    var dateError: String? {
        guard draft.start < calendar.startOfDay(for: now) else { return nil }
        return String(localized: "The start date is in the past. Pick \(EventFormat.shortDay(now)) or later.")
    }

    var timeError: String? {
        let endsBefore = draft.isAllDay
            ? calendar.startOfDay(for: draft.end) < calendar.startOfDay(for: draft.start)
            : draft.end <= draft.start
        return endsBefore ? String(localized: "The end time is before the start time.") : nil
    }

    var linkError: String? {
        draft.venueKind == .online && draft.meetingLink.isBlank ? String(localized: "Add the meeting link.") : nil
    }

    var errorSummary: [String] {
        [
            titleError.map { _ in String(localized: "Event title is missing") },
            audienceError.map { _ in String(localized: "No audience selected") },
            dateError.map { _ in String(localized: "Date is in the past") },
            timeError.map { _ in String(localized: "End time is before the start time") },
            linkError.map { _ in String(localized: "Meeting link is missing") },
        ].compactMap { $0 }
    }

    var isValid: Bool { errorSummary.isEmpty }

    // MARK: Actions

    private func normalizedDraft() -> NewEventDraft {
        var draft = draft
        draft.title = draft.title.trimmed
        draft.description = draft.description.trimmed
        draft.seatLimit = Int(seatText.trimmed).flatMap { $0 > 0 ? $0 : nil }
        draft.hasCover = draft.hasCover || coverImage != nil
        draft.publishAt = schedulePublish ? (draft.publishAt ?? now) : nil
        if draft.isAllDay {
            draft.start = calendar.startOfDay(for: draft.start)
            draft.end = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: draft.end) ?? draft.end
        }
        return draft
    }

    /// Validates first; returns false and shows the error summary when something is missing.
    func publish() async -> Bool {
        guard isValid else {
            showsErrors = true
            return false
        }
        isPublishing = true
        defer { isPublishing = false }
        do {
            publishedEvent = try await service.publish(normalizedDraft())
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func saveDraft() async {
        isSaving = true
        defer { isSaving = false }
        do {
            draft.id = try await service.saveDraft(normalizedDraft())
            savedNotice = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func validateForPreview() -> Bool {
        if !isValid { showsErrors = true }
        return isValid
    }

    /// Start over after "Create another".
    func reset() {
        draft = Self.blankDraft(now: now)
        draft.campusLocation = options?.campusLocations.first ?? ""
        draft.audience.department = options?.courses.first ?? ""
        draft.audience.yearSem = options?.yearSems.first ?? ""
        coverImage = nil
        seatText = ""
        schedulePublish = false
        showsErrors = false
        publishedEvent = nil
        Task { await refreshCounts() }
    }

    /// What students and parents will see (Preview).
    func previewEvent(organiser: String) -> LearnerEvent {
        let draft = normalizedDraft()
        return LearnerEvent(
            id: draft.id ?? "preview", title: draft.title, category: draft.category, start: draft.start, end: draft.end,
            isAllDay: draft.isAllDay, venue: draft.venueText, isOnline: draft.venueKind == .online,
            meetingLink: draft.venueKind == .online ? draft.meetingLink : nil,
            organiser: organiser, organiserRole: "",
            coverCaption: "\(draft.venueKind == .online ? String(localized: "Online") : draft.campusLocation) · \(EventFormat.shortDay(draft.start))",
            rsvpRequired: draft.rsvpRequired, rsvpDeadline: draft.rsvpRequired ? draft.rsvpDeadline : nil,
            seatLimit: draft.seatLimit, goingCount: 0, maxGuests: draft.allowGuests ? 2 : 0,
            myResponse: nil, myGuests: 0, isFeatured: false, description: draft.description,
            attachments: draft.attachments, galleryItemCount: nil)
    }

    /// Facts on the Published screen.
    var publishedFacts: [(String, String)] {
        let invited = invitedTotal
        let roles = EventAudienceRole.allCases
            .filter { draft.audience.roles.contains($0) && counts.count(for: $0) > 0 }
            .map { "\(EventFormat.count(counts.count(for: $0))) \($0.title.lowercased())" }
            .joined(separator: ", ")
        var reminders: [String] = []
        if draft.reminders.dayBefore { reminders.append(String(localized: "1 day")) }
        if draft.reminders.hourBefore { reminders.append(String(localized: "1 hour")) }
        let seats = Int(seatText.trimmed).map { "\($0)" } ?? String(localized: "No limit")
        let reminderText = reminders.isEmpty ? String(localized: "no reminders")
            : String(localized: "reminders \(reminders.joined(separator: " and ")) before")
        return [
            (String(localized: "Audience"), String(localized: "\(EventFormat.count(invited)) invited · \(roles)")),
            (String(localized: "Date"), "\(EventFormat.fullDay(draft.start)) · \(EventFormat.timeRange(start: draft.start, end: draft.end, isAllDay: draft.isAllDay))"),
            (String(localized: "Venue"), draft.venueText),
            (String(localized: "Seats"), "\(seats) · \(reminderText)"),
        ]
    }

    func addAttachment(url: URL) {
        let name = url.lastPathComponent
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        let ext = url.pathExtension.lowercased()
        let kind: AttachmentKind = ext == "pdf" ? .pdf : ["jpg", "jpeg", "png", "heic"].contains(ext) ? .image : .document
        let label: String
        switch kind {
        case .pdf: label = "PDF"
        case .image: label = String(localized: "Image")
        case .document, .voice: label = String(localized: "Document")
        }
        let sizeText = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
        draft.attachments.append(AssignmentAttachment(id: UUID().uuidString, name: name, kind: kind, detail: "\(label) · \(sizeText)"))
    }
}
