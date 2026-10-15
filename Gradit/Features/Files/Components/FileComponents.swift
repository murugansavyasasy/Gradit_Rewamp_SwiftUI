//
//  FileComponents.swift
//  Gradit
//
//  Shared building blocks for the Files module. Design: filesModule.pdf.
//

import SwiftUI

extension FileKind {
    var tint: Color {
        switch self {
        case .pdf: Theme.Colors.destructive
        case .image: Theme.Colors.green700
        case .document: Theme.Colors.blue600
        case .video: Theme.Colors.white
        }
    }
    var tintBackground: Color {
        switch self {
        case .pdf: Theme.Colors.errorBackground
        case .image: Theme.Colors.green50
        case .document: Theme.Colors.blue50
        case .video: Theme.Colors.ink900
        }
    }
    var chipTone: StatusBadge.Tone {
        switch self {
        case .pdf: .red
        case .image: .green
        case .document: .blueSoft
        case .video: .dark
        }
    }
}

/// Square kind icon tile.
struct FileKindTile: View {
    let kind: FileKind
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: kind.systemImage)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(kind.tint)
            .frame(width: size, height: size)
            .background(kind.tintBackground, in: .rect(cornerRadius: 12))
    }
}

/// File row for the list view.
struct FileRow: View {
    let file: SharedFile
    var isReader = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                FileKindTile(kind: file.kind)
                VStack(alignment: .leading, spacing: 3) {
                    Text(file.name).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        StatusBadge(text: file.typeLabel, tone: file.kind.chipTone, weight: .bold)
                        Text(file.sizeText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        Text("· \(file.dateText)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
                    }
                    if isReader {
                        Text("\(file.author) · \(file.category.title)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    } else {
                        if file.status == .scheduled { StatusBadge(text: "Scheduled", tone: .amber, weight: .heavy) }
                        Text(file.audienceText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if isReader, file.isNew { StatusBadge(text: "New", tone: .blueSolid, weight: .heavy) }
            }
            if !isReader, file.totalCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "eye").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
                    Text("\(file.viewedCount) / \(file.totalCount) viewed").font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink700)
                }
                progressBar(file.progress)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func progressBar(_ value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.surfaceMuted)
                Capsule().fill(Theme.Colors.green600).frame(width: max(0, geo.size.width * value))
            }
        }
        .frame(height: 5)
    }
}

/// Kind-specific preview pane used by the detail and viewer screens.
struct FilePreviewPane: View {
    let kind: FileKind
    let extraText: String            // "3 pages" / "04:32" / "24 slides" / "4032 × 3024"

    var body: some View {
        switch kind {
        case .pdf: paged(label: extraText, isDoc: false)
        case .document: paged(label: extraText, isDoc: true)
        case .image: imagePane
        case .video: videoPane
        }
    }

    private func paged(label: String, isDoc: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.Colors.surfaceMuted
                RoundedRectangle(cornerRadius: 8).fill(Theme.Colors.white)
                    .frame(width: 150, height: 190)
                    .overlay(Image(systemName: isDoc ? "rectangle.on.rectangle" : "doc.richtext")
                        .font(.system(size: 34, weight: .light)).foregroundStyle(Theme.Colors.ink300))
                    .shadow(color: Color(hex: 0x101828, opacity: 0.06), radius: 6, y: 3)
            }
            .frame(height: 240).frame(maxWidth: .infinity).clipShape(.rect(cornerRadius: 14))
            HStack {
                Image(systemName: "chevron.left").foregroundStyle(Theme.Colors.ink500)
                Spacer()
                Text(isDoc ? "Online preview · Slide 1 of \(pageCount)" : "Page 1 of \(pageCount)")
                    .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.horizontal, 6).padding(.top, 10)
        }
    }

    private var pageCount: String { extraText.components(separatedBy: " ").first ?? "1" }

    private var imagePane: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [Theme.Colors.blue700, Color(hex: 0xE9C98F)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 240).frame(maxWidth: .infinity)
                .overlay(Image(systemName: "photo").font(.system(size: 40, weight: .light)).foregroundStyle(.white.opacity(0.85)))
                .clipShape(.rect(cornerRadius: 14))
            HStack {
                Image(systemName: "minus.magnifyingglass").foregroundStyle(Theme.Colors.ink500)
                Spacer()
                Text("100% · pinch to zoom").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Image(systemName: "plus.magnifyingglass").foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.horizontal, 6).padding(.top, 10)
        }
    }

    private var videoPane: some View {
        ZStack(alignment: .bottom) {
            Theme.Colors.ink900
            Image(systemName: "play.fill").font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.Colors.ink900)
                .frame(width: 56, height: 56).background(Theme.Colors.white, in: Circle())
            HStack {
                Text("00:00 / \(extraText)").font(AppFont.jakarta(12, .bold)).foregroundStyle(.white)
                Spacer()
                Text("Streaming · 720p").font(AppFont.jakarta(12, .bold)).foregroundStyle(.white)
            }
            .padding(12)
        }
        .frame(height: 240).frame(maxWidth: .infinity).clipShape(.rect(cornerRadius: 14))
    }
}

/// Grid card for the grid view.
struct FileGridCard: View {
    let file: SharedFile

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                file.kind.tintBackground
                Image(systemName: file.kind.systemImage).font(.system(size: 30, weight: .semibold)).foregroundStyle(file.kind.tint)
            }
            .frame(height: 96).frame(maxWidth: .infinity).clipShape(.rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900).lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    StatusBadge(text: file.typeLabel, tone: file.kind.chipTone, weight: .bold)
                    Text(file.sizeText).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                }
                Text(file.dateText).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
            }
            .padding(.top, 10)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }
}
