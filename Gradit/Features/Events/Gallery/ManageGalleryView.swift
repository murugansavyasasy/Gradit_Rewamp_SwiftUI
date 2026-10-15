//
//  ManageGalleryView.swift
//  Gradit
//
//  Organiser's gallery after publishing: summary and views, change cover, add more,
//  edit / reorder / select and delete items, unpublish or delete the gallery.
//  Design: 12 Events › Manage gallery (+ Edit item, Change cover, Reorder, Select,
//  Delete selected, Unpublish, Unpublished, Delete gallery, Empty).
//

import SwiftUI

struct ManageGalleryView: View {
    let eventID: String

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var model: ManageGalleryViewModel?

    var body: some View {
        VStack(spacing: 0) {
            EventTopBar(title: String(localized: "Manage gallery"), subtitle: model?.gallery?.eventTitle, onBack: { dismiss() })
            if let model {
                if let gallery = model.gallery {
                    content(model, gallery: gallery)
                    if model.mode == .select { selectBar(model) }
                } else if let error = model.errorMessage {
                    EventStateCard(systemImage: "photo.on.rectangle", title: String(localized: "Couldn’t load the gallery"),
                                   message: error, actionTitle: String(localized: "Try again"), actionImage: "arrow.clockwise") {
                        Task { await model.load() }
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
        .sheet(item: Binding(
            get: { model?.editingItemID.map(IdentifiedString.init) },
            set: { model?.editingItemID = $0?.id })) { identified in
            if let model {
                ManageItemSheet(model: model, itemID: identified.id)
            }
        }
        .sheet(isPresented: Binding(get: { model?.showsCoverPicker ?? false }, set: { model?.showsCoverPicker = $0 })) {
            if let model { CoverPickerSheet(model: model) }
        }
        .task {
            if model == nil { model = ManageGalleryViewModel(eventID: eventID, service: dependencies.eventService) }
            await model?.load()
        }
    }

    // MARK: - Content

    private func content(_ model: ManageGalleryViewModel, gallery: EventGallery) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                if let toast = model.toast {
                    EventToastView(toast: toast)
                        .task(id: toast) {
                            try? await Task.sleep(for: .seconds(4))
                            withAnimation { model.toast = nil }
                        }
                }
                summary(model, gallery: gallery)
                if gallery.items.isEmpty {
                    EventStateCard(systemImage: "photo.on.rectangle.angled", title: String(localized: "No photos or videos yet"),
                                   message: String(localized: "Receivers see “No photos or videos yet” until you add some."),
                                   actionTitle: String(localized: "Add photos and videos"), actionImage: "plus") {
                        router.push(.event(.addMedia(eventID: eventID, source: .gallery)))
                    }
                } else {
                    itemsSection(model, gallery: gallery)
                }
                if model.mode == .view { settings(model, gallery: gallery) }
                PoweredByFooter()
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 24)
            .animation(.easeOut(duration: 0.2), value: model.toast)
        }
        .scrollIndicators(.hidden)
        .refreshable { await model.load() }
    }

    private func summary(_ model: ManageGalleryViewModel, gallery: EventGallery) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let cover = gallery.cover {
                GalleryCoverBanner(tint: cover.tint, symbol: cover.symbol, caption: cover.caption, imageURL: cover.thumbnailURL)
            }
            HStack(alignment: .top) {
                Text(gallery.displayTitle).font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                EventStatusPill(text: gallery.isPublished ? String(localized: "Published") : String(localized: "Unpublished"),
                                foreground: gallery.isPublished ? Theme.Colors.green700 : Theme.Colors.ink700,
                                background: gallery.isPublished ? Theme.Colors.green50 : Theme.Colors.chipGrey)
            }
            Label(gallery.items.isEmpty ? String(localized: "No items") : EventFormat.mediaCount(photos: gallery.photoCount, videos: gallery.videoCount),
                  systemImage: "photo.on.rectangle")
                .font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
            Text(publishLine(gallery)).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            Text(gallery.audienceText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            if gallery.isPublished {
                EventProgressRow(text: String(localized: "\(EventFormat.count(gallery.views)) / \(EventFormat.count(gallery.audienceCount)) viewed"),
                                 percentText: EventFormat.percent(gallery.views, of: gallery.audienceCount),
                                 fraction: gallery.audienceCount > 0 ? Double(gallery.views) / Double(gallery.audienceCount) : 0,
                                 tint: Theme.Colors.blue600)
            }
            HStack(spacing: 10) {
                EventBarButton(title: String(localized: "Change cover"), systemImage: "star", style: .outline,
                               isEnabled: gallery.photoCount > 0) {
                    model.pendingCoverID = model.coverID
                    model.showsCoverPicker = true
                }
                EventBarButton(title: String(localized: "Add more"), systemImage: "plus") {
                    router.push(.event(.addMedia(eventID: eventID, source: .gallery)))
                }
            }
        }
        .padding(14)
        .dashboardCard(radius: 16)
    }

    private func publishLine(_ gallery: EventGallery) -> String {
        guard gallery.isPublished else { return String(localized: "Hidden from receivers. Only you can see it.") }
        let when = gallery.publishedAt.map { EventFormat.stamp($0) } ?? ""
        let download = gallery.allowDownload ? String(localized: "Download allowed") : String(localized: "Download not allowed")
        return String(localized: "Published \(when) · \(download) · Push sent")
    }

    private func itemsSection(_ model: ManageGalleryViewModel, gallery: EventGallery) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos and videos").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                switch model.mode {
                case .view:
                    smallButton(String(localized: "Reorder"), systemImage: "arrow.up.arrow.down") { model.mode = .reorder }
                    smallButton(String(localized: "Select"), systemImage: "checkmark.circle") { model.startSelecting() }
                case .reorder:
                    smallButton(String(localized: "Done"), systemImage: nil, filled: true) { Task { await model.finishReorder() } }
                case .select:
                    EmptyView()
                }
            }
            if model.mode != .reorder {
                EventCountTabs(tabs: EventGalleryViewModel.Tab.allCases.map { EventCountTab(id: $0, title: $0.title, count: model.count($0)) },
                               selection: $model.tab)
            }
            switch model.mode {
            case .view:
                Text("Tap an item to edit its caption, make it the cover, move it or delete it.")
                    .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            case .select:
                Text(model.selection.isEmpty ? String(localized: "Tap items to select them. Nothing selected yet.")
                                             : String(localized: "Tap items to select them. \(model.selection.count) selected."))
                    .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.blue700)
            case .reorder:
                Text("Use the arrows to change the order receivers see. Captions can be edited here too.")
                    .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }

            if model.mode == .reorder {
                VStack(spacing: 8) {
                    ForEach(model.visible) { item in reorderRow(model, item: item) }
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                    ForEach(model.visible) { item in gridCell(model, item: item) }
                }
            }
            if model.hasMore {
                Button { model.showsAll = true } label: {
                    Text("Show all \(model.filtered.count) items").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.blue600)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .dashboardCard(radius: 16)
    }

    private func smallButton(_ title: String, systemImage: String?, filled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage { Image(systemName: systemImage).font(.system(size: 12, weight: .bold)) }
                Text(title)
            }
            .font(AppFont.jakarta(13, .bold))
            .foregroundStyle(filled ? Theme.Colors.white : Theme.Colors.blue700)
            .padding(.horizontal, 12).frame(height: 36)
            .background(filled ? Theme.Colors.blue600 : Theme.Colors.blue50, in: Capsule())
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func gridCell(_ model: ManageGalleryViewModel, item: GalleryItem) -> some View {
        let isSelected = model.selection.contains(item.id)
        let prefix = model.mode == .select
            ? (isSelected ? String(localized: "Selected. ") : String(localized: "Not selected. "))
            : ""
        return Button {
            if model.mode == .select { model.toggleSelection(item.id) } else { model.editingItemID = item.id }
        } label: {
            GalleryTileView(item: item, isCover: item.id == model.coverID, cornerRadius: 8, symbolSize: 20)
                .overlay {
                    if model.mode == .select {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? Theme.Colors.blue600 : .clear, lineWidth: 3)
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(isSelected ? Theme.Colors.blue600 : .white)
                                    .background(isSelected ? Circle().fill(.white) : Circle().fill(.black.opacity(0.3)))
                                    .padding(6)
                            }
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(prefix + item.accessibilityText))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func reorderRow(_ model: ManageGalleryViewModel, item: GalleryItem) -> some View {
        let index = model.index(of: item.id) ?? 0
        let number = index + 1
        return HStack(spacing: 10) {
            Button { model.editingItemID = item.id } label: {
                GalleryTileView(item: item, isCover: item.id == model.coverID, symbolSize: 16).frame(width: 64)
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

    private func settings(_ model: ManageGalleryViewModel, gallery: EventGallery) -> some View {
        VStack(spacing: 10) {
            if gallery.isPublished {
                EventBarButton(title: String(localized: "Unpublish gallery"), systemImage: "eye.slash", style: .outline) {
                    model.dialog = .unpublish
                }
            } else {
                EventBarButton(title: String(localized: "Publish again"), systemImage: "eye", isLoading: model.isWorking) {
                    Task { await model.setPublished(true) }
                }
            }
            Button { model.dialog = .deleteGallery } label: {
                Label("Delete gallery", systemImage: "trash")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.destructive)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.Colors.errorBackground, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private func selectBar(_ model: ManageGalleryViewModel) -> some View {
        EventBottomBar {
            EventBarButton(title: String(localized: "Cancel"), style: .outline) { model.cancelSelecting() }
            if model.selection.isEmpty {
                EventBarButton(title: String(localized: "Select items"), isEnabled: false) {}
            } else {
                EventBarButton(title: String(localized: "Delete \(model.selectionText)"), systemImage: "trash", style: .destructive) {
                    model.dialog = .deleteItems
                }
            }
        }
    }

    // MARK: - Dialogs

    @ViewBuilder
    private var dialogs: some View {
        if let model, let gallery = model.gallery {
            let media = EventFormat.mediaCount(photos: gallery.photoCount, videos: gallery.videoCount)
            switch model.dialog {
            case .deleteItems:
                EventAlertCard(systemImage: "trash", title: String(localized: "Delete \(model.selectionText)?"),
                               message: String(localized: "They’ll be removed from the gallery for all \(EventFormat.count(gallery.audienceCount)) people. Copies people already saved to their phones aren’t affected. You can’t undo this."),
                               confirmTitle: String(localized: "Delete"), isWorking: model.isWorking,
                               onConfirm: { Task { await model.deleteSelected() } },
                               onCancel: { model.dialog = nil })
            case .unpublish:
                EventAlertCard(systemImage: "eye.slash", iconTint: Theme.Colors.amber800, iconBackground: Theme.Colors.warningBackground,
                               title: String(localized: "Unpublish this gallery?"),
                               message: String(localized: "Receivers will see “Gallery no longer available”. Your \(media) stay here, and you can publish again any time."),
                               confirmTitle: String(localized: "Unpublish"), confirmColor: Theme.Colors.blue600, isWorking: model.isWorking,
                               onConfirm: { Task { await model.setPublished(false) } },
                               onCancel: { model.dialog = nil })
            case .deleteGallery:
                EventAlertCard(systemImage: "trash", title: String(localized: "Delete the whole gallery?"),
                               message: String(localized: "All \(media), captions and view counts will be deleted. Receivers will see “Gallery no longer available”. You can’t undo this."),
                               confirmTitle: String(localized: "Delete gallery"), isWorking: model.isWorking,
                               onConfirm: { Task { if await model.deleteGallery() { dismiss() } } },
                               onCancel: { model.dialog = nil })
            case nil:
                EmptyView()
            }
        }
    }
}

// MARK: - Item sheet

private struct ManageItemSheet: View {
    @Bindable var model: ManageGalleryViewModel
    let itemID: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let index = model.index(of: itemID) {
            let item = model.items[index]
            let isCover = item.id == model.coverID
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    GalleryTileView(item: item, isCover: isCover, symbolSize: 18).frame(width: 72)
                    EventSheetHeader(title: "\(item.kind.title) \(index + 1) of \(model.items.count)",
                                     subtitle: item.kind == .video ? String(localized: "Video · \(item.duration ?? "")") : String(localized: "Photo")) {
                        dismiss()
                    }
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
                        Task { await model.setCover(itemID) }
                    }
                }
                HStack(spacing: 10) {
                    EventBarButton(title: String(localized: "Move earlier"), systemImage: "arrow.left", style: .outline,
                                   isEnabled: index > 0) { model.move(itemID, by: -1) }
                    EventBarButton(title: String(localized: "Move later"), systemImage: "arrow.right", style: .outline,
                                   isEnabled: index < model.items.count - 1) { model.move(itemID, by: 1) }
                }
                HStack(spacing: 10) {
                    EventBarButton(title: String(localized: "Delete"), systemImage: "trash", style: .destructive,
                                   isLoading: model.isWorking) {
                        Task { await model.deleteItem(itemID) }
                    }
                    EventBarButton(title: String(localized: "Done")) { dismiss() }
                }
            }
            .padding(20)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Theme.Radius.sheet)
            .onDisappear { Task { await model.commitCaptions() } }
        }
    }
}

// MARK: - Cover picker

private struct CoverPickerSheet: View {
    @Bindable var model: ManageGalleryViewModel
    @Environment(\.dismiss) private var dismiss

    private var photos: [GalleryItem] {
        let all = model.items.filter { $0.kind == .photo }
        let current = all.filter { $0.id == model.coverID }
        return current + all.filter { $0.id != model.coverID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            EventSheetHeader(title: String(localized: "Choose a cover photo"),
                             subtitle: String(localized: "Shown on event cards and at the top of the gallery. Photos only.")) { dismiss() }
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(photos) { item in
                        let isOn = item.id == (model.pendingCoverID ?? model.coverID)
                        Button { model.pendingCoverID = item.id } label: {
                            GalleryTileView(item: item, symbolSize: 16)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10).strokeBorder(isOn ? Theme.Colors.blue600 : .clear, lineWidth: 3)
                                }
                                .overlay(alignment: .topTrailing) {
                                    if isOn {
                                        Image(systemName: "checkmark.circle.fill").font(.system(size: 18))
                                            .foregroundStyle(Theme.Colors.blue600).background(Circle().fill(.white)).padding(4)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isOn ? [.isSelected] : [])
                    }
                }
            }
            EventBarButton(title: String(localized: "Use as cover")) {
                if let id = model.pendingCoverID ?? model.coverID {
                    Task { await model.setCover(id) }
                }
                dismiss()
            }
        }
        .padding(20)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Radius.sheet)
    }
}
