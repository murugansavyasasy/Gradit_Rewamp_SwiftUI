//
//  CreateEventView.swift
//  Gradit
//
//  Create / edit / duplicate an event: cover, details, date and time, venue,
//  audience, RSVP, attachments, reminders and publish options.
//  Design: 12 Events › Management & Teachers › Create Event (+ Errors, Date picker, Preview, Published).
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct CreateEventView: View {
    let mode: CreateEventViewModel.Mode

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(ProfileStore.self) private var profileStore: ProfileStore?
    @Environment(\.dismiss) private var dismiss
    @State private var model: CreateEventViewModel?
    @State private var dateField: CreateEventViewModel.DateField?
    @State private var coverItem: PhotosPickerItem?
    @State private var isImporting = false
    @State private var isPreviewing = false
    @State private var isPublished = false

    var body: some View {
        VStack(spacing: 0) {
            EventTopBar(title: model?.title ?? String(localized: "Create event"),
                        backLabel: "Back to my events", onBack: { dismiss() }) {
                if model?.savedNotice == true {
                    EventStatusPill(text: String(localized: "Draft saved"), systemImage: "checkmark",
                                    foreground: Theme.Colors.green700, background: Theme.Colors.green50)
                }
            }
            if let model {
                if model.isLoading && model.options == nil {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    form(model)
                    bottomBar(model)
                }
            } else {
                Spacer()
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .keepsSwipeBack()
        .task {
            if model == nil { model = CreateEventViewModel(mode: mode, service: dependencies.eventService) }
            await model?.load()
        }
        .task(id: model?.draft.audience) { await model?.refreshCounts() }
        .sheet(item: $dateField) { field in
            if let model {
                EventDateSheet(title: field.title, selected: model.date(for: field),
                               minimumDate: field == .end ? model.draft.start : model.now) { day in
                    model.setDay(day, for: field)
                }
            }
        }
        .fullScreenCover(isPresented: $isPreviewing) {
            if let model {
                EventPreviewScreen(event: model.previewEvent(organiser: profileStore?.profile?.fullName ?? ""),
                                   inviteeCount: model.invitedTotal,
                                   isPublishing: model.isPublishing,
                                   publishTitle: model.schedulePublish ? String(localized: "Schedule") : String(localized: "Publish")) {
                    isPreviewing = false
                } onPublish: {
                    Task {
                        if await model.publish() {
                            isPreviewing = false
                            isPublished = true
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isPublished) {
            if let model, let event = model.publishedEvent {
                EventPublishedView(title: event.title, deadline: model.draft.rsvpRequired ? model.draft.rsvpDeadline : nil,
                                   isScheduled: model.schedulePublish, facts: model.publishedFacts) {
                    isPublished = false
                    router.pop()
                } onView: {
                    isPublished = false
                    router.pop()
                    router.push(.event(.staffDetail(id: event.id)))
                } onCreateAnother: {
                    model.reset()
                    isPublished = false
                }
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf, .image, .plainText, .data],
                      allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            for url in urls {
                let accessed = url.startAccessingSecurityScopedResource()
                model?.addAttachment(url: url)
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
        }
        .onChange(of: coverItem) {
            guard let coverItem else { return }
            Task {
                if let data = try? await coverItem.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    model?.coverImage = image
                    model?.draft.hasCover = true
                }
                self.coverItem = nil
            }
        }
        .alert("Couldn’t save the event", isPresented: Binding(
            get: { model?.errorMessage != nil && model?.options != nil },
            set: { if !$0 { model?.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model?.errorMessage ?? "")
        }
    }

    // MARK: - Form

    private func form(_ model: CreateEventViewModel) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                if model.showsErrors && !model.isValid {
                    errorBanner(model)
                }
                coverCard(model)
                detailsCard(model)
                dateCard(model)
                venueCard(model)
                audienceCard(model)
                registrationCard(model)
                attachmentsCard(model)
                optionsCard(model)
                PoweredByFooter()
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func errorBanner(_ model: CreateEventViewModel) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.Colors.error)
            VStack(alignment: .leading, spacing: 4) {
                let count = model.errorSummary.count
                Text(count == 1 ? String(localized: "Fix 1 thing before publishing") : String(localized: "Fix \(count) things before publishing"))
                    .font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.red800)
                ForEach(model.errorSummary, id: \.self) { message in
                    Text("• \(message)").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.red700)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Theme.Colors.errorBackground, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.error.opacity(0.4)))
        .accessibilityElement(children: .combine)
    }

    private func coverCard(_ model: CreateEventViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cover image").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
            if model.coverImage != nil || model.draft.hasCover {
                VStack(spacing: 0) {
                    Group {
                        if let image = model.coverImage {
                            Image(uiImage: image).resizable().scaledToFill()
                                .frame(maxWidth: .infinity).frame(height: 150).clipped()
                                .accessibilityLabel(Text("Cover image: \(model.draft.title)"))
                        } else {
                            EventCoverBanner(category: model.draft.category, caption: String(localized: "Cover preview"),
                                             height: 150, accessibilityTitle: model.draft.title)
                        }
                    }
                    HStack(spacing: 10) {
                        Text(model.coverImage == nil ? String(localized: "Category cover") : String(localized: "Your photo"))
                            .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                        Spacer(minLength: 0)
                        PhotosPicker(selection: $coverItem, matching: .images) {
                            Text("Replace").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue600)
                                .padding(.horizontal, 12).frame(height: 36)
                                .background(Theme.Colors.blue50, in: .rect(cornerRadius: 10))
                        }
                        Button {
                            model.coverImage = nil
                            model.draft.hasCover = false
                        } label: {
                            Image(systemName: "trash").font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.Colors.destructive).frame(width: 36, height: 36)
                                .background(Theme.Colors.errorBackground, in: .rect(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove cover image")
                    }
                    .padding(12)
                }
                .clipShape(.rect(cornerRadius: 14))
                .dashboardCard(radius: 14)
            } else {
                PhotosPicker(selection: $coverItem, matching: .images) {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus").font(.system(size: 24, weight: .medium)).foregroundStyle(Theme.Colors.blue600)
                        Text("Upload cover image").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.blue700)
                        Text("JPG or PNG · 1200 × 630 recommended").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(Theme.Colors.blue50.opacity(0.5), in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.blueBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
                }
            }
        }
    }

    private func detailsCard(_ model: CreateEventViewModel) -> some View {
        let titleError = model.showsErrors ? model.titleError : nil
        return EventFormCard {
            VStack(alignment: .leading, spacing: 6) {
                EventFieldLabel(text: String(localized: "Event title"), isRequired: true)
                TextField(String(localized: "e.g. Kalai Vizha ’26"), text: Binding(
                    get: { model.draft.title },
                    set: { model.draft.title = String($0.prefix(80)) }))
                    .font(AppFont.jakarta(15, .semibold))
                    .padding(.horizontal, 14).frame(height: 48)
                    .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(titleError == nil ? Theme.Colors.border : Theme.Colors.error, lineWidth: titleError == nil ? 1 : 2))
                HStack {
                    if let titleError { EventFieldError(text: titleError) }
                    Spacer()
                    Text("\(model.draft.title.count) / 80").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                EventFieldLabel(text: String(localized: "Description"))
                TextField(String(localized: "What’s happening, who it’s for, what to bring"), text: Binding(
                    get: { model.draft.description },
                    set: { model.draft.description = String($0.prefix(1000)) }), axis: .vertical)
                    .font(AppFont.jakarta(14))
                    .lineLimit(5...10)
                    .padding(12)
                    .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
                Text("\(model.draft.description.count) / 1000").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            VStack(alignment: .leading, spacing: 8) {
                EventFieldLabel(text: String(localized: "Category"))
                EventFlowLayout {
                    ForEach(EventCategory.allCases) { category in
                        EventChoiceChip(title: category.title, isOn: model.draft.category == category, showsCheck: true) {
                            model.draft.category = category
                        }
                    }
                }
            }
        }
    }

    private func dateCard(_ model: CreateEventViewModel) -> some View {
        @Bindable var model = model
        let dateError = model.showsErrors ? model.dateError : nil
        let timeError = model.showsErrors ? model.timeError : nil
        return EventFormCard(isError: dateError != nil || timeError != nil) {
            EventToggleRow(title: String(localized: "All day"), subtitle: String(localized: "No start or end time"),
                           isOn: $model.draft.isAllDay)
            Grid(horizontalSpacing: 10, verticalSpacing: 12) {
                GridRow {
                    dateColumn(model, field: .start, isError: dateError != nil)
                    if !model.draft.isAllDay { timeColumn(model, start: true, isError: false) }
                }
                GridRow {
                    dateColumn(model, field: .end, isError: timeError != nil && model.draft.end < model.draft.start)
                    if !model.draft.isAllDay { timeColumn(model, start: false, isError: timeError != nil) }
                }
            }
            if let dateError { EventFieldError(text: dateError) }
            if let timeError { EventFieldError(text: timeError) }
        }
    }

    private func dateColumn(_ model: CreateEventViewModel, field: CreateEventViewModel.DateField, isError: Bool) -> some View {
        let date = model.date(for: field)
        return VStack(alignment: .leading, spacing: 6) {
            EventFieldLabel(text: field.title)
            EventPickerButton(systemImage: "calendar", text: EventFormat.day(date), isError: isError,
                              accessibilityLabel: "\(field.title): \(EventFormat.day(date)). Change") {
                dateField = field
            }
        }
    }

    private func timeColumn(_ model: CreateEventViewModel, start: Bool, isError: Bool) -> some View {
        let date = start ? model.draft.start : model.draft.end
        let current = model.minutes(of: date)
        return VStack(alignment: .leading, spacing: 6) {
            EventFieldLabel(text: start ? String(localized: "Start time") : String(localized: "End time"))
            FormDropdown(value: CreateEventViewModel.timeLabel(current),
                         options: model.timeOptions(including: date).map(CreateEventViewModel.timeLabel),
                         isError: isError) { label in
                if let minutes = model.timeOptions(including: date).first(where: { CreateEventViewModel.timeLabel($0) == label }) {
                    model.setTime(minutes, start: start)
                }
            }
        }
    }

    private func venueCard(_ model: CreateEventViewModel) -> some View {
        @Bindable var model = model
        return EventFormCard(title: String(localized: "Venue")) {
            EventSegmented(options: [(NewEventDraft.VenueKind.campus, String(localized: "Campus location")),
                                     (NewEventDraft.VenueKind.online, String(localized: "Online"))],
                           selection: $model.draft.venueKind)
            if model.draft.venueKind == .campus {
                VStack(alignment: .leading, spacing: 6) {
                    EventFieldLabel(text: String(localized: "Campus location"))
                    FormDropdown(value: model.draft.campusLocation, options: model.options?.campusLocations ?? []) {
                        model.draft.campusLocation = $0
                    }
                }
            } else {
                let linkError = model.showsErrors ? model.linkError : nil
                VStack(alignment: .leading, spacing: 6) {
                    EventFieldLabel(text: String(localized: "Meeting link"))
                    TextField("https://meet.google.com/…", text: $model.draft.meetingLink)
                        .font(AppFont.jakarta(14))
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .padding(.horizontal, 14).frame(height: 48)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(linkError == nil ? Theme.Colors.border : Theme.Colors.error, lineWidth: linkError == nil ? 1 : 2))
                    if let linkError { EventFieldError(text: linkError) }
                }
            }
        }
    }

    private func audienceCard(_ model: CreateEventViewModel) -> some View {
        @Bindable var model = model
        let audienceError = model.showsErrors ? model.audienceError : nil
        let sectionMissing = audienceError != nil && model.draft.audience.scope == .groups && model.draft.audience.section.isEmpty
        return EventFormCard(title: String(localized: "Audience"), isRequired: true, isError: audienceError != nil) {
            EventSegmented(options: [(AudienceSelection.Scope.wholeCollege, String(localized: "All (whole college)")),
                                     (AudienceSelection.Scope.groups, String(localized: "Choose classes"))],
                           selection: $model.draft.audience.scope)
            if model.draft.audience.scope == .groups, let options = model.options {
                VStack(alignment: .leading, spacing: 6) {
                    EventFieldLabel(text: String(localized: "Course / Department"))
                    FormDropdown(value: model.draft.audience.department, options: options.courses) { model.draft.audience.department = $0 }
                }
                VStack(alignment: .leading, spacing: 6) {
                    EventFieldLabel(text: String(localized: "Year / Semester"))
                    FormDropdown(value: model.draft.audience.yearSem, options: options.yearSems) { model.draft.audience.yearSem = $0 }
                }
                VStack(alignment: .leading, spacing: 6) {
                    EventFieldLabel(text: String(localized: "Section"))
                    FormDropdown(value: CreateEventViewModel.sectionTitle(model.draft.audience.section),
                                 options: options.sections.map(CreateEventViewModel.sectionTitle),
                                 isError: sectionMissing) { title in
                        if let value = options.sections.first(where: { CreateEventViewModel.sectionTitle($0) == title }) {
                            model.draft.audience.section = value
                        }
                    }
                }
            }
            EventFieldLabel(text: String(localized: "Invite"))
            HStack(spacing: 8) {
                ForEach(EventAudienceRole.allCases) { role in
                    roleToggle(model, role: role)
                }
            }
            if let audienceError { EventFieldError(text: audienceError) }
            EventFlowLayout(spacing: 6, rowSpacing: 6) {
                ForEach(model.audienceChips, id: \.self) { chip in
                    Text(chip).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.blue700)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Theme.Colors.blue50, in: Capsule())
                }
            }
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill").font(.system(size: 16))
                VStack(alignment: .leading, spacing: 1) {
                    Text(model.countLine).font(AppFont.jakarta(15, .heavy))
                    Text(model.countSubline).font(AppFont.jakarta(12, .semibold))
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(model.invitedTotal > 0 ? Theme.Colors.green700 : Theme.Colors.ink500)
            .padding(12)
            .background(model.invitedTotal > 0 ? Theme.Colors.green50 : Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
            .accessibilityElement(children: .combine)
        }
    }

    private func roleToggle(_ model: CreateEventViewModel, role: EventAudienceRole) -> some View {
        let isOn = model.draft.audience.roles.contains(role)
        return Button { model.toggleRole(role) } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: isOn ? "checkmark.square.fill" : "square")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isOn ? Theme.Colors.blue600 : Theme.Colors.ink400)
                    Text(role.title).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
                Text(EventFormat.count(model.counts.count(for: role)))
                    .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink500)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isOn ? Theme.Colors.blue50 : Theme.Colors.white, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isOn ? Theme.Colors.blue600 : Theme.Colors.border, lineWidth: isOn ? 2 : 1))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(role.title), \(model.counts.count(for: role))")
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private func registrationCard(_ model: CreateEventViewModel) -> some View {
        @Bindable var model = model
        return EventFormCard {
            EventToggleRow(title: String(localized: "Require RSVP"),
                           subtitle: String(localized: "Invitees reply Going, Maybe or Not going"),
                           isOn: $model.draft.rsvpRequired)
            if model.draft.rsvpRequired {
                HStack(alignment: .top, spacing: 10) {
                    dateColumn(model, field: .rsvp, isError: false)
                    VStack(alignment: .leading, spacing: 6) {
                        EventFieldLabel(text: String(localized: "Seat limit"), hint: String(localized: "(optional)"))
                        TextField(String(localized: "No limit"), text: $model.seatText)
                            .keyboardType(.numberPad)
                            .font(AppFont.jakarta(14, .bold))
                            .padding(.horizontal, 12).frame(height: 48)
                            .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
                    }
                }
                EventToggleRow(title: String(localized: "Allow guests"),
                               subtitle: String(localized: "Students can bring up to 2 family members"),
                               isOn: $model.draft.allowGuests)
            }
        }
    }

    private func attachmentsCard(_ model: CreateEventViewModel) -> some View {
        EventFormCard(title: String(localized: "Attachments")) {
            Button { isImporting = true } label: {
                Label("Add brochure or schedule", systemImage: "paperclip")
                    .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.blue700)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.Colors.blue50, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
            ForEach(model.draft.attachments) { file in
                AttachmentRow(attachment: file) {
                    model.draft.attachments.removeAll { $0.id == file.id }
                }
            }
        }
    }

    private func optionsCard(_ model: CreateEventViewModel) -> some View {
        @Bindable var model = model
        return EventFormCard {
            EventFieldLabel(text: String(localized: "Reminder before event"))
            HStack(spacing: 8) {
                EventChoiceChip(title: String(localized: "1 day before"), isOn: model.draft.reminders.dayBefore, showsCheck: true) {
                    model.draft.reminders.dayBefore.toggle()
                }
                EventChoiceChip(title: String(localized: "1 hour before"), isOn: model.draft.reminders.hourBefore, showsCheck: true) {
                    model.draft.reminders.hourBefore.toggle()
                }
            }
            Divider().overlay(Theme.Colors.divider)
            EventToggleRow(title: String(localized: "Notify by push"), subtitle: String(localized: "App notification when published"),
                           isOn: $model.draft.reminders.push)
            EventToggleRow(title: String(localized: "Notify by SMS"), subtitle: String(localized: "Short SMS with title, date and venue"),
                           isOn: $model.draft.reminders.sms)
            Divider().overlay(Theme.Colors.divider)
            EventFieldLabel(text: String(localized: "Publish"))
            EventSegmented(options: [(false, String(localized: "Now")), (true, String(localized: "Schedule"))],
                           selection: $model.schedulePublish)
            if model.schedulePublish {
                dateColumn(model, field: .publish, isError: false)
            }
        }
    }

    // MARK: - Bottom bar

    private func bottomBar(_ model: CreateEventViewModel) -> some View {
        EventBottomBar {
            EventBarButton(title: String(localized: "Save draft"), style: .outline, isLoading: model.isSaving) {
                Task { await model.saveDraft() }
            }
            EventBarButton(title: String(localized: "Preview"), systemImage: "eye", style: .outline) {
                if model.validateForPreview() { isPreviewing = true }
            }
            EventBarButton(title: model.schedulePublish ? String(localized: "Schedule") : String(localized: "Publish"),
                           isLoading: model.isPublishing) {
                Task { if await model.publish() { isPublished = true } }
            }
        }
    }
}

// MARK: - Date sheet

/// Month calendar bottom sheet; past dates can't be picked.
struct EventDateSheet: View {
    let title: String
    let selected: Date
    var minimumDate: Date?
    let onDone: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var day: Date
    @State private var month: Date

    init(title: String, selected: Date, minimumDate: Date? = nil, onDone: @escaping (Date) -> Void) {
        self.title = title
        self.selected = selected
        self.minimumDate = minimumDate
        self.onDone = onDone
        _day = State(initialValue: selected)
        _month = State(initialValue: selected)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            EventSheetHeader(title: title) { dismiss() }
            EventMonthHeader(month: $month, minimumMonth: minimumDate)
            EventMonthGrid(month: month, selected: day, minimumDate: minimumDate) { day = $0 }
            Text("Past dates can’t be picked.").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            Spacer(minLength: 0)
            PrimaryButton(title: LocalizedStringKey("Done · \(EventFormat.day(day))")) {
                onDone(day)
                dismiss()
            }
        }
        .padding(20)
        .presentationDetents([.height(600), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Radius.sheet)
    }
}

// MARK: - Preview

/// Receiver view of the draft with Edit / Publish at the bottom.
private struct EventPreviewScreen: View {
    let event: LearnerEvent
    let inviteeCount: Int
    let isPublishing: Bool
    let publishTitle: String
    let onEdit: () -> Void
    let onPublish: () -> Void

    var body: some View {
        LearnerEventDetailContent(model: LearnerEventDetailViewModel(preview: event),
                                  previewNote: String(localized: "Receiver preview — this is exactly what \(EventFormat.count(inviteeCount)) people will see."),
                                  onBack: onEdit) {
            EventBottomBar {
                EventBarButton(title: String(localized: "Edit"), systemImage: "pencil", style: .outline, action: onEdit)
                EventBarButton(title: publishTitle, systemImage: "paperplane.fill", isLoading: isPublishing, action: onPublish)
            }
        }
    }
}

#Preview {
    NavigationStack { CreateEventView(mode: .new) }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
