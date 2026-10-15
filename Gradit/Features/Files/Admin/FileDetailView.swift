//
//  FileDetailView.swift
//  Gradit
//
//  Admin file details: preview, meta and manage actions (edit/replace/move/delete).
//  Design: filesModule.pdf p15–20.
//

import SwiftUI

struct FileDetailView: View {
    let fileID: String
    let isReader: Bool
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: FileDetailViewModel?
    @State private var isMoving = false
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "File details"),
                             subtitle: model?.detail.map { "\($0.category.title) · \($0.folder)" }, showsBack: true) { dismiss() }
            if let model, let detail = model.detail {
                content(detail)
            } else if let model, model.errorMessage != nil {
                ErrorStateView(message: model.errorMessage ?? "") { model.reload() }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = FileDetailViewModel(fileID: fileID, isReader: false, role: role, service: dependencies.fileService) }
            await model?.load()
        }
        .sheet(isPresented: $isMoving) {
            if let detail = model?.detail {
                MoveToFolderSheet(currentFolder: detail.folder, service: dependencies.fileService).presentationDetents([.large])
            }
        }
        .alert("Delete this file?", isPresented: $isConfirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dismiss() }
        } message: {
            if let detail = model?.detail {
                Text("\(detail.name) will be removed for all \(detail.totalCount) receivers and from your folders. This can't be undone.")
            }
        }
    }

    private func content(_ detail: FileDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                FilePreviewPane(kind: detail.kind, extraText: detail.extraText)
                    .padding(12).dashboardCard(radius: 16)
                infoCard(detail)
                actionGrid
                viewStats(detail)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func infoCard(_ detail: FileDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(detail.name).font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                StatusBadge(text: detail.typeLabel, tone: detail.kind.chipTone, weight: .bold)
                Text("\(detail.sizeText) · \(detail.extraText)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            infoRow("Category", detail.category.title)
            infoRow("Folder", detail.folder)
            infoRow("Audience", detail.audienceText)
            infoRow("Schedule", detail.scheduleText)
            infoRow("Expiry", detail.expiryText)
            infoRow("Download", detail.downloadAllowed ? String(localized: "Allowed") : String(localized: "Not allowed"))
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func infoRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).frame(width: 92, alignment: .leading)
            Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900).frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            action("pencil", "Edit details") {}
            action("arrow.triangle.2.circlepath", "Replace file") {}
            action("folder", "Move to folder") { isMoving = true }
            action("trash", "Delete", destructive: true) { isConfirmingDelete = true }
        }
    }

    private func action(_ icon: String, _ label: LocalizedStringKey, destructive: Bool = false, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Label(label, systemImage: icon)
                .font(AppFont.jakarta(14, .bold)).foregroundStyle(destructive ? Theme.Colors.destructive : Theme.Colors.ink700)
                .frame(maxWidth: .infinity, minHeight: 50)
                .dashboardCard(radius: 12, border: destructive ? Theme.Colors.destructive.opacity(0.4) : Theme.Colors.line)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func viewStats(_ detail: FileDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Viewed").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Text("\(detail.viewedCount) / \(detail.totalCount)").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Colors.surfaceMuted)
                    Capsule().fill(Theme.Colors.green600)
                        .frame(width: max(0, geo.size.width * (detail.totalCount > 0 ? Double(detail.viewedCount)/Double(detail.totalCount) : 0)))
                }
            }
            .frame(height: 8)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }
}

// MARK: - Move to folder

private struct MoveToFolderSheet: View {
    let currentFolder: String
    let service: FileServiceProtocol
    @Environment(\.dismiss) private var dismiss
    @State private var folders: [FileFolder] = []
    @State private var selected: String

    init(currentFolder: String, service: FileServiceProtocol) {
        self.currentFolder = currentFolder
        self.service = service
        _selected = State(initialValue: currentFolder)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Move to folder").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("Receivers aren't notified. Only your folders change.").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 36, height: 36).background(Theme.Colors.surfaceMuted, in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(20)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(folders) { folder in
                        let on = selected == folder.name
                        Button { selected = folder.name } label: {
                            HStack(spacing: 12) {
                                Image(systemName: on ? "largecircle.fill.circle" : "circle")
                                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(on ? Theme.Colors.blue600 : Theme.Colors.ink300)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(folder.name).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                                    Text(folder.name == currentFolder ? "Current folder" : "Move here").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                                }
                                Spacer(minLength: 0)
                                if on { Text("Selected").font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.blue600) }
                            }
                            .padding(14).dashboardCard(radius: 14, border: on ? Theme.Colors.blue600 : Theme.Colors.line, borderWidth: on ? 1.5 : 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            PrimaryButton(title: "Move here") { dismiss() }.padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .task { if folders.isEmpty { folders = (try? await service.folders()) ?? [] } }
    }
}

#Preview {
    NavigationStack { FileDetailView(fileID: "f2", isReader: false, role: .management) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
