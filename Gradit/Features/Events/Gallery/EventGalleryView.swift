//
//  EventGalleryView.swift
//  Gradit
//
//  Receivers' gallery grid and the full-screen viewer (photo zoom, video playback,
//  share and save to the phone's Photos app). Also used as the organiser's preview.
//  Design: 12 Events › Students & Parents › Gallery, Viewer, Storage permission,
//  Saving, Saved, Download failed, Share, Loading, Offline, Empty, No longer available.
//

import SwiftUI
import AVKit

/// Pushed receiver gallery for an event.
struct EventGalleryView: View {
    let eventID: String

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: EventGalleryViewModel?

    var body: some View {
        Group {
            if let model {
                EventGalleryScreen(model: model, onBack: { dismiss() }) { EmptyView() }
            } else {
                Theme.Colors.surfaceMuted.ignoresSafeArea()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .keepsSwipeBack()
        .task {
            if model == nil { model = EventGalleryViewModel(eventID: eventID, service: dependencies.eventService) }
            await model?.load()
        }
    }
}

struct EventGalleryScreen<Footer: View>: View {
    @Bindable var model: EventGalleryViewModel
    let onBack: () -> Void
    @ViewBuilder var footer: () -> Footer

    @State private var viewerIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            EventTopBar(title: String(localized: "Gallery"), subtitle: model.gallery?.eventTitle, onBack: onBack)
            if model.isPreview, let gallery = model.gallery {
                Label(String(localized: "Receiver preview — this is exactly what \(EventFormat.count(gallery.audienceCount)) people will see."),
                      systemImage: "eye")
                    .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.blue700)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Theme.Colors.blue50)
            }
            if model.state == .offline {
                Label("You’re offline. Connect to the internet to view the gallery.", systemImage: "wifi.slash")
                    .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Theme.Colors.chipGrey)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content
                    Label("Photos and videos open online only. GradIt doesn’t keep any copy on your phone, so the gallery needs the internet.",
                          systemImage: "icloud")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        .fixedSize(horizontal: false, vertical: true)
                    PoweredByFooter()
                }
                .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { await model.load() }
            footer()
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .fullScreenCover(item: Binding(
            get: { viewerIndex.map { IdentifiedString(id: String($0)) } },
            set: { viewerIndex = $0.flatMap { Int($0.id) } })) { start in
            if let gallery = model.gallery {
                GalleryViewerView(gallery: gallery, startIndex: Int(start.id) ?? 0, localImages: model.localImages)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(0..<12, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10).fill(Theme.Colors.chipGrey).aspectRatio(1, contentMode: .fit)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading gallery")
            Text("Loading photos and videos…").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                .frame(maxWidth: .infinity)
        case .loaded:
            if let gallery = model.gallery {
                album(gallery)
                EventCountTabs(tabs: EventGalleryViewModel.Tab.allCases.map { EventCountTab(id: $0, title: $0.title, count: model.count($0)) },
                               selection: $model.tab)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                    ForEach(model.visibleItems) { item in
                        Button {
                            viewerIndex = gallery.items.firstIndex { $0.id == item.id }
                        } label: {
                            GalleryTileView(item: item, localImage: model.localImages[item.id], isCover: item.id == gallery.cover?.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        case .empty:
            EventStateCard(systemImage: "photo.on.rectangle",
                           title: String(localized: "No photos or videos yet"),
                           message: String(localized: "The organiser hasn’t added photos from \(model.gallery?.eventTitle ?? String(localized: "this event")) yet. You’ll get a notification when they do."),
                           actionTitle: model.isPreview ? nil : String(localized: "Back to event"), action: onBack)
        case .offline:
            EventStateCard(systemImage: "wifi.slash", tint: Theme.Colors.ink700, tintBackground: Theme.Colors.chipGrey,
                           title: String(localized: "Connect to the internet to view the gallery"),
                           message: String(localized: "Photos and videos are shown online only. Thumbnails aren’t stored, so nothing can be shown while you’re offline."),
                           actionTitle: String(localized: "Retry"), actionImage: "arrow.clockwise") { model.retry() }
        case .unavailable:
            EventStateCard(systemImage: "nosign", tint: Theme.Colors.red700, tintBackground: Theme.Colors.errorBackground,
                           title: String(localized: "Gallery no longer available"),
                           message: String(localized: "The organiser removed this gallery. Photos you downloaded earlier are still in your phone’s Gallery."),
                           actionTitle: String(localized: "Back to event"), action: onBack)
        case .failed(let message):
            EventStateCard(systemImage: "exclamationmark.triangle", tint: Theme.Colors.red700, tintBackground: Theme.Colors.errorBackground,
                           title: String(localized: "Couldn’t load the gallery"), message: message,
                           actionTitle: String(localized: "Retry"), actionImage: "arrow.clockwise") { model.retry() }
        }
    }

    private func sharedLine(_ gallery: EventGallery) -> String {
        guard let published = gallery.publishedAt else { return String(localized: "Shared by \(gallery.sharedBy)") }
        return String(localized: "Shared by \(gallery.sharedBy) · \(EventFormat.stamp(published))")
    }

    private func album(_ gallery: EventGallery) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(gallery.displayTitle).font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .accessibilityAddTraits(.isHeader)
            Label("\(EventFormat.fullDay(gallery.start)) · \(gallery.venue)", systemImage: "calendar")
            Label(EventFormat.mediaCount(photos: gallery.photoCount, videos: gallery.videoCount), systemImage: "photo.on.rectangle")
            Text(sharedLine(gallery))
            EventStatusPill(text: gallery.allowDownload ? String(localized: "Download allowed") : String(localized: "Download not allowed"),
                            systemImage: gallery.allowDownload ? "arrow.down.to.line" : "lock",
                            foreground: gallery.allowDownload ? Theme.Colors.green700 : Theme.Colors.ink700,
                            background: gallery.allowDownload ? Theme.Colors.green50 : Theme.Colors.chipGrey)
        }
        .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .dashboardCard(radius: 16)
    }
}

// MARK: - Viewer

/// Full-screen, swipeable photo / video viewer.
struct GalleryViewerView: View {
    let gallery: EventGallery
    var localImages: [String: UIImage] = [:]

    enum SaveState: Equatable {
        case idle, saving, saved
        case failed(String)
    }

    @Environment(\.dismiss) private var dismiss
    @State private var index: Int
    @State private var zoom: CGFloat = 1
    @State private var pinchBase: CGFloat = 1
    @State private var saveState: SaveState = .idle
    @State private var showsPermission = false

    init(gallery: EventGallery, startIndex: Int, localImages: [String: UIImage] = [:]) {
        self.gallery = gallery
        self.localImages = localImages
        _index = State(initialValue: min(max(startIndex, 0), max(gallery.items.count - 1, 0)))
    }

    private var item: GalleryItem? { gallery.items.indices.contains(index) ? gallery.items[index] : nil }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let item {
                VStack(spacing: 0) {
                    header(item)
                    pager
                    bottom(item)
                }
            }
            if showsPermission, let item {
                permissionDialog(item)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: index) {
            zoom = 1
            pinchBase = 1
            saveState = .idle
        }
        .accessibilityAction(.escape) { dismiss() }
    }

    private func header(_ item: GalleryItem) -> some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 44, height: 44).background(.white.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close viewer, back to gallery")
            VStack(alignment: .leading, spacing: 1) {
                Text("\(index + 1) of \(gallery.items.count)").font(AppFont.jakarta(15, .heavy)).foregroundStyle(.white)
                Text(gallery.displayTitle).font(AppFont.jakarta(12)).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            if gallery.allowDownload {
                Button { download(item) } label: {
                    Image(systemName: "arrow.down.to.line").font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 44, height: 44).background(.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Download \(item.kind.title.lowercased()) to your phone")
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private var pager: some View {
        TabView(selection: $index) {
            ForEach(Array(gallery.items.enumerated()), id: \.element.id) { offset, item in
                page(item)
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .leading) { navButton("chevron.left", label: "Previous item") { step(-1) } }
        .overlay(alignment: .trailing) { navButton("chevron.right", label: "Next item") { step(1) } }
    }

    @ViewBuilder
    private func page(_ item: GalleryItem) -> some View {
        if item.kind == .video {
            GalleryVideoPage(item: item)
        } else {
            photo(item)
                .scaleEffect(zoom)
                .gesture(MagnifyGesture()
                    .onChanged { zoom = min(max(pinchBase * $0.magnification, 1), 3) }
                    .onEnded { _ in pinchBase = zoom })
                .onTapGesture(count: 2) {
                    withAnimation { zoom = zoom > 1 ? 1 : 2 }
                    pinchBase = zoom
                }
                .accessibilityLabel(Text(item.accessibilityText))
        }
    }

    @ViewBuilder
    private func photo(_ item: GalleryItem) -> some View {
        if let image = localImages[item.id] {
            Image(uiImage: image).resizable().scaledToFit()
        } else if let url = item.mediaURL ?? item.thumbnailURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else if phase.error != nil {
                    GalleryTileView(item: item, cornerRadius: 0, symbolSize: 80).padding(16)
                } else {
                    VStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("Loading photo…").font(AppFont.jakarta(13, .semibold)).foregroundStyle(.white)
                        Text("Streaming from the college server").font(AppFont.jakarta(12)).foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        } else {
            GalleryTileView(item: item, cornerRadius: 0, symbolSize: 80).padding(16)
        }
    }

    private func navButton(_ systemImage: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                .frame(width: 40, height: 40).background(.black.opacity(0.4), in: Circle())
                .frame(width: 52, height: 52).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
        .accessibilityLabel(label)
        .opacity(zoom > 1 ? 0 : 1)
    }

    private func step(_ delta: Int) {
        guard !gallery.items.isEmpty else { return }
        withAnimation { index = (index + delta + gallery.items.count) % gallery.items.count }
    }

    private func bottom(_ item: GalleryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if item.kind == .photo {
                HStack {
                    Button { setZoom(zoom - 0.5) } label: { Image(systemName: "minus.magnifyingglass").frame(width: 44, height: 44) }
                        .accessibilityLabel("Zoom out")
                    Spacer()
                    Text("\(Int(zoom * 100))% · pinch to zoom · swipe for next")
                        .font(AppFont.jakarta(12, .semibold)).foregroundStyle(.white.opacity(0.75))
                    Spacer()
                    Button { setZoom(zoom + 0.5) } label: { Image(systemName: "plus.magnifyingglass").frame(width: 44, height: 44) }
                        .accessibilityLabel("Zoom in")
                }
                .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                .buttonStyle(.plain)
            }
            if !item.caption.isEmpty {
                Text(item.caption).font(AppFont.jakarta(15, .semibold)).foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            switch saveState {
            case .saving:
                HStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("Saving to your phone’s Gallery…").font(AppFont.jakarta(13, .semibold)).foregroundStyle(.white)
                }
            case .saved:
                Label {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Saved to Gallery").font(AppFont.jakarta(14, .heavy))
                        Text("Find it in your phone’s Photos app. GradIt keeps no copy.").font(AppFont.jakarta(12))
                    }
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .foregroundStyle(Theme.Colors.green100)
                .task {
                    try? await Task.sleep(for: .seconds(3))
                    if saveState == .saved { saveState = .idle }
                }
            case .failed(let message):
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.Colors.errorBackground)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Download failed").font(AppFont.jakarta(14, .heavy))
                        Text(message).font(AppFont.jakarta(12))
                    }
                    Spacer()
                    Button { save(item) } label: {
                        Label("Retry", systemImage: "arrow.clockwise").font(AppFont.jakarta(13, .bold))
                            .padding(.horizontal, 12).frame(height: 36)
                            .background(.white.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.white)
            case .idle:
                EmptyView()
            }
            HStack(spacing: 10) {
                ShareLink(item: EventShareLinks.galleryItem(eventID: gallery.eventID, item: item),
                          subject: Text(gallery.displayTitle), message: Text(item.caption)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(.white.opacity(0.12), in: .rect(cornerRadius: 14))
                }
                if gallery.allowDownload {
                    Button { download(item) } label: {
                        Label("Download", systemImage: "arrow.down.to.line")
                            .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink900)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(.white, in: .rect(cornerRadius: 14))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(saveState == .saving)
                } else {
                    Label("Download not allowed", systemImage: "lock")
                        .font(AppFont.jakarta(13, .semibold)).foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    private func setZoom(_ value: CGFloat) {
        withAnimation { zoom = min(max(value, 1), 3) }
        pinchBase = zoom
    }

    // MARK: Save to Photos

    private func download(_ item: GalleryItem) {
        if PhotoLibrarySaver.needsPermissionPrompt {
            showsPermission = true
        } else {
            save(item)
        }
    }

    private func save(_ item: GalleryItem) {
        saveState = .saving
        let fallback = item.mediaURL == nil ? (localImages[item.id] ?? item.renderedPlaceholder()) : nil
        Task {
            do {
                try await PhotoLibrarySaver.save(mediaURL: item.mediaURL, kind: item.kind, fallbackImage: fallback)
                saveState = .saved
            } catch {
                saveState = .failed(error.localizedDescription)
            }
        }
    }

    private func permissionDialog(_ item: GalleryItem) -> some View {
        EventAlertCard(systemImage: "photo.badge.arrow.down", iconTint: Theme.Colors.blue600, iconBackground: Theme.Colors.blue50,
                       title: String(localized: "Storage permission needed"),
                       message: String(localized: "To save this \(item.kind.title.lowercased()) to your phone’s Gallery, allow GradIt to add photos and videos.\n\nGradIt only saves what you choose to download. It doesn’t read your other photos."),
                       cancelTitle: String(localized: "Not now"), confirmTitle: String(localized: "Allow"),
                       confirmColor: Theme.Colors.blue600,
                       onConfirm: {
                           showsPermission = false
                           Task {
                               if await PhotoLibrarySaver.requestAccess() {
                                   save(item)
                               } else {
                                   saveState = .failed(PhotoLibrarySaverError.notAllowed.localizedDescription)
                               }
                           }
                       },
                       onCancel: { showsPermission = false })
            .preferredColorScheme(.light)
    }
}

/// One video page: plays the file when there is one, otherwise shows the poster.
private struct GalleryVideoPage: View {
    let item: GalleryItem
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                GalleryTileView(item: item, cornerRadius: 0, symbolSize: 80)
                    .overlay(alignment: .bottom) {
                        Text("Streaming · \(item.duration ?? "")").font(AppFont.jakarta(12, .semibold))
                            .foregroundStyle(.white.opacity(0.8)).padding(12)
                    }
                    .padding(16)
            }
        }
        .accessibilityLabel(Text(item.accessibilityText))
        .onAppear {
            if player == nil, let url = item.mediaURL { player = AVPlayer(url: url) }
        }
        .onDisappear { player?.pause() }
    }
}

#Preview("Gallery") {
    NavigationStack {
        EventGalleryScreen(model: EventGalleryViewModel(preview: MockEventService.sportsDayGallery(), localImages: [:]),
                           onBack: {}) { EmptyView() }
    }
}
