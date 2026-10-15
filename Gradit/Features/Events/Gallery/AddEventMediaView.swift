//
//  AddEventMediaView.swift
//  Gradit
//
//  Organiser adds photos and videos to a completed event: pick from camera or
//  library, captions and order, cover, who can see it, download and publish options.
//  Design: 12 Events › Add media (+ Captions and order, Item, Choose groups, Empty,
//  Upload failed, From Home / notification / event detail, Gallery preview, Gallery published).
//

import SwiftUI
import PhotosUI

struct AddEventMediaView: View {
    let eventID: String
    let source: AddEventMediaViewModel.Source

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var model: AddEventMediaViewModel?
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var videoItems: [PhotosPickerItem] = []
    @State private var isImporting = false
    @State private var showsCamera = false
    @State private var isPreviewing = false
    @State private var isPublished = false

    var body: some View {
        VStack(spacing: 0) {
            EventTopBar(title: String(localized: "Add photos and videos"),
                        subtitle: String(localized: "Step 1 of 2 · event gallery"), onBack: { dismiss() })
            if let model {
                if model.info == nil {
                    if let error = model.errorMessage {
                        EventStateCard(systemImage: "wifi.exclamationmark", tint: Theme.Colors.red700,
                                       tintBackground: Theme.Colors.errorBackground,
                                       title: String(localized: "Couldn’t open this event"), message: error)
                            .padding(16)
                        Spacer()
                    } else {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
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
            if model == nil {
                model = AddEventMediaViewModel(eventID: eventID, source: source, service: dependencies.eventService)
            }
            await model?.load()
        }
        .task(id: model.map { "\($0.audienceScope)|\($0.stream)|\($0.department)|\($0.semester)|\($0.division)" }) {
            await model?.refreshCounts()
        }
        .onChange(of: photoItems) { importItems(photoItems) { photoItems = [] } }
        .onChange(of: videoItems) { importItems(videoItems) { videoItems = [] } }
        .fullScreenCover(isPresented: $showsCamera) {
            EventCameraPicker { result in
                showsCamera = false
                guard let result, let model else { return }
                Task {
                    switch result {
                    case .photo(let image):
                        if let media = await MediaLoader.photo(image, index: model.nextPickIndex()) {
                            model.add([media], message: String(localized: "1 photo added from the camera."))
                        }
                    case .video(let url):
                        let media = await MediaLoader.videoMedia(at: url, name: "VID_\(model.nextPickIndex())")
                        model.add([media], message: String(localized: "1 video added from the camera."))
                    }
                }
            }
            .ignoresSafeArea()
        }
        .sheet(item: Binding(
            get: { model?.editingItemID.map(IdentifiedString.init) },
            set: { model?.editingItemID = $0?.id })) { identified in
            if let model {
                MediaItemSheet(model: model, itemID: identified.id)
            }
        }
        .fullScreenCover(isPresented: $isPreviewing) {
            if let model {
                EventGalleryScreen(model: EventGalleryViewModel(preview: model.previewGallery, localImages: model.localImages),
                                   onBack: { isPreviewing = false }) {
                    EventBottomBar {
                        EventBarButton(title: String(localized: "Edit"), systemImage: "pencil", style: .outline) {
                            isPreviewing = false
                        }
                        EventBarButton(title: model.publishTitle, systemImage: "paperplane.fill", isLoading: model.isPublishing,
                                       isEnabled: model.canPublish) {
                            Task {
                                if await model.publish() {
                                    isPreviewing = false
                                    isPublished = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isPublished) {
            if let model, let gallery = model.publishedGallery {
                GalleryPublishedView(gallery: gallery, recipientsLine: model.recipientsLine, pushSent: model.notifyPush) {
                    isPublished = false
                    closeToEvent()
                } onAddMore: {
                    isPublished = false
                    self.model = AddEventMediaViewModel(eventID: eventID, source: source, service: dependencies.eventService)
                    Task { await self.model?.load() }
                } onViewGallery: {
                    isPublished = false
                    router.pop()
                    router.push(.event(.manageGallery(eventID: eventID)))
                }
            }
        }
    }

    private func closeToEvent() {
        router.pop()
        if source != .detail && source != .gallery {
            router.push(.event(.staffDetail(id: eventID)))
        }
    }

    private func importItems(_ items: [PhotosPickerItem], reset: @escaping () -> Void) {
        guard !items.isEmpty, let model else { return }
        isImporting = true
        Task {
            var picked: [PickedMedia] = []
            var failed = 0
            for item in items {
                if let media = await MediaLoader.load(item, index: model.nextPickIndex()) {
                    picked.append(media)
                } else {
                    failed += 1
                }
            }
            model.add(picked)
            if failed > 0 {
                model.toast = EventToastMessage(
                    text: failed == 1 ? String(localized: "1 item couldn’t be read from your library.")
                                      : String(localized: "\(failed) items couldn’t be read from your library."),
                    tone: .danger)
            }
            isImporting = false
            reset()
        }
    }

    // MARK: - Form

    private func form(_ model: AddEventMediaViewModel) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                if let banner = model.blockingBanner {
                    EventToastView(toast: EventToastMessage(text: banner, tone: .danger))
                }
                if let toast = model.toast {
                    EventToastView(toast: toast)
                        .task(id: toast) {
                            try? await Task.sleep(for: .seconds(4))
                            withAnimation { model.toast = nil }
                        }
                }
                if let info = model.info { eventCard(info) }
                sourcesSection(model)
                selectedSection(model)
                albumSection(model)
                audienceSection(model)
                optionsSection(model)
                PoweredByFooter()
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 24)
            .animation(.easeOut(duration: 0.2), value: model.toast)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func eventCard(_ info: GalleryEventInfo) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconTile(systemImage: "trophy.fill", size: 48, radius: 14,
                     foreground: Theme.Colors.green700, background: Theme.Colors.green50)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top) {
                    Text(info.title).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    EventStatusPill(status: .completed)
                }
                Text("\(EventFormat.dateLine(start: info.start, end: info.end)) · \(EventFormat.timeRange(start: info.start, end: info.end, isAllDay: info.isAllDay))")
                    .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink700)
                Text(info.venue).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
        }
        .padding(14)
        .dashboardCard(radius: 16)
        .accessibilityElement(children: .combine)
    }

    private func sourcesSection(_ model: AddEventMediaViewModel) -> some View {
        EventFormCard(title: String(localized: "Choose photos and videos")) {
            HStack(spacing: 8) {
                if EventCameraPicker.isAvailable {
                    Button { showsCamera = true } label: {
                        sourceLabel("camera.fill", String(localized: "Camera"))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("Take a photo or record a video")
                }
                PhotosPicker(selection: $photoItems, maxSelectionCount: MediaRules.maxItemsPerUpload,
                             matching: .images, photoLibrary: .shared()) {
                    sourceLabel("photo.on.rectangle", String(localized: "Gallery"))
                }
                .accessibilityLabel("Choose several photos from your gallery")
                PhotosPicker(selection: $videoItems, maxSelectionCount: 20, matching: .videos, photoLibrary: .shared()) {
                    sourceLabel("video.fill", String(localized: "Video"))
                }
                .accessibilityLabel("Choose videos up to 200 MB each")
            }
            .disabled(isImporting)
            .overlay {
                if isImporting {
                    ProgressView().padding(10).background(.regularMaterial, in: .rect(cornerRadius: 10))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Photos").bold()
                    Text("JPG, PNG, HEIC · up to 10 MB each")
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Videos").bold()
                    Text("MP4, MOV · up to 200 MB each")
                }
                Text("Select many at once. Up to \(MediaRules.maxItemsPerUpload) items per upload.")
            }
            .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            if !model.rejected.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.rejected.count == 1 ? String(localized: "1 file not added")
                                                   : String(localized: "\(model.rejected.count) files not added"))
                        .font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.red800)
                    ForEach(model.rejected) { file in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Theme.Colors.error)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(file.name).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                                Text(file.reason).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.red700)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            Button { model.dismissRejected(file.id) } label: {
                                Image(systemName: "xmark").font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.Colors.ink500).frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Dismiss \(file.name)")
                        }
                    }
                }
                .padding(12)
                .background(Theme.Colors.errorBackground, in: .rect(cornerRadius: 12))
            }
        }
    }

    private func sourceLabel(_ systemImage: String, _ title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 20, weight: .semibold))
            Text(title).font(AppFont.jakarta(13, .bold))
        }
        .foregroundStyle(Theme.Colors.blue700)
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(Theme.Colors.blue50, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.blueBorderLight))
    }

    private func selectedSection(_ model: AddEventMediaViewModel) -> some View {
        @Bindable var model = model
        return EventFormCard(title: String(localized: "Selected"), trailing: model.selectedCountText, isError: model.itemsError) {
            if model.items.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled").font(.system(size: 24)).foregroundStyle(Theme.Colors.blue600)
                    Text("No photos or videos yet").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("Use Camera, Gallery or Video above. You can pick many at once.")
                        .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(20)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(model.itemsError ? Theme.Colors.error : Theme.Colors.blueBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
                if model.itemsError { EventFieldError(text: String(localized: "Add at least one photo or video.")) }
            } else {
                if model.uploadingCount > 0 {
                    let total = model.items.count
                    EventProgressRow(text: String(localized: "Uploading \(model.uploadingCount) of \(total) · \(model.uploadedCount) done"),
                                     percentText: EventFormat.percent(model.uploadedCount, of: total),
                                     fraction: Double(model.uploadedCount) / Double(max(total, 1)), tint: Theme.Colors.blue600)
                }
                EventSegmented(options: [(AddEventMediaViewModel.ViewMode.grid, String(localized: "Grid")),
                                         (AddEventMediaViewModel.ViewMode.list, String(localized: "Captions and order"))],
                               selection: $model.viewMode)
                if model.viewMode == .grid {
                    Text("Tap an item to add a caption, set the cover or move it. The first photo is the cover until you choose one.")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(model.visibleItems) { item in
                            gridCell(model, item: item)
                        }
                    }
                } else {
                    Text("Captions are optional. Use the arrows to change the order receivers see.")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    VStack(spacing: 8) {
                        ForEach(model.visibleItems) { item in
                            listRow(model, item: item)
                        }
                    }
                }
                if model.hasMore {
                    Button { model.showsAll = true } label: {
                        Text("Show all \(model.items.count) items").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.blue600)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func gridCell(_ model: AddEventMediaViewModel, item: AddEventMediaViewModel.DraftItem) -> some View {
        let number = (model.index(of: item.id) ?? 0) + 1
        return Button { model.editingItemID = item.id } label: {
            GalleryTileView(item: item.asGalleryItem, localImage: item.media.thumbnail, isCover: item.id == model.effectiveCoverID)
                .overlay { uploadOverlay(model, item: item) }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button { model.remove(item.id) } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .heavy)).foregroundStyle(.white)
                    .frame(width: 24, height: 24).background(.black.opacity(0.6), in: Circle())
                    .frame(width: 40, height: 40).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(item.kind.title.lowercased()) \(number)")
        }
        .accessibilityLabel("\(item.kind.title) \(number)\(item.caption.isEmpty ? "" : ": \(item.caption)"). Edit")
    }

    @ViewBuilder
    private func uploadOverlay(_ model: AddEventMediaViewModel, item: AddEventMediaViewModel.DraftItem) -> some View {
        switch item.state {
        case .uploading(let progress):
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.35)
                VStack(spacing: 4) {
                    Text(EventFormat.percent(Int(progress * 100), of: 100)).font(AppFont.jakarta(12, .heavy)).foregroundStyle(.white)
                    ProgressView(value: progress).tint(.white).padding(.horizontal, 8)
                }
                .padding(.bottom, 8)
            }
            .clipShape(.rect(cornerRadius: 10))
            .accessibilityLabel("Uploading")
        case .failed:
            ZStack {
                Theme.Colors.red800.opacity(0.75)
                VStack(spacing: 4) {
                    Text("Upload failed").font(AppFont.jakarta(11, .heavy)).foregroundStyle(.white)
                    Button { model.retry(item.id) } label: {
                        Label("Retry", systemImage: "arrow.clockwise").font(AppFont.jakarta(11, .bold))
                            .foregroundStyle(Theme.Colors.red800)
                            .padding(.horizontal, 8).frame(height: 28)
                            .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(.rect(cornerRadius: 10))
        case .uploaded:
            EmptyView()
        }
    }

    private func listRow(_ model: AddEventMediaViewModel, item: AddEventMediaViewModel.DraftItem) -> some View {
        let index = model.index(of: item.id) ?? 0
        let number = index + 1
        return HStack(spacing: 10) {
            Button { model.editingItemID = item.id } label: {
                GalleryTileView(item: item.asGalleryItem, localImage: item.media.thumbnail,
                                isCover: item.id == model.effectiveCoverID, symbolSize: 16)
                    .frame(width: 64)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(item.kind.title) \(number)").font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
                TextField(String(localized: "Add a caption (optional)"), text: Binding(
                    get: { item.caption }, set: { model.setCaption($0, for: item.id) }))
                    .font(AppFont.jakarta(14))
                    .padding(.horizontal, 10).frame(height: 40)
                    .background(Theme.Colors.white, in: .rect(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.Colors.border))
                    .accessibilityLabel("Caption for \(item.kind.title.lowercased()) \(number)")
            }
            VStack(spacing: 4) {
                arrowButton("chevron.up", enabled: index > 0, label: "Move \(item.kind.title.lowercased()) \(number) earlier") {
                    model.move(item.id, by: -1)
                }
                arrowButton("chevron.down", enabled: index < model.items.count - 1,
                            label: "Move \(item.kind.title.lowercased()) \(number) later") {
                    model.move(item.id, by: 1)
                }
            }
        }
        .padding(8)
        .dashboardCard(radius: 12)
    }

    private func albumSection(_ model: AddEventMediaViewModel) -> some View {
        @Bindable var model = model
        return EventFormCard {
            EventFieldLabel(text: String(localized: "Album title"), hint: String(localized: "(optional)"))
            TextField(model.info.map { String(localized: "e.g. \($0.title) – highlights") } ?? "", text: $model.albumTitle)
                .font(AppFont.jakarta(15, .semibold))
                .padding(.horizontal, 14).frame(height: 48)
                .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
            Text("If empty, receivers see the event name.").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
        }
    }

    private func audienceSection(_ model: AddEventMediaViewModel) -> some View {
        @Bindable var model = model
        return EventFormCard(title: String(localized: "Visible to"),
                             trailing: String(localized: "\(EventFormat.count(model.recipients)) people"),
                             isError: model.rolesError) {
            EventSegmented(options: [(AddEventMediaViewModel.AudienceScope.everyone, String(localized: "Everyone invited")),
                                     (AddEventMediaViewModel.AudienceScope.groups, String(localized: "Choose groups"))],
                           selection: $model.audienceScope)
            if model.audienceScope == .groups, let options = model.options {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    dropdown(String(localized: "Stream"), value: model.stream, options: options.streams, title: { $0 }) { model.stream = $0 }
                    dropdown(String(localized: "Department"), value: model.department, options: options.departments,
                             title: { $0 == "all" ? String(localized: "All departments") : $0 }) { model.department = $0 }
                    dropdown(String(localized: "Year / Semester"), value: model.semester, options: options.semesters,
                             title: Self.semesterTitle) { model.semester = $0 }
                    dropdown(String(localized: "Division"), value: model.division, options: options.divisions,
                             title: { $0 == "all" ? String(localized: "All divisions") : String(localized: "Division \($0)") }) { model.division = $0 }
                }
                EventFieldLabel(text: String(localized: "Roles"))
                HStack(spacing: 8) {
                    ForEach(EventAudienceRole.allCases) { role in
                        EventChoiceChip(title: role.title, isOn: model.roles.contains(role), showsCheck: true) {
                            model.toggleRole(role)
                        }
                    }
                }
            }
            Text(model.recipientsLine).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
                .fixedSize(horizontal: false, vertical: true)
            if model.rolesError {
                EventFieldError(text: String(localized: "Choose at least one: Students, Parents or Staff."))
            }
        }
    }

    private static func semesterTitle(_ value: String) -> String {
        guard let sem = Int(value) else { return String(localized: "All semesters") }
        return String(localized: "Year \((sem + 1) / 2) · Sem \(sem)")
    }

    private func dropdown(_ label: String, value: String, options: [String], title: @escaping (String) -> String,
                          onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            EventFieldLabel(text: label)
            FormDropdown(value: title(value), options: options.map(title)) { picked in
                if let raw = options.first(where: { title($0) == picked }) { onSelect(raw) }
            }
        }
    }

    private func optionsSection(_ model: AddEventMediaViewModel) -> some View {
        @Bindable var model = model
        return EventFormCard(title: String(localized: "Options")) {
            EventToggleRow(title: String(localized: "Allow download"),
                           subtitle: String(localized: "Receivers can save photos and videos to their phone. Turn off for view only."),
                           isOn: $model.allowDownload)
            EventFieldLabel(text: String(localized: "When to publish"))
            EventSegmented(options: [(false, String(localized: "Publish now")), (true, String(localized: "Schedule"))],
                           selection: $model.publishLater)
            if model.publishLater {
                DatePicker(String(localized: "Date and time"), selection: $model.publishAt, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    .font(AppFont.jakarta(14, .bold))
                    .tint(Theme.Colors.blue600)
            }
            EventToggleRow(title: String(localized: "Notify by push"), subtitle: model.pushDescription, isOn: $model.notifyPush)
        }
    }

    // MARK: - Bottom bar

    private func bottomBar(_ model: AddEventMediaViewModel) -> some View {
        EventBottomBar {
            EventBarButton(title: String(localized: "Save draft"), style: .outline) {
                Task { await model.saveDraft() }
            }
            EventBarButton(title: String(localized: "Preview"), systemImage: "eye", style: .outline, isEnabled: !model.items.isEmpty) {
                isPreviewing = true
            }
            EventBarButton(title: model.publishTitle, systemImage: "paperplane.fill", isLoading: model.isPublishing) {
                Task { if await model.publish() { isPublished = true } }
            }
        }
    }
}

// MARK: - Helpers

/// `String` wrapper so an optional id can drive `.sheet(item:)`.
struct IdentifiedString: Identifiable {
    let id: String
}

/// Up / down reorder button (44 pt target).
func arrowButton(_ systemImage: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: systemImage).font(.system(size: 13, weight: .bold))
            .foregroundStyle(enabled ? Theme.Colors.blue700 : Theme.Colors.ink300)
            .frame(width: 36, height: 30)
            .background(Theme.Colors.blue50.opacity(enabled ? 1 : 0.5), in: .rect(cornerRadius: 8))
            .frame(minWidth: 44, minHeight: 34)
            .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
    .accessibilityLabel(label)
}

// MARK: - Item sheet

/// Caption, cover, move and remove for one selected item.
private struct MediaItemSheet: View {
    @Bindable var model: AddEventMediaViewModel
    let itemID: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let index = model.index(of: itemID) {
            let item = model.items[index]
            let isCover = item.id == model.effectiveCoverID
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    GalleryTileView(item: item.asGalleryItem, localImage: item.media.thumbnail, isCover: isCover, symbolSize: 18)
                        .frame(width: 72)
                    EventSheetHeader(title: "\(item.kind.title) \(index + 1) of \(model.items.count)",
                                     subtitle: subtitle(item)) { dismiss() }
                }
                VStack(alignment: .leading, spacing: 6) {
                    EventFieldLabel(text: String(localized: "Caption"), hint: String(localized: "(optional · also read out by screen readers)"))
                    TextField(String(localized: "e.g. Tug of war final – Sem 5 A vs Sem 5 B"), text: Binding(
                        get: { model.items.first { $0.id == itemID }?.caption ?? "" },
                        set: { model.setCaption($0, for: itemID) }), axis: .vertical)
                        .font(AppFont.jakarta(14)).lineLimit(2...4)
                        .padding(12)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
                }
                if item.kind == .video {
                    Text("Only a photo can be the cover.").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                } else if isCover {
                    Label("This is the cover photo", systemImage: "star.fill")
                        .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.green700)
                } else {
                    EventBarButton(title: String(localized: "Set as cover photo"), systemImage: "star", style: .outline) {
                        model.setCover(itemID)
                    }
                }
                HStack(spacing: 10) {
                    EventBarButton(title: String(localized: "Move earlier"), systemImage: "arrow.left", style: .outline,
                                   isEnabled: index > 0) { model.move(itemID, by: -1) }
                    EventBarButton(title: String(localized: "Move later"), systemImage: "arrow.right", style: .outline,
                                   isEnabled: index < model.items.count - 1) { model.move(itemID, by: 1) }
                }
                HStack(spacing: 10) {
                    EventBarButton(title: String(localized: "Remove"), systemImage: "trash", style: .destructive) {
                        model.remove(itemID)
                        dismiss()
                    }
                    EventBarButton(title: String(localized: "Done")) { dismiss() }
                }
            }
            .padding(20)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Theme.Radius.sheet)
        }
    }

    private func subtitle(_ item: AddEventMediaViewModel.DraftItem) -> String {
        if case .uploading = item.state { return String(localized: "Uploading…") }
        if item.state == .failed { return String(localized: "Upload failed") }
        return item.kind == .video ? String(localized: "Video · \(item.media.duration ?? "")") : String(localized: "Photo")
    }
}
