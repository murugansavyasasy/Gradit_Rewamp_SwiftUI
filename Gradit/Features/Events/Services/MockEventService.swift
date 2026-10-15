//
//  MockEventService.swift
//  Gradit
//
//  In-memory events used in DEBUG, previews and tests. Content mirrors the design
//  canvas (12 Events); dates are placed relative to today so the list always has
//  something upcoming, ongoing and past. Changes (publish, RSVP, gallery edits)
//  are kept for the life of the app so every role sees them.
//

import Foundation

final class MockEventService: EventServiceProtocol {
    private let latency: Duration
    private let calendar = Calendar.current
    private let today: Date

    private var events: [StaffEvent] = []
    private var details: [String: StaffEventDetail] = [:]
    private var learner: [LearnerEvent] = []
    private var galleries: [String: EventGallery] = [:]
    private var removedGalleries: Set<String> = []
    private var uploads: [String: MediaUpload] = [:]
    private var nextID = 1

    /// Set in tests to make every call fail.
    var failure: Error?

    init(latency: Duration = .milliseconds(300), now: Date = .now) {
        self.latency = latency
        today = Calendar.current.startOfDay(for: now)
        seed(now: now)
    }

    private func wait() async throws {
        try await Task.sleep(for: latency)
        if let failure { throw failure }
    }

    // MARK: - Organiser

    func staffEvents(role: UserRole) async throws -> StaffEventList {
        try await wait()
        let owner = role == .faculty ? "Dr. Meena Krishnan · CSE" : "Dr. Suresh Kumar · Principal"
        return StaffEventList(ownerLine: owner, events: events.map(withGallerySummary))
    }

    func staffEventDetail(id: String) async throws -> StaffEventDetail {
        try await wait()
        guard var detail = details[id] else { throw EventServiceError.notFound }
        detail.event = withGallerySummary(detail.event)
        return detail
    }

    func formOptions() async throws -> EventFormOptions {
        try await wait()
        return EventFormOptions(
            campusLocations: ["Seminar hall, Block A", "Main auditorium", "Block B, Room 204", "College ground", "Lab 3"],
            courses: ["B.E. CSE", "B.E. ECE", "B.E. Mechanical", "B.Tech IT"],
            yearSems: ["Year 3 · Sem 5", "Year 2 · Sem 3", "Year 4 · Sem 7"],
            sections: ["A", "B", "all"],
            streams: ["Engineering", "Arts and Science", "Management", "Education"],
            departments: ["all", "CSE", "Information Technology", "ECE", "Mechanical", "Civil"],
            semesters: ["all", "1", "3", "5", "7"],
            divisions: ["all", "A", "B"])
    }

    func audienceCounts(for selection: AudienceSelection) async throws -> InviteeCounts {
        try await Task.sleep(for: latency / 3)
        if let failure { throw failure }
        return counts(for: selection)
    }

    func eventDraft(id: String) async throws -> NewEventDraft {
        try await wait()
        guard let detail = details[id] else { throw EventServiceError.notFound }
        let event = detail.event
        let isOnline = event.isOnline
        return NewEventDraft(
            id: event.id, title: event.title, description: detail.description, category: event.category,
            hasCover: true, start: event.start, end: event.end, isAllDay: event.isAllDay,
            venueKind: isOnline ? .online : .campus,
            campusLocation: isOnline ? "Seminar hall, Block A" : event.venue,
            meetingLink: isOnline ? "https://meet.google.com/uce-flut-ter" : "",
            audience: AudienceSelection(scope: event.invitedCount > 1000 ? .wholeCollege : .groups, eventID: nil, stream: nil,
                                        department: "B.E. CSE", yearSem: "Year 3 · Sem 5", section: "all",
                                        roles: Set(event.roles)),
            rsvpRequired: detail.rsvpRequired,
            rsvpDeadline: detail.rsvpDeadline ?? event.start,
            seatLimit: detail.seatLimit, allowGuests: false,
            attachments: detail.attachments, reminders: detail.reminders, publishAt: nil)
    }

    func saveDraft(_ draft: NewEventDraft) async throws -> String {
        try await wait()
        let event = makeEvent(from: draft, isDraft: true)
        upsert(event, draft: draft)
        return event.id
    }

    func publish(_ draft: NewEventDraft) async throws -> StaffEvent {
        try await wait()
        let event = makeEvent(from: draft, isDraft: false)
        upsert(event, draft: draft)
        if event.roles.contains(.students) || event.roles.contains(.parents) {
            learner.removeAll { $0.id == event.id }
            learner.append(LearnerEvent(
                id: event.id, title: event.title, category: event.category, start: event.start, end: event.end,
                isAllDay: event.isAllDay, venue: event.venue, isOnline: event.isOnline,
                meetingLink: draft.venueKind == .online ? draft.meetingLink : nil,
                organiser: "Dr. Suresh Kumar", organiserRole: String(localized: "Principal"),
                coverCaption: coverCaption(venue: event.venue, date: event.start),
                rsvpRequired: draft.rsvpRequired, rsvpDeadline: draft.rsvpRequired ? endOfDay(draft.rsvpDeadline) : nil,
                seatLimit: draft.seatLimit, goingCount: 0, maxGuests: draft.allowGuests ? 2 : 0,
                myResponse: nil, myGuests: 0, isFeatured: false, description: draft.description,
                attachments: draft.attachments, galleryItemCount: nil))
        }
        return event
    }

    func sendReminder(eventID: String) async throws -> Int {
        try await wait()
        return details[eventID]?.responseCounts.noResponse ?? 0
    }

    func exportAttendees(eventID: String) async throws -> String {
        try await wait()
        let title = details[eventID]?.event.title ?? "Event"
        let slug = title.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).prefix(4).joined(separator: "_")
        return "\(slug)_attendees.xlsx"
    }

    func cancelEvent(id: String, reason: String, notifyInvitees: Bool) async throws {
        try await wait()
        guard let index = events.firstIndex(where: { $0.id == id }) else { throw EventServiceError.notFound }
        events[index].cancelledAt = .now
        events[index].cancelReason = reason
        details[id]?.event = events[index]
        learner.removeAll { $0.id == id }
    }

    func deleteEvent(id: String) async throws {
        try await wait()
        events.removeAll { $0.id == id }
        details[id] = nil
        learner.removeAll { $0.id == id }
        galleries[id] = nil
    }

    // MARK: - Gallery (organiser)

    func galleryEventInfo(eventID: String) async throws -> GalleryEventInfo {
        try await wait()
        guard let event = events.first(where: { $0.id == eventID }) else { throw EventServiceError.notFound }
        var invitees = InviteeCounts.zero
        for role in event.roles {
            switch role {
            case .students: invitees.students = event.id == "e-sports-day" ? 100 : event.invitedCount
            case .parents: invitees.parents = event.id == "e-sports-day" ? 140 : 0
            case .staff: invitees.staff = 0
            }
        }
        if invitees.total == 0 { invitees.students = event.invitedCount }
        let classes = event.audienceText.components(separatedBy: " · ").first ?? event.audienceText
        return GalleryEventInfo(eventID: event.id, title: event.title, start: event.start, end: event.end,
                                isAllDay: event.isAllDay, venue: event.venue, invitees: invitees,
                                classesText: classes, gallery: galleries[eventID])
    }

    func latestEventNeedingMedia() async throws -> String? {
        try await wait()
        return events
            .filter { $0.status() == .completed && galleries[$0.id] == nil }
            .max { $0.end < $1.end }?.id
    }

    func uploadMedia(eventID: String, upload: MediaUpload) async throws -> String {
        try await Task.sleep(for: latency * 4)
        if let failure { throw failure }
        let id = "up-\(nextID)"
        nextID += 1
        uploads[id] = upload
        return id
    }

    func saveGalleryDraft(_ request: GalleryPublishRequest) async throws {
        try await wait()
    }

    func publishGallery(_ request: GalleryPublishRequest) async throws -> EventGallery {
        try await wait()
        guard let event = events.first(where: { $0.id == request.eventID }) else { throw EventServiceError.notFound }
        let tints = GalleryTint.allCases
        let newItems: [GalleryItem] = request.items.enumerated().map { index, item in
            let upload = uploads[item.uploadID]
            let fileURL = upload.flatMap(Self.persist)
            return GalleryItem(id: item.uploadID, kind: item.kind, caption: item.caption, duration: item.duration,
                               thumbnailURL: item.kind == .photo ? fileURL : nil, mediaURL: fileURL,
                               tint: tints[index % tints.count],
                               symbol: item.kind == .photo ? "photo.fill" : "play.fill")
        }
        let info = try? await galleryEventInfo(eventID: event.id)
        let audience = request.audience.scope == .eventInvitees
            ? (info?.invitees.total ?? event.invitedCount)
            : counts(for: request.audience).total(for: request.audience.roles)
        var gallery = galleries[event.id] ?? EventGallery(
            eventID: event.id, eventTitle: event.title, albumTitle: request.albumTitle, start: event.start, end: event.end,
            venue: event.venue, coverID: nil, allowDownload: request.allowDownload,
            sharedBy: String(localized: "Principal’s office"), publishedAt: nil, isPublished: true, views: 0,
            audienceCount: audience,
            audienceText: request.audience.scope == .eventInvitees
                ? String(localized: "Everyone who was invited · \(event.audienceText)")
                : String(localized: "Chosen groups · \(audience) people"),
            items: [])
        gallery.items += newItems
        gallery.albumTitle = request.albumTitle
        gallery.allowDownload = request.allowDownload
        gallery.coverID = request.coverUploadID ?? gallery.coverID
        gallery.isPublished = true
        gallery.publishedAt = request.publishAt ?? .now
        galleries[event.id] = gallery
        removedGalleries.remove(event.id)
        refreshLearnerGallery(event.id)
        return gallery
    }

    func organiserGallery(eventID: String) async throws -> EventGallery {
        try await wait()
        guard let gallery = galleries[eventID] else { throw EventServiceError.notFound }
        return gallery
    }

    func updateGallery(eventID: String, items: [GalleryItem], coverID: String?) async throws {
        try await wait()
        galleries[eventID]?.items = items
        galleries[eventID]?.coverID = coverID
        refreshLearnerGallery(eventID)
    }

    func deleteGalleryItems(eventID: String, itemIDs: [String]) async throws {
        try await wait()
        let ids = Set(itemIDs)
        galleries[eventID]?.items.removeAll { ids.contains($0.id) }
        refreshLearnerGallery(eventID)
    }

    func setGalleryPublished(eventID: String, published: Bool) async throws {
        try await wait()
        galleries[eventID]?.isPublished = published
        refreshLearnerGallery(eventID)
    }

    func deleteGallery(eventID: String) async throws {
        try await wait()
        galleries[eventID] = nil
        removedGalleries.insert(eventID)
        refreshLearnerGallery(eventID)
    }

    // MARK: - Receiver

    func learnerEvents() async throws -> [LearnerEvent] {
        try await wait()
        return learner
    }

    func learnerEvent(id: String) async throws -> LearnerEvent {
        try await wait()
        guard let event = learner.first(where: { $0.id == id }) else { throw EventServiceError.notFound }
        return event
    }

    func respond(eventID: String, response: RSVPResponse, guests: Int) async throws -> LearnerEvent {
        try await wait()
        guard let index = learner.firstIndex(where: { $0.id == eventID }) else { throw EventServiceError.notFound }
        var event = learner[index]
        if event.myResponse == .going { event.goingCount -= 1 }
        if response == .going { event.goingCount += 1 }
        event.myResponse = response
        event.myGuests = response == .going ? min(guests, event.maxGuests) : 0
        learner[index] = event
        return event
    }

    func learnerGallery(eventID: String) async throws -> EventGallery {
        try await wait()
        if let gallery = galleries[eventID], gallery.isPublished { return gallery }
        throw EventServiceError.galleryUnavailable
    }

    // MARK: - Helpers

    private func date(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private func endOfDay(_ date: Date) -> Date {
        calendar.date(bySettingHour: 23, minute: 59, second: 0, of: date) ?? date
    }

    private func coverCaption(venue: String, date: Date) -> String {
        let place = venue.components(separatedBy: ",").first ?? venue
        return "\(place) · \(date.formatted(.dateTime.day().month(.abbreviated)))"
    }

    private func withGallerySummary(_ event: StaffEvent) -> StaffEvent {
        var event = event
        if let gallery = galleries[event.id] {
            let cover = gallery.cover
            event.gallery = GallerySummary(
                photoCount: gallery.photoCount, videoCount: gallery.videoCount, views: gallery.views,
                audience: gallery.audienceCount, isPublished: gallery.isPublished, publishedAt: gallery.publishedAt,
                coverCaption: cover?.caption, coverTint: cover?.tint ?? .green, coverSymbol: cover?.symbol ?? "photo.fill")
        } else {
            event.gallery = nil
        }
        return event
    }

    private func refreshLearnerGallery(_ eventID: String) {
        guard let index = learner.firstIndex(where: { $0.id == eventID }) else { return }
        if let gallery = galleries[eventID], gallery.isPublished {
            learner[index].galleryItemCount = gallery.items.count
        } else {
            learner[index].galleryItemCount = nil
        }
    }

    /// Mock storage: keeps picked files so published items show the real photo or video.
    private static func persist(_ upload: MediaUpload) -> URL? {
        if let fileURL = upload.fileURL { return fileURL }
        guard let data = upload.data else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appending(path: "gallery-\(UUID().uuidString)")
            .appendingPathExtension(upload.kind == .photo ? "jpg" : "mp4")
        return (try? data.write(to: url)) == nil ? nil : url
    }

    /// Head counts used by Create event and Add media.
    private func counts(for selection: AudienceSelection) -> InviteeCounts {
        switch selection.scope {
        case .wholeCollege:
            return InviteeCounts(students: 2480, parents: 2413, staff: 203)
        case .eventInvitees:
            if selection.eventID == "e-sports-day" { return InviteeCounts(students: 100, parents: 140, staff: 0) }
            let invited = events.first { $0.id == selection.eventID }?.invitedCount ?? 0
            return InviteeCounts(students: invited, parents: 0, staff: 0)
        case .groups where selection.stream == nil:
            // Create event: course › year › section.
            switch selection.section {
            case "A": return InviteeCounts(students: 58, parents: 57, staff: 6)
            case "B": return InviteeCounts(students: 42, parents: 41, staff: 6)
            case "all": return InviteeCounts(students: 100, parents: 98, staff: 9)
            default: return .zero
            }
        case .groups:
            // Add media: stream › department › semester › division.
            let division = selection.section.isEmpty ? "all" : selection.section
            var students = division == "A" ? 58 : division == "B" ? 42 : 100
            var parents = division == "A" ? 81 : division == "B" ? 59 : 140
            var staff = division == "all" ? 9 : 5
            if selection.yearSem != "5" {
                students = division == "all" ? 118 : 60
                parents = Int((Double(students) * 1.4).rounded())
            }
            if selection.department != "CSE" {
                students = selection.department == "all" ? students * 5 : Int((Double(students) * 0.9).rounded())
                parents = Int((Double(students) * 1.4).rounded())
                staff = selection.department == "all" ? 44 : 8
            }
            return InviteeCounts(students: students, parents: parents, staff: staff)
        }
    }

    private func audienceText(for draft: NewEventDraft) -> String {
        let roles = EventAudienceRole.allCases.filter { draft.audience.roles.contains($0) }.map(\.title).joined(separator: ", ")
        guard draft.audience.scope == .groups else { return String(localized: "Whole college · \(roles)") }
        let sem = draft.audience.yearSem.components(separatedBy: " · ").last ?? draft.audience.yearSem
        let section: String
        switch draft.audience.section {
        case "all": section = "A, B"
        default: section = draft.audience.section
        }
        return "\(draft.audience.department) \(sem) \(section) · \(roles)"
    }

    private func makeEvent(from draft: NewEventDraft, isDraft: Bool) -> StaffEvent {
        let id: String
        if let existing = draft.id {
            id = existing
        } else {
            id = "e-new-\(nextID)"
            nextID += 1
        }
        let invited = counts(for: draft.audience).total(for: draft.audience.roles)
        let previous = events.first { $0.id == id }
        return StaffEvent(
            id: id, title: draft.title.isEmpty ? String(localized: "Untitled event") : draft.title,
            category: draft.category, start: draft.start, end: draft.end, isAllDay: draft.isAllDay,
            venue: draft.venueText, isOnline: draft.venueKind == .online, audienceText: audienceText(for: draft),
            roles: EventAudienceRole.allCases.filter { draft.audience.roles.contains($0) },
            goingCount: previous?.goingCount ?? 0, invitedCount: invited, isDraft: isDraft,
            cancelledAt: nil, cancelReason: nil, createdAt: previous?.createdAt ?? .now,
            editedAt: .now, gallery: nil)
    }

    private func upsert(_ event: StaffEvent, draft: NewEventDraft) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.insert(event, at: 0)
        }
        let invitees = makeAttendees(students: event.roles.contains(.students) ? 100 : 0,
                                     parents: event.roles.contains(.parents) ? 140 : 0,
                                     staff: event.roles.contains(.staff), allPending: true)
        let previous = details[event.id]
        details[event.id] = StaffEventDetail(
            event: event, description: draft.description,
            coverCaption: coverCaption(venue: event.venue, date: event.start),
            organiser: "Dr. Suresh Kumar", organiserRole: String(localized: "Principal"),
            rsvpRequired: draft.rsvpRequired, rsvpDeadline: draft.rsvpRequired ? endOfDay(draft.rsvpDeadline) : nil,
            seatLimit: draft.seatLimit, publishedAt: event.isDraft ? nil : (previous?.publishedAt ?? .now),
            reminders: draft.reminders, attachments: draft.attachments,
            responseCounts: previous?.responseCounts ?? RSVPCounts(going: 0, maybe: 0, notGoing: 0, noResponse: event.invitedCount),
            attendees: previous?.attendees ?? invitees)
    }

    private func makeAttendees(students: Int, parents: Int, staff: Bool, allPending: Bool) -> [EventAttendee] {
        let sent = date(-1, 9)
        func response(_ code: Character) -> RSVPResponse? {
            switch code {
            case "g": .going
            case "m": .maybe
            case "n": .notGoing
            default: nil
            }
        }
        let studentCodes = Array(MockEventData.studentResponses)
        let parentCodes = Array(MockEventData.parentResponses)
        var people: [EventAttendee] = []
        for (index, seed) in MockEventData.students.prefix(students).enumerated() {
            let answer = allPending ? nil : response(studentCodes[index])
            let minutes = MockEventData.studentReplyMinutes[index]
            people.append(EventAttendee(
                id: "s-\(seed.2)", name: seed.0, classLabel: "B.E. CSE · Sem 5 \(seed.1)", regNo: seed.2, isStaff: false,
                response: answer, respondedAt: answer == nil ? nil : sent.addingTimeInterval(Double(minutes) * 60)))
        }
        if parents > 0 {
            var index = 0
            outer: for seed in MockEventData.students {
                for relation in [String(localized: "Father of"), String(localized: "Mother of")] {
                    guard index < parents, index < parentCodes.count else { break outer }
                    let answer = allPending ? nil : response(parentCodes[index])
                    people.append(EventAttendee(
                        id: "p-\(seed.2)-\(index % 2)", name: "\(relation) \(seed.0)", classLabel: "Parent · Sem 5 \(seed.1)",
                        regNo: "", isStaff: false, response: answer,
                        respondedAt: answer == nil ? nil : sent.addingTimeInterval(Double(index) * 420)))
                    index += 1
                }
            }
        }
        if staff {
            for (index, name) in MockEventData.staff.enumerated() {
                people.append(EventAttendee(id: "t-\(index)", name: name, classLabel: "Staff · CSE", regNo: "",
                                            isStaff: true, response: nil, respondedAt: nil))
            }
        }
        return people
    }

    private func counts(of people: [EventAttendee]) -> RSVPCounts {
        RSVPCounts(going: people.filter { $0.response == .going }.count,
                   maybe: people.filter { $0.response == .maybe }.count,
                   notGoing: people.filter { $0.response == .notGoing }.count,
                   noResponse: people.filter { $0.response == nil }.count)
    }

    private func items(_ seeds: [MockEventData.ItemSeed]) -> [GalleryItem] {
        seeds.map { GalleryItem(id: $0.0, kind: $0.1, caption: $0.2, duration: $0.3, thumbnailURL: nil, mediaURL: nil,
                                tint: $0.4, symbol: $0.5) }
    }

    // MARK: - Seed

    private func seed(now: Date) {
        let cse = "B.E. CSE Sem 5 A, B"
        struct Seed {
            var id: String, title: String, category: EventCategory, start: Date, end: Date, allDay = false
            var venue: String, online = false, audience: String, roles: [EventAudienceRole]
            var going: Int, invited: Int, draft = false, cancelled: Date? = nil, reason: String? = nil, created: Int
            var description: String, organiser: String, organiserRole: String
            var deadline: Date?, seats: Int?, files: [AssignmentAttachment] = []
        }
        let pdf = { (id: String, name: String, size: String) in
            AssignmentAttachment(id: id, name: name, kind: .pdf, detail: "PDF · \(size)")
        }
        let seeds: [Seed] = [
            Seed(id: "e-cyber", title: "Cyber security awareness workshop", category: .workshop,
                 start: date(17, 10), end: date(17, 13), venue: "Seminar hall, Block A",
                 audience: "\(cse) · Students, Staff", roles: [.students, .staff], going: 0, invited: 109, created: 9,
                 description: "Learn how to spot phishing, protect your accounts and stay safe online. Session by the Tamil Nadu Cyber Crime Wing, with a hands-on lab.\n\nBring your laptop. Certificates for all attendees.",
                 organiser: "Dr. Suresh Kumar", organiserRole: "Principal", deadline: endOfDay(date(14, 0)), seats: 120,
                 files: [pdf("f1", "Workshop_brochure.pdf", "1.1 MB"), pdf("f2", "Session_schedule.pdf", "220 KB")]),
            Seed(id: "e-ptm", title: "Parent–teacher meeting – B.E. CSE Sem 5", category: .parentMeeting,
                 start: date(2, 10), end: date(2, 13), venue: "Block B, Room 204",
                 audience: "\(cse) · Parents", roles: [.parents], going: 84, invited: 98, created: 4,
                 description: "Meet the class advisor and subject teachers to discuss IA 1 results, attendance and the model exam plan.\n\nEach family gets a 10-minute slot. You will receive your slot time by SMS on Thursday.",
                 organiser: "Dr. Meena Krishnan", organiserRole: "Class advisor · CSE", deadline: endOfDay(date(1, 0)), seats: nil,
                 files: [pdf("f1", "PTM_slot_plan.pdf", "160 KB")]),
            Seed(id: "e-ai", title: "AI in healthcare – guest lecture", category: .academic,
                 start: date(8, 14), end: date(8, 16), venue: "Seminar hall, Block A",
                 audience: "\(cse) · Students", roles: [.students], going: 64, invited: 100, created: 6,
                 description: "Dr. Anitha Raman from Apollo Hospitals talks about how AI is used in radiology and early diagnosis, with a live demo and Q&A.",
                 organiser: "Dept. of CSE", organiserRole: "Dr. Prakash V., HoD", deadline: endOfDay(date(6, 0)), seats: 120,
                 files: [pdf("f1", "Speaker_profile.pdf", "210 KB")]),
            Seed(id: "e-kalai", title: "Kalai Vizha ’26 – inter-department cultural fest", category: .cultural,
                 start: date(9, 9, 30), end: date(9, 17), venue: "Main auditorium",
                 audience: "Whole college · Students, Staff", roles: [.students, .staff], going: 412, invited: 2683, created: 3,
                 description: "Dance, music, drama and art competitions between all departments, followed by a celebrity music night at 6 PM.\n\nStudents can bring up to two family members. Entry with college ID only.",
                 organiser: "Cultural committee", organiserRole: "Dr. Lakshmi Sundar, coordinator", deadline: endOfDay(date(7, 0)), seats: 600,
                 files: [pdf("f1", "KalaiVizha26_brochure.pdf", "2.2 MB"), pdf("f2", "Event_schedule.pdf", "340 KB")]),
            Seed(id: "e-cricket", title: "Inter-department cricket finals – CSE vs ECE", category: .sports,
                 start: now.addingTimeInterval(-3600), end: now.addingTimeInterval(5400), venue: "College ground",
                 audience: "All years · Students, Staff", roles: [.students, .staff], going: 220, invited: 2683, created: 2,
                 description: "Cheer for CSE in the final against ECE. Gallery seating was by registration, which closed yesterday. Standing area is open to all.",
                 organiser: "Physical Education dept.", organiserRole: "Mr. Karthik S., PD", deadline: endOfDay(date(-1, 0)), seats: nil),
            Seed(id: "e-sports-day", title: "Sports Day 2026", category: .sports,
                 start: date(-1, 8), end: date(-1, 16, 30), venue: "College ground",
                 audience: "\(cse) · Students, Parents", roles: [.students, .parents], going: 196, invited: 240, created: 5,
                 description: "Track and field, relays and the tug of war final between Sem 5 A and Sem 5 B. Medals were given by the Principal at 04:00 PM. Thank you to all athletes, parents and volunteers!",
                 organiser: "Physical Education dept.", organiserRole: "Mr. Karthik S., PD", deadline: endOfDay(date(-5, 0)), seats: nil),
            Seed(id: "e-techfest", title: "Techfest ’26 – national symposium", category: .academic,
                 start: date(-2, 9), end: date(-2, 17), venue: "Main auditorium",
                 audience: "B.E. CSE all years · Students", roles: [.students], going: 288, invited: 760, created: 1,
                 description: "Paper presentations, project expo and coding contest. Thank you to all 288 participants!",
                 organiser: "Dept. of CSE", organiserRole: "Dr. Prakash V., HoD", deadline: endOfDay(date(-4, 0)), seats: nil,
                 files: [pdf("f1", "Techfest26_results.pdf", "420 KB")]),
            Seed(id: "e-annual", title: "Annual Day 2026", category: .cultural,
                 start: date(38, 0), end: date(38, 23, 59), allDay: true, venue: "College ground",
                 audience: "Whole college · Students, Parents, Staff", roles: [.students, .parents, .staff],
                 going: 0, invited: 5096, draft: true, created: 8,
                 description: "Annual Day celebrations with prize distribution and cultural programmes.",
                 organiser: "Dr. Suresh Kumar", organiserRole: "Principal", deadline: nil, seats: nil),
            Seed(id: "e-visit", title: "Industrial visit – Ashok Leyland, Ennore", category: .academic,
                 start: date(1, 8), end: date(1, 16), venue: "Ennore plant, Chennai",
                 audience: "B.E. Mechanical Sem 5 · Students", roles: [.students], going: 54, invited: 58,
                 cancelled: date(0, 7, 30), reason: "Heavy rain alert", created: 0,
                 description: "Plant visit covering the engine assembly line and quality lab.",
                 organiser: "Dept. of Mechanical", organiserRole: "Prof. Ravi Shankar", deadline: endOfDay(date(-1, 0)), seats: 60),
        ]

        for seed in seeds {
            let event = StaffEvent(
                id: seed.id, title: seed.title, category: seed.category, start: seed.start, end: seed.end,
                isAllDay: seed.allDay, venue: seed.venue, isOnline: seed.online, audienceText: seed.audience,
                roles: seed.roles, goingCount: seed.going, invitedCount: seed.invited, isDraft: seed.draft,
                cancelledAt: seed.cancelled, cancelReason: seed.reason,
                createdAt: date(seed.created - 10, 9), editedAt: seed.draft ? date(-1, 18) : nil, gallery: nil)
            events.append(event)

            let attendees: [EventAttendee]
            let responses: RSVPCounts
            switch seed.id {
            case "e-cyber":
                attendees = makeAttendees(students: 100, parents: 0, staff: true, allPending: true)
                responses = counts(of: attendees)
            case "e-sports-day":
                attendees = makeAttendees(students: 100, parents: 140, staff: false, allPending: false)
                responses = counts(of: attendees)
            case "e-ai", "e-ptm", "e-techfest", "e-visit":
                attendees = makeAttendees(students: 100, parents: 0, staff: false, allPending: false)
                responses = seed.invited == 100 ? counts(of: attendees)
                    : RSVPCounts(going: seed.going, maybe: seed.invited / 12, notGoing: seed.invited / 20,
                                 noResponse: max(0, seed.invited - seed.going - seed.invited / 12 - seed.invited / 20))
            default:
                attendees = makeAttendees(students: 100, parents: 0, staff: false, allPending: false)
                let maybe = seed.invited / 12, notGoing = seed.invited / 20
                responses = RSVPCounts(going: seed.going, maybe: maybe, notGoing: notGoing,
                                       noResponse: max(0, seed.invited - seed.going - maybe - notGoing))
            }

            details[seed.id] = StaffEventDetail(
                event: event, description: seed.description,
                coverCaption: coverCaption(venue: seed.venue, date: seed.start),
                organiser: seed.organiser, organiserRole: seed.organiserRole,
                rsvpRequired: seed.deadline != nil, rsvpDeadline: seed.deadline, seatLimit: seed.seats,
                publishedAt: seed.draft ? nil : date(seed.created - 10, 9),
                reminders: EventReminderSettings(dayBefore: true, hourBefore: true, push: true, sms: seed.id != "e-cyber"),
                attachments: seed.files, responseCounts: responses, attendees: attendees)
        }

        galleries["e-techfest"] = EventGallery(
            eventID: "e-techfest", eventTitle: "Techfest ’26 – national symposium", albumTitle: "Techfest ’26",
            start: date(-2, 9), end: date(-2, 17), venue: "Main auditorium", coverID: "t26", allowDownload: false,
            sharedBy: "Dept. of CSE", publishedAt: date(-1, 10, 15), isPublished: true, views: 512, audienceCount: 760,
            audienceText: "Everyone who was invited · B.E. CSE all years · Students",
            items: items(MockEventData.techfestItems))

        // Receivers (student / parent).
        func learnerSeed(_ id: String, rsvp: RSVPResponse? = nil, guests: Int = 0, maxGuests: Int = 0,
                         featured: Bool = false) -> LearnerEvent? {
            guard let detail = details[id] else { return nil }
            let event = detail.event
            return LearnerEvent(
                id: id, title: event.title, category: event.category, start: event.start, end: event.end,
                isAllDay: event.isAllDay, venue: event.venue, isOnline: event.isOnline, meetingLink: nil,
                organiser: detail.organiser, organiserRole: detail.organiserRole, coverCaption: detail.coverCaption,
                rsvpRequired: detail.rsvpRequired, rsvpDeadline: detail.rsvpDeadline, seatLimit: detail.seatLimit,
                goingCount: event.goingCount, maxGuests: maxGuests, myResponse: rsvp, myGuests: guests,
                isFeatured: featured, description: detail.description, attachments: detail.attachments,
                galleryItemCount: galleries[id].map { $0.items.count })
        }
        let seeded: [LearnerEvent?] = [
            learnerSeed("e-cricket"),
            learnerSeed("e-ptm", rsvp: .going, guests: 1, maxGuests: 1),
            LearnerEvent(
                id: "e-flutter", title: "Flutter app development workshop", category: .workshop,
                start: date(3, 10), end: date(3, 16), isAllDay: false, venue: "Online · Google Meet", isOnline: true,
                meetingLink: "https://meet.google.com/uce-flut-ter", organiser: "CSE Coding Club",
                organiserRole: "Prof. Karthik Raman, mentor", coverCaption: "Online · \(date(3, 0).formatted(.dateTime.day().month(.abbreviated)))",
                rsvpRequired: true, rsvpDeadline: endOfDay(date(2, 0)), seatLimit: 120, goingCount: 120, maxGuests: 0,
                myResponse: nil, myGuests: 0, isFeatured: false,
                description: "A hands-on, 6-hour workshop. Build and publish a simple attendance app in Flutter.\n\nInstall Flutter SDK and VS Code before the session.",
                attachments: [pdf("f1", "Setup_guide.pdf", "780 KB")], galleryItemCount: nil),
            learnerSeed("e-ai", rsvp: .maybe),
            learnerSeed("e-kalai", maxGuests: 2, featured: true),
            LearnerEvent(
                id: "e-pooja", title: "Ayudha Pooja and Vijayadashami holidays", category: .holiday,
                start: date(12, 0), end: date(13, 23, 59), isAllDay: true, venue: "Campus closed", isOnline: false,
                meetingLink: nil, organiser: "Principal’s office", organiserRole: "Dr. Suresh Kumar",
                coverCaption: date(12, 0).formatted(.dateTime.day().month(.abbreviated)),
                rsvpRequired: false, rsvpDeadline: nil, seatLimit: nil, goingCount: 0, maxGuests: 0,
                myResponse: nil, myGuests: 0, isFeatured: false,
                description: "The college remains closed for the Ayudha Pooja and Vijayadashami holidays. Classes resume the next working day.",
                attachments: [], galleryItemCount: nil),
            LearnerEvent(
                id: "e-zoho", title: "Zoho pre-placement talk", category: .placement,
                start: date(15, 10), end: date(15, 12), isAllDay: false, venue: "Main auditorium", isOnline: false,
                meetingLink: nil, organiser: "Training & Placement cell", organiserRole: "Ms. Kavitha R.",
                coverCaption: "Main auditorium · \(date(15, 0).formatted(.dateTime.day().month(.abbreviated)))",
                rsvpRequired: true, rsvpDeadline: endOfDay(date(12, 0)), seatLimit: 400, goingCount: 186, maxGuests: 0,
                myResponse: nil, myGuests: 0, isFeatured: false,
                description: "Zoho’s hiring team explains the roles, salary and selection process for the campus drive.",
                attachments: [], galleryItemCount: nil),
            learnerSeed("e-sports-day", rsvp: .going),
            learnerSeed("e-techfest", rsvp: .going),
        ]
        learner = seeded.compactMap { $0 }
    }

    /// Design data for the Sports Day gallery, used by previews and tests.
    static func sportsDayGallery(start: Date = .now, end: Date = .now) -> EventGallery {
        EventGallery(
            eventID: "e-sports-day", eventTitle: "Sports Day 2026", albumTitle: "Sports Day 2026 – highlights",
            start: start, end: end, venue: "College ground", coverID: "s42", allowDownload: true,
            sharedBy: "Principal’s office", publishedAt: .now, isPublished: true, views: 180, audienceCount: 240,
            audienceText: "Everyone who was invited · B.E. CSE Sem 5 A, B · Students and Parents",
            items: MockEventData.sportsDayItems.map {
                GalleryItem(id: $0.0, kind: $0.1, caption: $0.2, duration: $0.3, thumbnailURL: nil, mediaURL: nil,
                            tint: $0.4, symbol: $0.5)
            })
    }
}
