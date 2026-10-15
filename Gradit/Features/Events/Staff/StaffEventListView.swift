//
//  StaffEventListView.swift
//  Gradit
//
//  My events for Principal / Teacher: search, filters, status tabs and event cards
//  with RSVP progress and gallery shortcuts.
//  Design: 12 Events › Management & Teachers › Events (+ Past, Empty, Loading, Error).
//

import SwiftUI

struct StaffEventListView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: StaffEventListViewModel?

    var body: some View {
        VStack(spacing: 0) {
            EventTopBar(title: String(localized: "Events"), subtitle: model?.ownerLine,
                        onBack: isPresented ? { dismiss() } : nil)
            if let model {
                content(model)
            } else {
                Spacer()
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) {
            if let model, !model.isEmpty, model.tab != .completed {
                createButton
            }
        }
        .task {
            if model == nil { model = StaffEventListViewModel(role: role, service: dependencies.eventService) }
            await model?.load()
        }
    }

    // MARK: - Content

    private func content(_ model: StaffEventListViewModel) -> some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                EventSearchField(placeholder: String(localized: "Search by title or venue"), text: $model.searchText)
                filters(model)
                EventCountTabs(tabs: model.tabs, selection: $model.tab)
                    .padding(.horizontal, -16)

                if model.tab == .completed && model.hasLoaded {
                    Label("Events move here automatically when their end time passes. Add photos and videos to completed events.",
                          systemImage: "info.circle")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if model.showsLoading {
                    ForEach(0..<3, id: \.self) { _ in EventSkeletonCard() }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Loading events")
                } else if model.showsError {
                    EventStateCard(systemImage: "wifi.exclamationmark", tint: Theme.Colors.red700,
                                   tintBackground: Theme.Colors.errorBackground,
                                   title: String(localized: "Couldn’t load your events"),
                                   message: String(localized: "Check your internet connection and try again."),
                                   actionTitle: String(localized: "Try again"), actionImage: "arrow.clockwise") {
                        model.retry()
                    }
                } else if model.isEmpty {
                    EventStateCard(systemImage: "calendar.badge.plus",
                                   title: String(localized: "No events yet"),
                                   message: String(localized: "Create an event to invite students, parents and staff and track who’s coming."),
                                   actionTitle: String(localized: "Create event"), actionImage: "plus") {
                        router.push(.event(.create(.new)))
                    }
                } else if model.visible.isEmpty {
                    Text("No events match these filters.")
                        .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500)
                        .frame(maxWidth: .infinity).padding(.vertical, 28)
                } else {
                    ForEach(model.visible) { event in
                        StaffEventCard(event: event, now: model.now) {
                            if event.isDraft {
                                router.push(.event(.create(.edit(event.id))))
                            } else {
                                router.push(.event(.staffDetail(id: event.id)))
                            }
                        } onAddMedia: {
                            router.push(.event(.addMedia(eventID: event.id, source: .events)))
                        } onManageGallery: {
                            router.push(.event(.manageGallery(eventID: event.id)))
                        }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 96)
        }
        .scrollIndicators(.hidden)
        .refreshable { await model.load() }
    }

    private func filters(_ model: StaffEventListViewModel) -> some View {
        @Bindable var model = model
        return ScrollView(.horizontal) {
            HStack(spacing: 8) {
                EventFilterMenu(label: model.category?.title ?? String(localized: "Category: All"),
                                options: [(EventCategory?.none, String(localized: "All"))] + EventCategory.allCases.map { (Optional($0), $0.title) },
                                selection: $model.category, isActive: model.category != nil)
                EventFilterMenu(label: model.audience?.title ?? String(localized: "Audience: All"),
                                options: [(EventAudienceRole?.none, String(localized: "All"))] + EventAudienceRole.allCases.map { (Optional($0), $0.title) },
                                selection: $model.audience, isActive: model.audience != nil)
                EventFilterMenu(label: String(localized: "Status: \(model.tab.tabTitle)"),
                                options: StaffEventListViewModel.tabOrder.map { ($0, $0.tabTitle) },
                                selection: $model.tab, isActive: true)
                EventFilterMenu(label: model.sort.title,
                                options: StaffEventListViewModel.Sort.allCases.map { ($0, $0.title) },
                                selection: $model.sort)
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -16)
    }

    private var createButton: some View {
        Button { router.push(.event(.create(.new))) } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.Colors.white)
                .frame(width: 56, height: 56)
                .background(Theme.Colors.blue600, in: Circle())
                .shadow(color: Theme.Colors.blue600.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(20)
        .accessibilityLabel("Create event")
    }
}

// MARK: - Card

struct StaffEventCard: View {
    let event: StaffEvent
    let now: Date
    let onOpen: () -> Void
    let onAddMedia: () -> Void
    let onManageGallery: () -> Void

    private var status: EventStatus { event.status(now: now) }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 0) {
                    EventCoverBanner(category: event.category, height: 92, accessibilityTitle: event.title)
                    details
                }
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityElement(children: .combine)

            if status == .completed {
                galleryFooter
            }
        }
        .clipShape(.rect(cornerRadius: 16))
        .dashboardCard(radius: 16)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Text(event.title)
                    .font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                EventStatusPill(status: status)
            }
            EventCategoryChip(category: event.category)
            infoLine("calendar", EventFormat.whenLine(start: event.start, end: event.end, isAllDay: event.isAllDay, now: now))
            infoLine(event.isOnline ? "video" : "mappin.and.ellipse", event.venue)
            infoLine("person.2", event.audienceText)
            if status != .draft {
                EventProgressRow(
                    text: String(localized: "\(EventFormat.count(event.goingCount)) going / \(EventFormat.count(event.invitedCount)) invited"),
                    percentText: EventFormat.percent(event.goingCount, of: event.invitedCount),
                    fraction: event.invitedCount > 0 ? Double(event.goingCount) / Double(event.invitedCount) : 0,
                    tint: status == .completed || status == .cancelled ? Theme.Colors.ink500 : Theme.Colors.green600)
            }
            if let note {
                Text(note.text)
                    .font(AppFont.jakarta(12, .semibold)).foregroundStyle(note.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoLine(_ systemImage: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 12, weight: .semibold)).frame(width: 16)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
    }

    private var note: (text: String, color: Color)? {
        switch status {
        case .ongoing:
            return (String(localized: "Happening now · ends \(EventFormat.time(event.end))"), Theme.Colors.green700)
        case .completed:
            return (EventFormat.endedLine(event.end, now: now), Theme.Colors.ink700)
        case .draft:
            let edited = event.editedAt.map(EventFormat.shortDay) ?? EventFormat.shortDay(event.createdAt)
            return (String(localized: "Draft · edited \(edited) · not visible to anyone"), Theme.Colors.ink700)
        case .cancelled:
            let date = event.cancelledAt.map(EventFormat.shortDay) ?? ""
            let reason = event.cancelReason.map { " · \($0.lowercased())" } ?? ""
            return (String(localized: "Cancelled on \(date)\(reason) · invitees notified. Cancelled events can’t have a gallery."),
                    Theme.Colors.red700)
        case .upcoming:
            return nil
        }
    }

    @ViewBuilder
    private var galleryFooter: some View {
        if let gallery = event.gallery {
            Button(action: onManageGallery) {
                HStack(spacing: 10) {
                    IconTile(systemImage: "photo.on.rectangle.angled", size: 36, radius: 10,
                             foreground: Theme.Colors.green700, background: Theme.Colors.green50)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Manage gallery").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text(galleryLine(gallery)).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.chevron)
                }
                .padding(.horizontal, 14).frame(minHeight: 60)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .overlay(alignment: .top) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
            .accessibilityLabel("Manage gallery: \(galleryLine(gallery))")
        } else {
            HStack(spacing: 8) {
                Label("No gallery yet", systemImage: "photo")
                    .font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.amber800)
                Spacer(minLength: 0)
                Button(action: onAddMedia) {
                    Label("Add photos and videos", systemImage: "plus")
                        .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.white)
                        .padding(.horizontal, 12).frame(height: 40)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 10))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Theme.Colors.warningBackground.opacity(0.6))
            .overlay(alignment: .top) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
        }
    }

    private func galleryLine(_ gallery: GallerySummary) -> String {
        let media = EventFormat.mediaCount(photos: gallery.photoCount, videos: gallery.videoCount)
        guard gallery.isPublished else { return String(localized: "\(media) · unpublished") }
        return String(localized: "\(media) · \(EventFormat.count(gallery.views)) / \(EventFormat.count(gallery.audience)) viewed")
    }
}

#Preview {
    NavigationStack { StaffEventListView(role: .management) }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
