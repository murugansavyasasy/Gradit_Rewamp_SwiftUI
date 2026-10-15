//
//  LearnerEventDetailView.swift
//  Gradit
//
//  Event detail for students and parents: facts, add to calendar, share, gallery,
//  RSVP with guests and the confirmation sheet. Also the organiser's receiver preview.
//  Design: 12 Events › Students & Parents › Event detail (+ RSVP confirmation, Full,
//  Registration closed, Ended, Ended with gallery) and Management › Preview.
//

import SwiftUI

struct LearnerEventDetailView: View {
    let eventID: String

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: LearnerEventDetailViewModel?

    var body: some View {
        Group {
            if let model {
                LearnerEventDetailContent(model: model, onBack: { dismiss() }) {
                    if model.showsRSVP {
                        EventBottomBar {
                            if model.selection == nil {
                                EventBarButton(title: String(localized: "Choose a response"), isEnabled: false) {}
                            } else {
                                EventBarButton(title: model.confirmTitle, systemImage: "checkmark",
                                               isLoading: model.isSubmitting, isEnabled: model.canSubmit) {
                                    Task { await model.submit() }
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: Binding(get: { model.showsConfirmation }, set: { model.showsConfirmation = $0 })) {
                    RSVPConfirmationSheet(model: model) {
                        model.showsConfirmation = false
                        dismiss()
                    }
                }
            } else {
                Theme.Colors.surfaceMuted.ignoresSafeArea()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .keepsSwipeBack()
        .task {
            if model == nil { model = LearnerEventDetailViewModel(eventID: eventID, service: dependencies.eventService) }
            await model?.load()
        }
    }
}

/// Shared body of the receiver detail (live and preview).
struct LearnerEventDetailContent<Footer: View>: View {
    @Bindable var model: LearnerEventDetailViewModel
    var previewNote: String?
    let onBack: () -> Void
    @ViewBuilder var footer: () -> Footer

    @Environment(AppRouter.self) private var router: AppRouter?
    @Environment(\.openURL) private var openURL
    @State private var addsToCalendar = false

    var body: some View {
        VStack(spacing: 0) {
            EventTopBar(title: model.isPreview ? String(localized: "Preview") : String(localized: "Event"),
                        backLabel: model.isPreview ? "Back to edit" : "Back to events", onBack: onBack) {
                if let event = model.event, !model.isPreview {
                    ShareLink(item: EventShareLinks.event(event.id), subject: Text(event.title)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.Colors.ink900)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Share event")
                }
            }
            if let previewNote {
                Label(previewNote, systemImage: "eye")
                    .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.blue700)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Theme.Colors.blue50)
            }
            if let event = model.event {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header(event)
                        if model.hasEnded { gallerySection(event) }
                        if model.showsRSVP { rsvpSection(event) }
                        if let block = model.block { blockCard(block) }
                        about(event)
                    }
                    .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                footer()
            } else if let error = model.errorMessage {
                EventStateCard(systemImage: "calendar.badge.exclamationmark", tint: Theme.Colors.red700,
                               tintBackground: Theme.Colors.errorBackground,
                               title: String(localized: "Couldn’t open this event"), message: error)
                    .padding(16)
                Spacer()
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .eventFloatingToast($model.toast)
        .sheet(isPresented: $addsToCalendar) {
            if let event = model.event {
                AddToCalendarSheet(title: event.title, start: event.start, end: event.end, isAllDay: event.isAllDay,
                                   location: event.venue, notes: event.description) { saved in
                    addsToCalendar = false
                    if saved { model.toast = String(localized: "Added to your calendar") }
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: Header

    private func header(_ event: LearnerEvent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            EventCoverBanner(category: event.category, caption: event.coverCaption, height: 140, accessibilityTitle: event.title)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    EventCategoryChip(category: event.category)
                    if let state = model.stateLabel {
                        EventStatusPill(text: state.0,
                                        foreground: state.1 == .danger ? Theme.Colors.red700 : Theme.Colors.ink700,
                                        background: state.1 == .danger ? Theme.Colors.errorBackground : Theme.Colors.chipGrey)
                    }
                }
                Text(event.title).font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: 10) {
                    fact("calendar", EventFormat.dateLine(start: event.start, end: event.end))
                    fact("clock", EventFormat.timeRange(start: event.start, end: event.end, isAllDay: event.isAllDay))
                    HStack(spacing: 8) {
                        fact(event.isOnline ? "video" : "mappin.and.ellipse", event.venue)
                        Spacer(minLength: 0)
                        if event.isOnline, let link = event.meetingLink, let url = URL(string: link) {
                            pillLink(String(localized: "Join"), systemImage: "video.fill",
                                     label: String(localized: "Join online meeting: \(link)")) { openURL(url) }
                        } else if event.venue != String(localized: "Campus closed"), !event.isOnline {
                            pillLink(String(localized: "Map"), systemImage: "map",
                                     label: String(localized: "Open \(event.venue) in maps")) { openMaps(event.venue) }
                        }
                    }
                    if !event.organiser.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            IconTile(systemImage: "person.fill", size: 32, radius: 10)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.organiser).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                                if !event.organiserRole.isEmpty {
                                    Text(event.organiserRole).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                if !model.isPreview && !model.hasEnded {
                    HStack(spacing: 10) {
                        EventBarButton(title: String(localized: "Add to calendar"), systemImage: "calendar.badge.plus", style: .outline) {
                            addsToCalendar = true
                        }
                        ShareLink(item: EventShareLinks.event(event.id), subject: Text(event.title),
                                  message: Text("\(event.title) · \(EventFormat.whenLine(start: event.start, end: event.end, isAllDay: event.isAllDay))")) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                        }
                    }
                }
            }
            .padding(16)
        }
        .clipShape(.rect(cornerRadius: 16))
        .dashboardCard(radius: 16)
    }

    private func fact(_ systemImage: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            IconTile(systemImage: systemImage, size: 32, radius: 10)
            Text(text).font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink900)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
    }

    private func pillLink(_ title: String, systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue700)
                .padding(.horizontal, 12).frame(height: 36)
                .background(Theme.Colors.blue50, in: Capsule())
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func openMaps(_ venue: String) {
        let query = "\(venue), \(AppConfig.collegeName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://maps.apple.com/?q=\(query)") { openURL(url) }
    }

    // MARK: Gallery

    @ViewBuilder
    private func gallerySection(_ event: LearnerEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gallery").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if let gallery = model.gallery {
                    Text(EventFormat.mediaCount(photos: gallery.photoCount, videos: gallery.videoCount))
                        .font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
                }
            }
            if let gallery = model.gallery, let cover = gallery.cover {
                Button { router?.push(.event(.gallery(eventID: event.id))) } label: {
                    GalleryCoverBanner(tint: cover.tint, symbol: cover.symbol, caption: cover.caption, imageURL: cover.thumbnailURL)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Open gallery. Cover photo: \(cover.caption)")
                HStack(spacing: 6) {
                    ForEach(Array(gallery.items.prefix(6))) { item in
                        Button { router?.push(.event(.gallery(eventID: event.id))) } label: {
                            GalleryTileView(item: item, cornerRadius: 8, symbolSize: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                EventBarButton(title: String(localized: "View all \(gallery.items.count)"), systemImage: "photo.on.rectangle", style: .outline) {
                    router?.push(.event(.gallery(eventID: event.id)))
                }
            } else if event.galleryItemCount != nil {
                EventBarButton(title: String(localized: "Open gallery"), systemImage: "photo.on.rectangle", style: .outline) {
                    router?.push(.event(.gallery(eventID: event.id)))
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle").font(.system(size: 22)).foregroundStyle(Theme.Colors.blue600)
                    Text("No photos or videos yet").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("You’ll get a notification when the organiser adds them.")
                        .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(16)
                .background(Theme.Colors.blue50.opacity(0.6), in: .rect(cornerRadius: 12))
            }
        }
        .padding(16)
        .dashboardCard(radius: 16)
    }

    // MARK: RSVP

    private func rsvpSection(_ event: LearnerEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Will you attend?").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if let deadline = event.rsvpDeadline {
                    Text("RSVP by \(EventFormat.day(deadline))").font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
                }
            }
            if let current = model.currentResponseText, let response = event.myResponse {
                Label(String(localized: "Your response: \(current)"), systemImage: response.systemImage)
                    .font(AppFont.jakarta(13, .bold)).foregroundStyle(response.foreground)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(response.background, in: Capsule())
            }
            HStack(spacing: 8) {
                ForEach(RSVPResponse.allCases) { response in
                    let isOn = model.selection == response
                    Button { model.selection = response } label: {
                        VStack(spacing: 4) {
                            Image(systemName: response.systemImage).font(.system(size: 16, weight: .bold))
                            Text(response.title).font(AppFont.jakarta(13, .bold)).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(isOn ? Theme.Colors.blue700 : Theme.Colors.ink700)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(isOn ? Theme.Colors.blue50 : Theme.Colors.white, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isOn ? Theme.Colors.blue600 : Theme.Colors.border, lineWidth: isOn ? 2 : 1))
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isPreview)
                    .accessibilityAddTraits(isOn ? [.isSelected] : [])
                }
            }
            if model.showsGuests {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Guests").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                        Text("Up to \(event.maxGuests) family members").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Spacer()
                    stepperButton("minus", label: "Fewer guests", enabled: model.guests > 0) { model.changeGuests(by: -1) }
                    Text("\(model.guests)").font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .frame(minWidth: 24)
                        .accessibilityLabel("\(model.guests) guests")
                    stepperButton("plus", label: "More guests", enabled: model.guests < event.maxGuests) { model.changeGuests(by: 1) }
                }
                .padding(12)
                .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
            }
            Text(model.seatsLine).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
        }
        .padding(16)
        .dashboardCard(radius: 16)
    }

    private func stepperButton(_ systemImage: String, label: LocalizedStringKey, enabled: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage).font(.system(size: 14, weight: .bold))
                .foregroundStyle(enabled ? Theme.Colors.blue700 : Theme.Colors.ink300)
                .frame(width: 44, height: 44)
                .background(Theme.Colors.white, in: Circle())
                .overlay(Circle().strokeBorder(Theme.Colors.border))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func blockCard(_ block: LearnerEventDetailViewModel.Block) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: block.tone == .danger ? "nosign" : "info.circle.fill")
                .font(.system(size: 18, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(block.title).font(AppFont.jakarta(15, .heavy))
                Text(block.message).font(AppFont.jakarta(13)).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(block.tone == .danger ? Theme.Colors.red700 : Theme.Colors.ink700)
        .padding(14)
        .background(block.tone == .danger ? Theme.Colors.errorBackground : Theme.Colors.chipGrey, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    // MARK: About

    private func about(_ event: LearnerEvent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About this event").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink500)
            ForEach(event.paragraphs, id: \.self) { paragraph in
                Text(paragraph).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !event.attachments.isEmpty {
                Text("Attachments").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink500).padding(.top, 4)
                ForEach(event.attachments) { file in AttachmentRow(attachment: file) }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }
}

// MARK: - Confirmation

private struct RSVPConfirmationSheet: View {
    let model: LearnerEventDetailViewModel
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var addsToCalendar = false
    @State private var toast: String?

    var body: some View {
        let response = model.event?.myResponse ?? .going
        let event = model.event
        VStack(spacing: 14) {
            Image(systemName: response.systemImage)
                .font(.system(size: 26, weight: .bold)).foregroundStyle(response.foreground)
                .frame(width: 64, height: 64).background(response.background, in: Circle())
                .accessibilityHidden(true)
            Text(title(response)).font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .accessibilityAddTraits(.isHeader)
            Text(message(response, deadline: event?.rsvpDeadline))
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700).multilineTextAlignment(.center)
            if let event {
                VStack(spacing: 0) {
                    row(String(localized: "Event"), event.title, divider: true)
                    row(String(localized: "When"), "\(EventFormat.day(event.start)) · \(EventFormat.time(event.start))", divider: true)
                    row(String(localized: "Response"), model.currentResponseText ?? response.title, divider: false)
                }
                .padding(.horizontal, 14)
                .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
            }
            if response == .going {
                EventBarButton(title: String(localized: "Add to calendar"), systemImage: "calendar.badge.plus", style: .outline) {
                    addsToCalendar = true
                }
            }
            EventBarButton(title: String(localized: "Done"), action: onDone)
            Button("Change response") { dismiss() }
                .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(20)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Radius.sheet)
        .eventFloatingToast($toast)
        .sheet(isPresented: $addsToCalendar) {
            if let event {
                AddToCalendarSheet(title: event.title, start: event.start, end: event.end, isAllDay: event.isAllDay,
                                   location: event.venue, notes: event.description) { saved in
                    addsToCalendar = false
                    if saved { toast = String(localized: "Added to your calendar") }
                }
                .ignoresSafeArea()
            }
        }
    }

    private func title(_ response: RSVPResponse) -> String {
        switch response {
        case .going: String(localized: "You’re going!")
        case .maybe: String(localized: "Marked as maybe")
        case .notGoing: String(localized: "You’re not going")
        }
    }

    private func message(_ response: RSVPResponse, deadline: Date?) -> String {
        switch response {
        case .going: return String(localized: "We’ll remind you a day before.")
        case .maybe:
            let date = deadline.map(EventFormat.day) ?? String(localized: "the deadline")
            return String(localized: "Please confirm before \(date) so the organisers can plan seats.")
        case .notGoing: return String(localized: "Thanks for letting the organisers know.")
        }
    }

    private func row(_ label: String, _ value: String, divider: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).frame(width: 80, alignment: .leading)
            Text(value).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if divider { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { LearnerEventDetailView(eventID: "e-kalai") }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
