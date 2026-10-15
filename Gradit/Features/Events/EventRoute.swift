//
//  EventRoute.swift
//  Gradit
//
//  Entry point and pushed screens of the Events module, wired into the shared
//  `Route` enum so they use the active tab's NavigationStack.
//

import SwiftUI

enum EventRoute: Hashable {
    // Organiser
    case staffDetail(id: String)
    case create(CreateEventViewModel.Mode)
    case addMedia(eventID: String, source: AddEventMediaViewModel.Source)
    case manageGallery(eventID: String)
    /// Home › "… has ended" prompt: opens Add media for the latest event without a gallery.
    case pendingMedia
    // Receiver
    case learnerDetail(id: String)
    case gallery(eventID: String)
}

/// Builds the destination for an `EventRoute`.
struct EventRouteView: View {
    let route: EventRoute

    var body: some View {
        switch route {
        case .staffDetail(let id):
            StaffEventDetailView(eventID: id)
        case .create(let mode):
            CreateEventView(mode: mode)
        case .addMedia(let eventID, let source):
            AddEventMediaView(eventID: eventID, source: source)
        case .manageGallery(let eventID):
            ManageGalleryView(eventID: eventID)
        case .pendingMedia:
            PendingMediaView()
        case .learnerDetail(let id):
            LearnerEventDetailView(eventID: id)
        case .gallery(let eventID):
            EventGalleryView(eventID: eventID)
        }
    }
}

/// The Events menu tile and the Campus tab are role-aware: management and faculty
/// organise events; students and parents browse, RSVP and view galleries.
struct EventsEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        let role = session.currentRole ?? .student
        switch role {
        case .faculty, .management:
            StaffEventListView(role: role)
        case .parent, .student:
            LearnerEventsView()
        }
    }
}

/// Resolves the Home prompt to the event that still needs photos.
private struct PendingMediaView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var eventID: String?
    @State private var isResolved = false

    var body: some View {
        Group {
            if let eventID {
                AddEventMediaView(eventID: eventID, source: .home)
            } else if isResolved {
                VStack(spacing: 0) {
                    EventTopBar(title: String(localized: "Add photos and videos"), onBack: { dismiss() })
                    EventStateCard(systemImage: "photo.on.rectangle", title: String(localized: "Nothing to add right now"),
                                   message: String(localized: "Every completed event already has a gallery."))
                        .padding(16)
                    Spacer()
                }
                .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .task {
            guard !isResolved else { return }
            eventID = try? await dependencies.eventService.latestEventNeedingMedia()
            isResolved = true
        }
    }
}
