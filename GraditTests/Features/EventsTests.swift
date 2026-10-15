//
//  EventsTests.swift
//  GraditTests
//

import Foundation
import Testing
@testable import Gradit

@MainActor
struct EventsTests {

    private func makeService() -> MockEventService {
        MockEventService(latency: .zero)
    }

    // MARK: Status

    @Test func statusFollowsDatesAndFlags() {
        let now = Date.now
        var event = StaffEvent(
            id: "x", title: "T", category: .academic, start: now.addingTimeInterval(3600), end: now.addingTimeInterval(7200),
            isAllDay: false, venue: "Hall", isOnline: false, audienceText: "", roles: [.students], goingCount: 0,
            invitedCount: 10, isDraft: false, cancelledAt: nil, cancelReason: nil, createdAt: now, editedAt: nil, gallery: nil)
        #expect(event.status(now: now) == .upcoming)
        #expect(event.status(now: now.addingTimeInterval(4000)) == .ongoing)
        #expect(event.status(now: now.addingTimeInterval(8000)) == .completed)
        event.cancelledAt = now
        #expect(event.status(now: now) == .cancelled)
        event.isDraft = true
        #expect(event.status(now: now) == .draft)
    }

    // MARK: My events

    @Test func myEventsTabsCountEachStatus() async {
        let model = StaffEventListViewModel(role: .management, service: makeService())
        await model.load()
        let counts = Dictionary(uniqueKeysWithValues: model.tabs.map { ($0.id, $0.count) })
        #expect(counts[.upcoming] == 4)
        #expect(counts[.ongoing] == 1)
        #expect(counts[.completed] == 2)
        #expect(counts[.draft] == 1)
        #expect(counts[.cancelled] == 1)
        #expect(model.ownerLine.contains("Principal"))
    }

    @Test func myEventsSearchAndCategoryFilter() async {
        let model = StaffEventListViewModel(role: .faculty, service: makeService())
        await model.load()
        model.searchText = "seminar"
        #expect(model.visible.allSatisfy { $0.venue.lowercased().contains("seminar") || $0.title.lowercased().contains("seminar") })
        model.searchText = ""
        model.category = .workshop
        #expect(model.visible.map(\.id) == ["e-cyber"])
    }

    @Test func upcomingSortsSoonestFirst() async {
        let model = StaffEventListViewModel(role: .management, service: makeService())
        await model.load()
        let starts = model.visible.map(\.start)
        #expect(starts == starts.sorted())
    }

    // MARK: Create

    @Test func createRequiresTitleAndAudience() async {
        let model = CreateEventViewModel(mode: .new, service: makeService())
        await model.load()
        #expect(model.titleError != nil)
        #expect(model.audienceError != nil) // no section chosen yet
        let published = await model.publish()
        #expect(!published)
        #expect(model.showsErrors)
        #expect(model.errorSummary.contains("Event title is missing"))
    }

    @Test func endBeforeStartIsAnError() async {
        let model = CreateEventViewModel(mode: .new, service: makeService())
        await model.load()
        model.draft.end = model.draft.start.addingTimeInterval(-3600)
        #expect(model.timeError != nil)
    }

    @Test func publishingAddsEventForOrganiserAndReceivers() async throws {
        let service = makeService()
        let model = CreateEventViewModel(mode: .new, service: service)
        await model.load()
        model.draft.title = "Robotics club demo day"
        model.draft.audience.section = "all"
        model.draft.audience.roles = [.students, .parents]
        await model.refreshCounts()
        #expect(model.invitedTotal == 198)
        let published = await model.publish()
        #expect(published)
        let id = try #require(model.publishedEvent?.id)

        let list = StaffEventListViewModel(role: .management, service: service)
        await list.load()
        #expect(list.events.contains { $0.id == id && $0.invitedCount == 198 })

        let learner = LearnerEventsViewModel(service: service)
        await learner.load()
        #expect(learner.events.contains { $0.id == id })
    }

    @Test func editPrefillsExistingEvent() async {
        let model = CreateEventViewModel(mode: .edit("e-ai"), service: makeService())
        await model.load()
        #expect(model.draft.title == "AI in healthcare – guest lecture")
        #expect(model.draft.id == "e-ai")
        #expect(model.seatText == "120")
    }

    @Test func duplicateClearsIdentity() async {
        let model = CreateEventViewModel(mode: .duplicate("e-ai"), service: makeService())
        await model.load()
        #expect(model.draft.id == nil)
        #expect(model.draft.title.hasSuffix("(copy)"))
    }

    // MARK: Detail

    @Test func detailFiltersAttendeesAndPages() async {
        let model = StaffEventDetailViewModel(eventID: "e-ai", service: makeService())
        await model.load()
        #expect(model.detail != nil)
        #expect(model.count(.all) == 100)
        #expect(model.visibleAttendees.count == StaffEventDetailViewModel.pageSize)
        #expect(model.hasMore)
        model.filter = .noResponse
        #expect(model.visibleAttendees.allSatisfy { $0.response == nil })
        model.searchText = "2024503001"
        model.filter = .all
        #expect(model.visibleAttendees.map(\.regNo) == ["2024503001"])
    }

    @Test func cancellingMarksEventCancelled() async {
        let service = makeService()
        let model = StaffEventDetailViewModel(eventID: "e-ai", service: service)
        await model.load()
        await model.cancelEvent()
        #expect(model.status == .cancelled)
        #expect(model.toast?.tone == .danger)
        let learner = LearnerEventsViewModel(service: service)
        await learner.load()
        #expect(!learner.events.contains { $0.id == "e-ai" })
    }

    // MARK: Receivers

    @Test func learnerListGroupsAndFeatures() async {
        let model = LearnerEventsViewModel(service: makeService())
        await model.load()
        #expect(model.featured?.id == "e-kalai")
        let past = model.sections.first { $0.group == .past }?.events.map(\.id) ?? []
        #expect(Set(past) == ["e-sports-day", "e-techfest"])
        model.filter = .gallery
        #expect(model.sections.flatMap(\.events).map(\.id) == ["e-techfest"])
        model.filter = .category(.holiday)
        #expect(model.sections.flatMap(\.events).map(\.id) == ["e-pooja"])
    }

    @Test func rsvpUpdatesResponseAndCount() async {
        let service = makeService()
        let model = LearnerEventDetailViewModel(eventID: "e-kalai", service: service)
        await model.load()
        let before = model.event?.goingCount ?? 0
        model.selection = .going
        model.changeGuests(by: 5)
        #expect(model.guests == 2) // capped at the event's limit
        await model.submit()
        #expect(model.showsConfirmation)
        #expect(model.event?.myResponse == .going)
        #expect(model.event?.goingCount == before + 1)
        #expect(model.currentResponseText == "Going · 2 guests")
    }

    @Test func fullAndClosedEventsBlockRSVP() async {
        let service = makeService()
        let full = LearnerEventDetailViewModel(eventID: "e-flutter", service: service)
        await full.load()
        #expect(full.block?.title == "Event full")
        #expect(!full.showsRSVP)

        let closed = LearnerEventDetailViewModel(eventID: "e-cricket", service: service)
        await closed.load()
        #expect(closed.block?.title == "Registration closed")

        let holiday = LearnerEventDetailViewModel(eventID: "e-pooja", service: service)
        await holiday.load()
        #expect(holiday.block?.title == "No RSVP needed")
    }

    // MARK: Gallery

    @Test func galleryLoadsAndFiltersVideos() async {
        let model = EventGalleryViewModel(eventID: "e-techfest", service: makeService())
        await model.load()
        #expect(model.state == .loaded)
        #expect(model.count(.all) == 34)
        model.tab = .videos
        #expect(model.visibleItems.allSatisfy { $0.kind == .video })
        #expect(model.gallery?.cover?.id == "t26")
    }

    @Test func unpublishedGalleryIsUnavailableToReceivers() async {
        let service = makeService()
        let manage = ManageGalleryViewModel(eventID: "e-techfest", service: service)
        await manage.load()
        await manage.setPublished(false)
        let receiver = EventGalleryViewModel(eventID: "e-techfest", service: service)
        await receiver.load()
        #expect(receiver.state == .unavailable)
    }

    @Test func deletingSelectedItemsUpdatesGallery() async {
        let manage = ManageGalleryViewModel(eventID: "e-techfest", service: makeService())
        await manage.load()
        manage.startSelecting()
        manage.toggleSelection("t1")
        manage.toggleSelection("t7")
        #expect(manage.selectionText == "1 photo and 1 video")
        await manage.deleteSelected()
        #expect(manage.items.count == 32)
        #expect(manage.mode == .view)
    }

    @Test func mediaRulesRejectUnsupportedAndOversizedFiles() {
        let tiff = PickedMedia(kind: .photo, fileName: "IMG_1.tiff", fileExtension: "tiff", byteCount: 1000)
        let bigVideo = PickedMedia(kind: .video, fileName: "Full_day.mp4", fileExtension: "mp4", byteCount: 300 * 1024 * 1024)
        let photo = PickedMedia(kind: .photo, fileName: "IMG_2.heic", fileExtension: "heic", byteCount: 2_000_000)
        #expect(MediaRules.rejection(for: tiff) != nil)
        #expect(MediaRules.rejection(for: bigVideo) != nil)
        #expect(MediaRules.rejection(for: photo) == nil)
    }

    @Test func addMediaNeedsItemsBeforePublishing() async {
        let model = AddEventMediaViewModel(eventID: "e-sports-day", source: .events, service: makeService())
        await model.load()
        #expect(model.recipients == 240)
        let published = await model.publish()
        #expect(!published)
        #expect(model.itemsError)
        model.add([PickedMedia(kind: .photo, fileName: "IMG_9.tiff", fileExtension: "tiff", byteCount: 10)])
        #expect(model.items.isEmpty)
        #expect(model.rejected.count == 1)
    }

    @Test func pendingMediaPointsAtSportsDay() async throws {
        let id = try await makeService().latestEventNeedingMedia()
        #expect(id == "e-sports-day")
    }
}
