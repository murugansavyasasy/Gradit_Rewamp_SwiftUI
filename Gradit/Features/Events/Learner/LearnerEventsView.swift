//
//  LearnerEventsView.swift
//  Gradit
//
//  Events for students and parents: featured event, Today / This week / Later / Past
//  groups, filters, search and a month calendar.
//  Design: 12 Events › Students & Parents › Events (+ Calendar, Gallery filter,
//  Empty, Loading, Error, Offline).
//

import SwiftUI

struct LearnerEventsView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: LearnerEventsViewModel?

    var body: some View {
        VStack(spacing: 0) {
            EventTopBar(title: String(localized: "Events"),
                        subtitle: model.map { String(localized: "\($0.upcomingCount) upcoming · \(AppConfig.collegeName)") },
                        onBack: isPresented ? { dismiss() } : nil)
            if let model {
                if model.isOffline {
                    Label(offlineText(model), systemImage: "wifi.slash")
                        .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Theme.Colors.chipGrey)
                }
                content(model)
            } else {
                Spacer()
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = LearnerEventsViewModel(service: dependencies.eventService) }
            await model?.load()
        }
    }

    private func offlineText(_ model: LearnerEventsViewModel) -> String {
        let time = model.savedAt.map(EventFormat.time) ?? ""
        return String(localized: "You’re offline. Showing events saved at \(time). RSVPs will be sent when you reconnect.")
    }

    private func content(_ model: LearnerEventsViewModel) -> some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                EventSearchField(placeholder: String(localized: "Search events"), text: $model.searchText)
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(LearnerEventsViewModel.filters) { filter in
                            EventChoiceChip(title: filter.title, isOn: model.filter == filter) { model.filter = filter }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -16)
                EventSegmented(options: [(LearnerEventsViewModel.Layout.list, String(localized: "List")),
                                         (LearnerEventsViewModel.Layout.calendar, String(localized: "Calendar"))],
                               selection: $model.layout)

                if model.isLoading && !model.hasLoaded {
                    ForEach(0..<3, id: \.self) { _ in EventSkeletonCard() }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Loading events")
                } else if let error = model.errorMessage, !model.hasLoaded {
                    EventStateCard(systemImage: "wifi.exclamationmark", tint: Theme.Colors.red700,
                                   tintBackground: Theme.Colors.errorBackground,
                                   title: String(localized: "Couldn’t load events"),
                                   message: error.isEmpty ? String(localized: "Check your internet connection and try again.") : error,
                                   actionTitle: String(localized: "Try again"), actionImage: "arrow.clockwise") { model.retry() }
                } else if model.layout == .list {
                    listContent(model)
                } else {
                    calendarContent(model)
                }
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable { await model.load() }
    }

    @ViewBuilder
    private func listContent(_ model: LearnerEventsViewModel) -> some View {
        if let featured = model.featured {
            FeaturedEventCard(event: featured, now: model.now) {
                router.push(.event(.learnerDetail(id: featured.id)))
            }
        }
        ForEach(model.sections, id: \.group) { section in
            VStack(alignment: .leading, spacing: 8) {
                Text(section.group.title.uppercased())
                    .font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.ink500)
                    .accessibilityAddTraits(.isHeader)
                ForEach(section.events) { event in
                    LearnerEventRow(event: event, now: model.now) {
                        router.push(.event(.learnerDetail(id: event.id)))
                    }
                }
            }
        }
        if model.isEmpty {
            EventStateCard(systemImage: model.filter == .gallery ? "photo.on.rectangle" : "calendar",
                           title: model.filter.emptyTitle, message: model.emptyMessage)
        }
    }

    @ViewBuilder
    private func calendarContent(_ model: LearnerEventsViewModel) -> some View {
        @Bindable var model = model
        VStack(spacing: 8) {
            EventMonthHeader(month: $model.displayedMonth)
            EventMonthGrid(month: model.displayedMonth, selected: model.selectedDay, marks: model.dayMarks, now: model.now) {
                model.selectDay($0)
            }
            Text("• 2 = number of events that day. Tap a day to see them.")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .dashboardCard(radius: 16)
        Text(EventFormat.day(model.selectedDay))
            .font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            .accessibilityAddTraits(.isHeader)
        if model.dayEvents.isEmpty {
            Text("No events on this day.").font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500)
                .frame(maxWidth: .infinity).padding(.vertical, 20)
        } else {
            ForEach(model.dayEvents) { event in
                LearnerEventRow(event: event, now: model.now) {
                    router.push(.event(.learnerDetail(id: event.id)))
                }
            }
        }
    }
}

// MARK: - Status

/// Status chip for a receiver's event row.
struct LearnerEventStatus {
    let text: String
    let systemImage: String
    let foreground: Color
    let background: Color
    var border: Color?

    init(event: LearnerEvent, now: Date) {
        if event.hasEnded(now: now) {
            self.init(String(localized: "Ended"), "clock", Theme.Colors.ink700, Theme.Colors.chipGrey)
        } else if let response = event.myResponse {
            self.init(response.title, response.systemImage, response.foreground, response.background)
        } else if !event.rsvpRequired {
            self.init(String(localized: "No RSVP needed"), "info.circle", Theme.Colors.ink700, Theme.Colors.surfaceMuted)
        } else if event.isRegistrationClosed(now: now) {
            self.init(String(localized: "Registration closed"), "nosign", Theme.Colors.ink700, Theme.Colors.chipGrey)
        } else if event.isFull {
            self.init(String(localized: "Event full"), "nosign", Theme.Colors.red700, Theme.Colors.errorBackground)
        } else {
            self.init(String(localized: "RSVP needed"), "exclamationmark.circle", Theme.Colors.blue700, Theme.Colors.white,
                      border: Theme.Colors.blue600)
        }
    }

    private init(_ text: String, _ systemImage: String, _ foreground: Color, _ background: Color, border: Color? = nil) {
        self.text = text
        self.systemImage = systemImage
        self.foreground = foreground
        self.background = background
        self.border = border
    }

    var pill: EventStatusPill {
        EventStatusPill(text: text, systemImage: systemImage, foreground: foreground, background: background, border: border)
    }
}

// MARK: - Rows

struct LearnerEventRow: View {
    let event: LearnerEvent
    let now: Date
    let onOpen: () -> Void

    var body: some View {
        let ended = event.hasEnded(now: now)
        let isToday = Calendar.current.isDate(event.start, inSameDayAs: now)
        let status = LearnerEventStatus(event: event, now: now)
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 0) {
                    Text(EventFormat.month(event.start)).font(AppFont.jakarta(11, .heavy))
                    Text(EventFormat.dayOfMonth(event.start)).font(AppFont.jakarta(22, .heavy))
                    Text(EventFormat.weekday(event.start)).font(AppFont.jakarta(11, .bold))
                }
                .foregroundStyle(isToday ? Theme.Colors.white : (ended ? Theme.Colors.ink500 : Theme.Colors.blue700))
                .frame(width: 56, height: 70)
                .background(isToday ? Theme.Colors.blue600 : (ended ? Theme.Colors.chipGrey : Theme.Colors.blue50),
                            in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 5) {
                    EventCategoryChip(category: event.category)
                    Text(event.title).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    line("clock", EventFormat.isMultiDay(start: event.start, end: event.end)
                         ? EventFormat.whenLine(start: event.start, end: event.end, isAllDay: event.isAllDay, now: now)
                         : EventFormat.timeRange(start: event.start, end: event.end, isAllDay: event.isAllDay))
                    line(event.isOnline ? "video" : "mappin.and.ellipse", event.venue)
                    status.pill
                    if ended, let count = event.galleryItemCount {
                        Label(String(localized: "Photos and videos · \(count)"), systemImage: "photo.on.rectangle")
                            .font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.green700)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .dashboardCard(radius: 16)
            .opacity(ended ? 0.9 : 1)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
    }

    private func line(_ systemImage: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Image(systemName: systemImage).font(.system(size: 11, weight: .semibold)).frame(width: 14)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink700)
    }
}

struct FeaturedEventCard: View {
    let event: LearnerEvent
    let now: Date
    let onOpen: () -> Void

    var body: some View {
        let status: String = {
            if let response = event.myResponse { return String(localized: "Your response: \(response.title)") }
            let deadline = event.rsvpDeadline.map { String(localized: " · RSVP by \(EventFormat.day($0))") } ?? ""
            return String(localized: "\(EventFormat.count(event.goingCount)) going\(deadline)")
        }()
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                EventCoverBanner(category: event.category, caption: event.coverCaption, height: 130, accessibilityTitle: event.title)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("FEATURED").font(AppFont.jakarta(11, .heavy)).foregroundStyle(Theme.Colors.amber800)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Theme.Colors.warningBackground, in: Capsule())
                        EventCategoryChip(category: event.category)
                    }
                    Text(event.title).font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                    Label("\(EventFormat.day(event.start)) · \(EventFormat.time(event.start))", systemImage: "calendar")
                        .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
                    HStack {
                        Text(status).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink500)
                        Spacer()
                        Text(event.myResponse == nil ? String(localized: "RSVP") : String(localized: "View"))
                            .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.white)
                            .padding(.horizontal, 18).frame(height: 40)
                            .background(Theme.Colors.blue600, in: .rect(cornerRadius: 10))
                    }
                }
                .padding(14)
            }
            .clipShape(.rect(cornerRadius: 16))
            .dashboardCard(radius: 16)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Featured: \(event.title). \(status)")
    }
}

#Preview {
    NavigationStack { LearnerEventsView() }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
