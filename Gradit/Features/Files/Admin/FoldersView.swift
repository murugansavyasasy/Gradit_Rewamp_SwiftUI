//
//  FoldersView.swift
//  Gradit
//
//  Folders list with create / rename / delete. Design: filesModule.pdf p6–9.
//

import SwiftUI

struct FoldersView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: FoldersViewModel?
    @State private var isCreating = false
    @State private var renaming: FileFolder?
    @State private var deleting: FileFolder?
    @State private var folderName = ""

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Folders"),
                             subtitle: model.map { "\($0.folders.count) folders · \($0.totalFiles) files" }, showsBack: true) { dismiss() }
            if let model {
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = FoldersViewModel(service: dependencies.fileService) }
            await model?.load()
        }
        .alert("New folder", isPresented: $isCreating) {
            TextField("Folder name", text: $folderName)
            Button("Cancel", role: .cancel) { folderName = "" }
            Button("Create") { if !folderName.trimmed.isEmpty { model?.create(name: folderName.trimmed) }; folderName = "" }
        }
        .alert("Rename folder", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Folder name", text: $folderName)
            Button("Cancel", role: .cancel) { renaming = nil; folderName = "" }
            Button("Save") { if let f = renaming, !folderName.trimmed.isEmpty { model?.rename(f, to: folderName.trimmed) }; renaming = nil; folderName = "" }
        }
        .alert("Delete \"\(deleting?.name ?? "")\"?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Cancel", role: .cancel) {}
            Button("Delete folder", role: .destructive) { if let f = deleting { model?.delete(f) } }
        } message: {
            if let f = deleting { Text("The \(f.fileCount) files inside move to \"Unsorted\". They stay published and receivers aren't affected.") }
        }
    }

    private func content(_ model: FoldersViewModel) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                Button { folderName = ""; isCreating = true } label: {
                    Label("Create folder", systemImage: "folder.badge.plus")
                        .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())

                VStack(spacing: 0) {
                    ForEach(Array(model.folders.enumerated()), id: \.element.id) { index, folder in
                        if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                        row(folder)
                    }
                }
                .dashboardCard(radius: 16)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func row(_ folder: FileFolder) -> some View {
        HStack(spacing: 12) {
            IconTile(systemImage: "folder.fill", size: 40, foreground: Theme.Colors.amber800, background: Theme.Colors.warningBackground)
            VStack(alignment: .leading, spacing: 1) {
                Text(folder.name).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(folder.fileCount == 1 ? "1 file" : "\(folder.fileCount) files").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            Button { renaming = folder; folderName = folder.name } label: {
                Image(systemName: "pencil").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink700).frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            Button { deleting = folder } label: {
                Image(systemName: "trash").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.destructive).frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
    }
}

#Preview {
    NavigationStack { FoldersView() }.environment(AppRouter()).environment(AppDependencies.previewZero)
}
