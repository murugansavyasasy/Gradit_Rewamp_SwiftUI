//
//  StaffEventDetailView.swift
//  Gradit
//
//  Organiser's event detail: facts, actions (edit, remind, duplicate, export,
//  cancel, delete), gallery status, registration summary and the attendee list.
//  Design: 12 Events › Event detail (+ Just published, Completed, Cancel / Delete confirmation).
//

import SwiftUI

struct StaffEventDetailView: View {
    let eventID: String

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var model: StaffEventDetailViewModel?

    var body: some View {
        VStack(spacing: 0) {
            EventTopBar(title: String(localized: "Event"), backLabel: "Back to my events", onBack: { dismiss() })
            if let model {
                if let detail = model.detail {
                    content(model, detail: detail)
                } else if let error = model.errorMessage {
                    EventStateCard(systemImage: "wifi.exclamationmark", tint: Theme.Colors.red700,
                                   tintBackground: Theme.Colors.errorBackground,
                                   title: String(localized: "Couldn’t load this event"), message: error,
                                   actionTitle: String(localized: "Try again"), actionImage: "arrow.clockwise") {
                        Task { await model.refresh() }
                    }
                    .padding(16)
                    Spacer()
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Spacer()
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .keepsSwipeBack()
        .overlay { dialogs }
        .task {
            if model == nil { model = StaffEventDetailViewModel(eventID: eventID, service: dependencies.eventService) }
            if model?.detail == nil {
                await model?.load()
            } else {
                await model?.refresh()
            }
        }
    }

    // MARK: - Content

    private func content(_ model: StaffEventDetailViewModel, detail: StaffEventDetail) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                header(model, detail: detail)
                actions(model, detail: detail)
                if let toast = model.toast {
                    EventToastView(toast: toast)
                        .transition(.opacity)
                        .task(id: toast) {
                            try? await Task.sleep(for: .seconds(4))
                            withAnimation { model.toast = nil }
                        }
                }
                gallerySection(model, detail: detail)
                registrationSection(model, detail: detail)
                attendeesSection(model, detail: detail)
                aboutSection(detail)
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 24)
            .animation(.easeOut(duration: 0.2), value: model.toast)
        }
        .scrollIndicators(.hidden)
        .refreshable { await model.refresh() }
    }

    private func header(_ model: StaffEventDetailViewModel, detail: StaffEventDetail) -> some View {
        let event = detail.event
        return VStack(alignment: .leading, spacing: 0) {
            EventCoverBanner(category: event.category, caption: detail.coverCaption, height: 132, accessibilityTitle: event.title)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    EventCategoryChip(category: event.category)
                    EventStatusPill(status: model.status)
                }
                Text(event.title)
                    .font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                ForEach(facts(model, detail: detail), id: \.1) { fact in
                    EventFactRow(systemImage: fact.0, label: fact.1, value: fact.2)
                }
            }
            .padding(16)
        }
        .clipShape(.rect(cornerRadius: 16))
        .dashboardCard(radius: 16)
    }

    private func facts(_ model: StaffEventDetailViewModel, detail: StaffEventDetail) -> [(String, String, String)] {
        let event = detail.event
        let date = "\(EventFormat.dateLine(start: event.start, end: event.end)) · \(EventFormat.timeRange(start: event.start, end: event.end, isAllDay: event.isAllDay))"
        var schedule: String
        if let published = detail.publishedAt {
            schedule = String(localized: "Published \(EventFormat.stamp(published, now: model.now))")
        } else {
            schedule = String(localized: "Not published")
        }
        if model.isPast {
            schedule += String(localized: " · Ended \(EventFormat.stamp(event.end, now: model.now))")
        } else if let deadline = detail.rsvpDeadline {
            schedule += String(localized: " · RSVP by \(EventFormat.day(deadline))")
        }
        var reminders: [String] = []
        if detail.reminders.dayBefore { reminders.append(String(localized: "1 day")) }
        if detail.reminders.hourBefore { reminders.append(String(localized: "1 hour")) }
        var channels: [String] = []
        if detail.reminders.push { channels.append(String(localized: "push")) }
        if detail.reminders.sms { channels.append(String(localized: "SMS")) }
        let reminderText = reminders.isEmpty
            ? String(localized: "None")
            : String(localized: "\(reminders.joined(separator: String(localized: " and "))) before · \(channels.joined(separator: String(localized: " and ")))")
        return [
            ("calendar", String(localized: "Date and time"), date),
            (event.isOnline ? "video" : "mappin.and.ellipse", String(localized: "Venue"), event.venue),
            ("person.2", String(localized: "Audience"), String(localized: "\(EventFormat.count(event.invitedCount)) invited · \(event.audienceText)")),
            ("clock", String(localized: "Schedule"), schedule),
            ("bell", String(localized: "Reminders"), reminderText),
        ]
    }

    // MARK: - Actions

    private func actions(_ model: StaffEventDetailViewModel, detail: StaffEventDetail) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        let noResponse = detail.responseCounts.noResponse
        return LazyVGrid(columns: columns, spacing: 8) {
            if !model.isPast && model.status != .cancelled {
                actionTile("pencil", String(localized: "Edit")) { router.push(.event(.create(.edit(eventID)))) }
                actionTile("bell.badge", String(localized: "Remind"),
                           label: String(localized: "Send reminder to \(noResponse) people with no response")) {
                    Task { await model.remind() }
                }
            }
            actionTile("plus.square.on.square", String(localized: "Duplicate"), label: String(localized: "Duplicate as a new event")) {
                router.push(.event(.create(.duplicate(eventID))))
            }
            actionTile("square.and.arrow.down", String(localized: "Export list"), label: String(localized: "Export attendee list")) {
                Task { await model.exportList() }
            }
            if model.canCancel {
                actionTile("nosign", String(localized: "Cancel event"), tint: Theme.Colors.red700) {
                    model.dialog = .cancel
                }
            }
            actionTile("trash", String(localized: "Delete"), tint: Theme.Colors.red700) {
                model.dialog = .delete
            }
        }
    }

    private func actionTile(_ systemImage: String, _ title: String, tint: Color = Theme.Colors.blue700,
                            label: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage).font(.system(size: 17, weight: .semibold))
                Text(title).font(AppFont.jakarta(12, .bold)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Theme.Colors.white, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.line))
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label ?? title)
    }

    // MARK: - Gallery

    private func gallerySection(_ model: StaffEventDetailViewModel, detail: StaffEventDetail) -> some View {
        let gallery = detail.event.gallery
        let status = model.status
        let badge: (String, Color, Color) = {
            if let gallery { return gallery.isPublished
                ? (String(localized: "Published"), Theme.Colors.green700, Theme.Colors.green50)
                : (String(localized: "Unpublished"), Theme.Colors.ink700, Theme.Colors.chipGrey) }
            if status == .completed { return (String(localized: "Not added"), Theme.Colors.amber800, Theme.Colors.warningBackground) }
            if status == .cancelled { return (String(localized: "Not available"), Theme.Colors.ink700, Theme.Colors.chipGrey) }
            return (String(localized: "After the event"), Theme.Colors.ink700, Theme.Colors.chipGrey)
        }()
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gallery").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                EventStatusPill(text: badge.0, foreground: badge.1, background: badge.2)
            }
            if let gallery {
                GalleryCoverBanner(tint: gallery.coverTint, symbol: gallery.coverSymbol, caption: gallery.coverCaption)
                Label(galleryLine(gallery, now: model.now), systemImage: "photo.on.rectangle")
                    .font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
                EventProgressRow(text: String(localized: "\(EventFormat.count(gallery.views)) / \(EventFormat.count(gallery.audience)) viewed"),
                                 percentText: EventFormat.percent(gallery.views, of: gallery.audience),
                                 fraction: gallery.audience > 0 ? Double(gallery.views) / Double(gallery.audience) : 0,
                                 tint: Theme.Colors.blue600)
                EventBarButton(title: String(localized: "Manage gallery"), systemImage: "photo.stack") {
                    router.push(.event(.manageGallery(eventID: eventID)))
                }
            } else if status == .completed {
                VStack(spacing: 6) {
                    Image(systemName: "photo.badge.plus").font(.system(size: 22)).foregroundStyle(Theme.Colors.amber800)
                    Text("No photos or videos yet").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("This event ended \(EventFormat.stamp(detail.event.end, now: model.now)). Add photos and videos so students and parents can see the day.")
                        .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(16)
                .background(Theme.Colors.warningBackground.opacity(0.6), in: .rect(cornerRadius: 12))
                EventBarButton(title: String(localized: "Add photos and videos"), systemImage: "plus") {
                    router.push(.event(.addMedia(eventID: eventID, source: .detail)))
                }
            } else {
                Label(status == .cancelled
                      ? String(localized: "Cancelled events can’t have a gallery.")
                      : String(localized: "You can add photos and videos after the event ends on \(EventFormat.day(detail.event.end)) at \(EventFormat.time(detail.event.end))."),
                      systemImage: "info.circle")
                    .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .dashboardCard(radius: 16)
    }

    private func galleryLine(_ gallery: GallerySummary, now: Date) -> String {
        let media = EventFormat.mediaCount(photos: gallery.photoCount, videos: gallery.videoCount)
        guard let published = gallery.publishedAt else { return media }
        return String(localized: "\(media) · published \(EventFormat.stamp(published, now: now))")
    }

    // MARK: - Registrations

    private func registrationSection(_ model: StaffEventDetailViewModel, detail: StaffEventDetail) -> some View {
        let counts = detail.responseCounts
        let event = detail.event
        let seats = detail.seatLimit
        let denominator = model.isPast || seats == nil ? event.invitedCount : (seats ?? 0)
        let progressText: String
        if model.isPast || seats == nil {
            progressText = String(localized: "\(EventFormat.count(counts.going)) going / \(EventFormat.count(event.invitedCount)) invited")
        } else {
            progressText = String(localized: "\(EventFormat.count(counts.going)) / \(EventFormat.count(seats ?? 0)) seats filled")
        }
        let note: String
        if model.isPast {
            note = String(localized: "RSVP closed on \(detail.rsvpDeadline.map(EventFormat.day) ?? "—"). The event has ended.")
        } else if let seats, let deadline = detail.rsvpDeadline {
            note = String(localized: "\(max(seats - counts.going, 0)) seats left · RSVP closes \(EventFormat.day(deadline))")
        } else if let deadline = detail.rsvpDeadline {
            note = String(localized: "No seat limit · RSVP closes \(EventFormat.day(deadline))")
        } else {
            note = String(localized: "No RSVP needed for this event.")
        }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Registrations").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 8) {
                tile(counts.going, RSVPResponse.going.title, Theme.Colors.green50, Theme.Colors.green700)
                tile(counts.maybe, RSVPResponse.maybe.title, Theme.Colors.warningBackground, Theme.Colors.amber800)
                tile(counts.notGoing, RSVPResponse.notGoing.title, Theme.Colors.chipGrey, Theme.Colors.ink700)
                tile(counts.noResponse, String(localized: "No response"), Theme.Colors.errorBackground, Theme.Colors.red700)
            }
            EventProgressRow(text: progressText, percentText: EventFormat.percent(counts.going, of: denominator),
                             fraction: denominator > 0 ? Double(counts.going) / Double(denominator) : 0)
            Text(note).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
        }
        .padding(16)
        .dashboardCard(radius: 16)
    }

    private func tile(_ value: Int, _ label: String, _ background: Color, _ foreground: Color) -> some View {
        VStack(spacing: 2) {
            Text(EventFormat.count(value)).font(AppFont.jakarta(20, .heavy))
            Text(label).font(AppFont.jakarta(11, .bold)).lineLimit(1).minimumScaleFactor(0.7)
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(background, in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Attendees

    private func attendeesSection(_ model: StaffEventDetailViewModel, detail: StaffEventDetail) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 12) {
            Text("Attendees").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .accessibilityAddTraits(.isHeader)
            EventSearchField(placeholder: String(localized: "Search name or reg. no."), text: $model.searchText)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(StaffEventDetailViewModel.ResponseFilter.allCases) { filter in
                        let isOn = model.filter == filter
                        Button { model.filter = filter } label: {
                            HStack(spacing: 6) {
                                Text(filter.title)
                                Text("\(model.count(filter))")
                                    .font(AppFont.jakarta(11, .heavy))
                                    .padding(.horizontal, 6).padding(.vertical, 1)
                                    .background(isOn ? Theme.Colors.white.opacity(0.25) : Theme.Colors.chipGrey, in: Capsule())
                            }
                            .font(AppFont.jakarta(13, .bold))
                            .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                            .padding(.horizontal, 12).frame(height: 40)
                            .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                            .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isOn ? [.isSelected] : [])
                    }
                }
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 0) {
                let rows = model.visibleAttendees
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, attendee in
                    attendeeRow(attendee, invitedAt: detail.publishedAt, now: model.now)
                        .overlay(alignment: .bottom) {
                            if index < rows.count - 1 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                        }
                }
                if rows.isEmpty {
                    Text("No attendees match.").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                        .frame(maxWidth: .infinity).padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 12)
            .dashboardCard(radius: 14)

            if model.hasMore {
                Button { model.showsAll = true } label: {
                    Text("Show all \(model.matchingCount)")
                        .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.blue600)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .dashboardCard(radius: 16)
    }

    private func attendeeRow(_ attendee: EventAttendee, invitedAt: Date?, now: Date) -> some View {
        let response = attendee.response
        let when = attendee.respondedAt.map { String(localized: "Replied \(EventFormat.stamp($0, now: now))") }
            ?? invitedAt.map { String(localized: "Invited \(EventFormat.shortDay($0))") } ?? ""
        return HStack(spacing: 10) {
            InitialsAvatar(initials: DashboardGreeting.initials(attendee.name), size: 38,
                           foreground: attendee.isStaff ? Theme.Colors.amber800 : Theme.Colors.green700,
                           background: attendee.isStaff ? Theme.Colors.warningBackground : Theme.Colors.green50)
            VStack(alignment: .leading, spacing: 1) {
                Text(attendee.name).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900).lineLimit(1)
                Text(attendee.classLabel).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                EventStatusPill(text: response?.title ?? String(localized: "No response"),
                                foreground: response?.foreground ?? Theme.Colors.red700,
                                background: response?.background ?? Theme.Colors.errorBackground)
                Text(when).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    // MARK: - About

    private func aboutSection(_ detail: StaffEventDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Description").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink500)
            let paragraphs = detail.description.components(separatedBy: "\n\n").filter { !$0.isBlank }
            ForEach(paragraphs, id: \.self) { paragraph in
                Text(paragraph).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(detail.attachments) { file in
                AttachmentRow(attachment: file)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    // MARK: - Dialogs

    @ViewBuilder
    private var dialogs: some View {
        if let model, let detail = model.detail {
            switch model.dialog {
            case .cancel:
                cancelDialog(model, detail: detail)
            case .delete:
                EventAlertCard(systemImage: "trash", title: String(localized: "Delete this event?"),
                               message: String(localized: "It will be removed for all \(EventFormat.count(detail.event.invitedCount)) invitees and the attendee list will be lost. This can’t be undone."),
                               confirmTitle: String(localized: "Delete"), isWorking: model.isWorking,
                               onConfirm: {
                                   Task {
                                       if await model.deleteEvent() { dismiss() }
                                   }
                               },
                               onCancel: { model.dialog = nil })
            case nil:
                EmptyView()
            }
        }
    }

    private func cancelDialog(_ model: StaffEventDetailViewModel, detail: StaffEventDetail) -> some View {
        @Bindable var model = model
        let counts = detail.responseCounts
        return EventAlertCard(
            title: String(localized: "Cancel this event?"),
            message: String(localized: "Everyone who RSVP’d (\(counts.going) going, \(counts.maybe) maybe) will see it as Cancelled. You can’t undo this."),
            cancelTitle: String(localized: "Keep event"), confirmTitle: String(localized: "Cancel event"),
            isWorking: model.isWorking,
            onConfirm: { Task { await model.cancelEvent() } },
            onCancel: { model.dialog = nil },
            extra: {
                VStack(alignment: .leading, spacing: 6) {
                    EventFieldLabel(text: String(localized: "Reason (shown to invitees)"))
                    TextField(String(localized: "Reason"), text: $model.cancelReason, axis: .vertical)
                        .font(AppFont.jakarta(14)).lineLimit(2...4)
                        .padding(10)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
                }
                EventToggleRow(title: String(localized: "Notify invitees"), subtitle: String(localized: "Push and SMS to everyone invited"),
                               isOn: $model.notifyInvitees)
            })
    }
}

#Preview {
    NavigationStack { StaffEventDetailView(eventID: "e-ai") }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
