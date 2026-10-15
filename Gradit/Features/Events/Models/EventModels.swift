//
//  EventModels.swift
//  Gradit
//
//  Payloads for the Events module: staff (Principal / Teacher) create and track
//  events; students and parents browse, RSVP and open the gallery.
//  Design: canvas › 12 Events.
//

import Foundation

// MARK: - Enums

nonisolated enum EventCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case academic, cultural, sports, workshop, parentMeeting, holiday, placement, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .academic: String(localized: "Academic")
        case .cultural: String(localized: "Cultural")
        case .sports: String(localized: "Sports")
        case .workshop: String(localized: "Workshop")
        case .parentMeeting: String(localized: "Parent Meeting")
        case .holiday: String(localized: "Holiday")
        case .placement: String(localized: "Placement")
        case .other: String(localized: "Other")
        }
    }

    var systemImage: String {
        switch self {
        case .academic: "graduationcap.fill"
        case .cultural: "music.note"
        case .sports: "trophy.fill"
        case .workshop: "laptopcomputer"
        case .parentMeeting: "person.2.fill"
        case .holiday: "calendar"
        case .placement: "briefcase.fill"
        case .other: "star.fill"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = EventCategory(rawValue: raw) ?? .other
    }
}

/// Lifecycle of an event as the organiser sees it.
nonisolated enum EventStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case upcoming, ongoing, completed, draft, cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upcoming: String(localized: "Upcoming")
        case .ongoing: String(localized: "Ongoing")
        case .completed: String(localized: "Completed")
        case .draft: String(localized: "Draft")
        case .cancelled: String(localized: "Cancelled")
        }
    }

    /// Tab label on My events ("Past", "Drafts").
    var tabTitle: String {
        switch self {
        case .completed: String(localized: "Past")
        case .draft: String(localized: "Drafts")
        default: title
        }
    }

    var systemImage: String {
        switch self {
        case .upcoming: "clock"
        case .ongoing: "dot.radiowaves.left.and.right"
        case .completed: "checkmark"
        case .draft: "pencil"
        case .cancelled: "nosign"
        }
    }
}

nonisolated enum EventAudienceRole: String, Codable, Sendable, CaseIterable, Identifiable {
    case students, parents, staff

    var id: String { rawValue }

    var title: String {
        switch self {
        case .students: String(localized: "Students")
        case .parents: String(localized: "Parents")
        case .staff: String(localized: "Staff")
        }
    }
}

nonisolated enum RSVPResponse: String, Codable, Sendable, CaseIterable, Identifiable {
    case going, maybe, notGoing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .going: String(localized: "Going")
        case .maybe: String(localized: "Maybe")
        case .notGoing: String(localized: "Not going")
        }
    }

    var systemImage: String {
        switch self {
        case .going: "checkmark"
        case .maybe: "questionmark"
        case .notGoing: "xmark"
        }
    }
}

// MARK: - Shared pieces

/// Head counts per role for an audience.
nonisolated struct InviteeCounts: Codable, Hashable, Sendable {
    var students: Int
    var parents: Int
    var staff: Int

    static let zero = InviteeCounts(students: 0, parents: 0, staff: 0)

    func count(for role: EventAudienceRole) -> Int {
        switch role {
        case .students: students
        case .parents: parents
        case .staff: staff
        }
    }

    func total(for roles: Set<EventAudienceRole>) -> Int {
        roles.reduce(0) { $0 + count(for: $1) }
    }

    var total: Int { students + parents + staff }
}

/// Who an event or gallery is shared with.
nonisolated struct AudienceSelection: Codable, Hashable, Sendable {
    nonisolated enum Scope: String, Codable, Sendable {
        /// Create event › "All (whole college)".
        case wholeCollege
        /// Add media › "Everyone invited" to the event.
        case eventInvitees
        /// Course / department, year, section filters.
        case groups
    }

    var scope: Scope
    var eventID: String?
    var stream: String?
    var department: String
    var yearSem: String
    /// "" = not chosen yet, "all" = every section / division.
    var section: String
    var roles: Set<EventAudienceRole>
}

// MARK: - Organiser (staff)

/// Gallery state shown on an organiser's event card and detail.
nonisolated struct GallerySummary: Codable, Hashable, Sendable {
    var photoCount: Int
    var videoCount: Int
    var views: Int
    var audience: Int
    var isPublished: Bool
    var publishedAt: Date?
    var coverCaption: String?
    var coverTint: GalleryTint
    var coverSymbol: String

    var isEmpty: Bool { photoCount + videoCount == 0 }
}

/// Row on My events.
nonisolated struct StaffEvent: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var category: EventCategory
    var start: Date
    var end: Date
    var isAllDay: Bool
    var venue: String
    var isOnline: Bool
    /// "B.E. CSE Sem 5 A, B · Students, Staff"
    var audienceText: String
    var roles: [EventAudienceRole]
    var goingCount: Int
    var invitedCount: Int
    var isDraft: Bool
    var cancelledAt: Date?
    var cancelReason: String?
    var createdAt: Date
    var editedAt: Date?
    var gallery: GallerySummary?

    func status(now: Date = .now) -> EventStatus {
        if isDraft { return .draft }
        if cancelledAt != nil { return .cancelled }
        if now < start { return .upcoming }
        if now <= end { return .ongoing }
        return .completed
    }
}

nonisolated struct EventAttendee: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// "B.E. CSE · Sem 5 A" / "Staff · CSE" / "Parent · Sem 5 A"
    let classLabel: String
    let regNo: String
    let isStaff: Bool
    var response: RSVPResponse?
    var respondedAt: Date?
}

/// RSVP totals for the whole invite list (the attendee list may be a first page).
nonisolated struct RSVPCounts: Codable, Hashable, Sendable {
    var going: Int
    var maybe: Int
    var notGoing: Int
    var noResponse: Int

    var total: Int { going + maybe + notGoing + noResponse }
}

nonisolated struct EventReminderSettings: Codable, Hashable, Sendable {
    var dayBefore: Bool
    var hourBefore: Bool
    var push: Bool
    var sms: Bool
}

/// Organiser's event detail with attendees.
nonisolated struct StaffEventDetail: Codable, Identifiable, Hashable, Sendable {
    var event: StaffEvent
    var description: String
    var coverCaption: String
    var organiser: String
    var organiserRole: String
    var rsvpRequired: Bool
    var rsvpDeadline: Date?
    var seatLimit: Int?
    var publishedAt: Date?
    var reminders: EventReminderSettings
    var attachments: [AssignmentAttachment]
    var responseCounts: RSVPCounts
    var attendees: [EventAttendee]

    var id: String { event.id }
}

// MARK: - Receiver (student / parent)

nonisolated struct LearnerEvent: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var category: EventCategory
    var start: Date
    var end: Date
    var isAllDay: Bool
    var venue: String
    var isOnline: Bool
    var meetingLink: String?
    var organiser: String
    var organiserRole: String
    var coverCaption: String
    var rsvpRequired: Bool
    /// Last moment an RSVP is accepted.
    var rsvpDeadline: Date?
    var seatLimit: Int?
    var goingCount: Int
    /// Family members a student may bring (0 = no guests).
    var maxGuests: Int
    var myResponse: RSVPResponse?
    var myGuests: Int
    var isFeatured: Bool
    var description: String
    var attachments: [AssignmentAttachment]
    /// Items in a published gallery; nil when the organiser hasn't published one.
    var galleryItemCount: Int?

    func hasEnded(now: Date = .now) -> Bool { now > end }

    func isRegistrationClosed(now: Date = .now) -> Bool {
        guard let rsvpDeadline else { return false }
        return now > rsvpDeadline
    }

    var isFull: Bool {
        guard let seatLimit else { return false }
        return goingCount >= seatLimit
    }

    var paragraphs: [String] {
        description.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Create

nonisolated struct NewEventDraft: Codable, Hashable, Sendable {
    nonisolated enum VenueKind: String, Codable, Sendable { case campus, online }

    /// Set when editing an existing event or draft.
    var id: String?
    var title: String
    var description: String
    var category: EventCategory
    var hasCover: Bool
    var start: Date
    var end: Date
    var isAllDay: Bool
    var venueKind: VenueKind
    var campusLocation: String
    var meetingLink: String
    var audience: AudienceSelection
    var rsvpRequired: Bool
    var rsvpDeadline: Date
    var seatLimit: Int?
    var allowGuests: Bool
    var attachments: [AssignmentAttachment]
    var reminders: EventReminderSettings
    var publishAt: Date?

    var venueText: String {
        venueKind == .online ? String(localized: "Online · \(meetingLink.trimmingCharacters(in: .whitespacesAndNewlines))") : campusLocation
    }
}

// MARK: - Form options

nonisolated struct EventFormOptions: Codable, Hashable, Sendable {
    var campusLocations: [String]
    var courses: [String]
    var yearSems: [String]
    /// Section values: "A", "B", "all".
    var sections: [String]
    /// Gallery "Choose groups" pickers.
    var streams: [String]
    var departments: [String]
    var semesters: [String]
    var divisions: [String]
}

nonisolated enum EventServiceError: LocalizedError, Equatable {
    case galleryUnavailable
    case notFound

    var errorDescription: String? {
        switch self {
        case .galleryUnavailable: String(localized: "The organiser removed this gallery.")
        case .notFound: String(localized: "This event is no longer available.")
        }
    }
}
