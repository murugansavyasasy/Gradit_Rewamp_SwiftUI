//
//  FileListView.swift
//  Gradit
//
//  Files list — admin/faculty (manage, list+grid, FAB) and student/parent
//  (read-only). Design: filesModule.pdf p1–5, p21–23.
//

import SwiftUI

struct FileListView: View {
    let isReader: Bool
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: FileListViewModel?

    private var subtitle: String {
        if isReader { return role == .parent ? "For Aarav R. · view online" : "view online" }
        return "\(model?.items.count ?? 0) files"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model {
                tabs(model)
                controls(model)
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) { if !isReader { createButton } }
        .task {
            if model == nil { model = FileListViewModel(isReader: isReader, role: role, service: dependencies.fileService) }
            await model?.load()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Files").font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(subtitle).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            if !isReader {
                Button { router.push(.file(.folders)) } label: {
                    Image(systemName: "folder").font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink700).frame(width: 40, height: 40).dashboardCard(radius: 12)
                }
                .buttonStyle(.plain).accessibilityLabel("Folders")
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func tabs(_ model: FileListViewModel) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 18) {
                tabButton(model, kind: nil, title: String(localized: "All"))
                ForEach(FileKind.allCases) { kind in tabButton(model, kind: kind, title: kind.tabTitle) }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
        .padding(.bottom, 10)
    }

    private func tabButton(_ model: FileListViewModel, kind: FileKind?, title: String) -> some View {
        let on = model.kind == kind
        return Button { model.kind = kind } label: {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("\(model.count(kind))").font(AppFont.jakarta(12, .heavy))
                        .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 8).frame(height: 22)
                        .background(on ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted, in: Capsule())
                    Text(title).font(AppFont.jakarta(15, .bold)).foregroundStyle(on ? Theme.Colors.blue700 : Theme.Colors.ink500)
                }
                Rectangle().fill(on ? Theme.Colors.blue600 : .clear).frame(height: 2)
            }
            .padding(.top, 4).contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func controls(_ model: FileListViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                TextField(String(localized: "Search file name"), text: $model.searchText).font(AppFont.jakarta(15))
            }
            .padding(.horizontal, 14).frame(height: 46).dashboardCard(radius: 12)

            HStack(spacing: 10) {
                AssignmentDropdown(label: String(localized: "Category"), value: model.category, options: model.categoryOptions) { model.category = $0 }
                if !isReader {
                    Spacer(minLength: 0)
                    Button { model.newestFirst.toggle() } label: {
                        HStack(spacing: 6) {
                            Text(model.newestFirst ? String(localized: "Newest") : String(localized: "Oldest"))
                                .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                            Image(systemName: "arrow.up.arrow.down").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
                        }
                        .padding(.horizontal, 12).frame(height: 38).background(Theme.Colors.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(Theme.Colors.border))
                    }
                    .buttonStyle(.plain)
                    Button { model.isGrid.toggle() } label: {
                        Image(systemName: model.isGrid ? "list.bullet" : "square.grid.2x2")
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink700)
                            .frame(width: 38, height: 38).background(Theme.Colors.white, in: .rect(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.Colors.border))
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 10)
    }

    @ViewBuilder
    private func content(_ model: FileListViewModel) -> some View {
        if model.isLoading, model.items.isEmpty {
            loadingSkeleton
        } else if let error = model.errorMessage, model.items.isEmpty {
            stateCard(icon: "wifi.exclamationmark", title: String(localized: "Couldn't load files"),
                      message: String(localized: "Check your internet connection and try again."), action: String(localized: "Try again")) { model.reload() }
        } else if model.visible.isEmpty {
            if isReader {
                stateCard(icon: "folder", title: String(localized: "No files yet"),
                          message: String(localized: "Files your college shares will show here."), action: nil, perform: nil)
            } else {
                stateCard(icon: "folder", title: String(localized: "No files yet"),
                          message: String(localized: "Share circulars, study material, question papers, photos and videos with students, parents and staff."),
                          action: String(localized: "Upload files")) { router.push(.file(.upload)) }
            }
        } else {
            ScrollView {
                if model.isGrid {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(model.visible) { file in gridButton(file) }
                    }
                    .padding(16).padding(.bottom, 96)
                } else {
                    VStack(spacing: 14) {
                        ForEach(model.visible) { file in listButton(file) }
                    }
                    .padding(16).padding(.bottom, isReader ? 24 : 96)
                }
                if isReader {
                    Text("Files open online. To keep a copy, use Download where the sender allows it.")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        .multilineTextAlignment(.center).padding(.horizontal, 24).padding(.bottom, 16)
                }
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func listButton(_ file: SharedFile) -> some View {
        Button { open(file) } label: { FileRow(file: file, isReader: isReader) }.buttonStyle(PressableButtonStyle())
    }
    private func gridButton(_ file: SharedFile) -> some View {
        Button { open(file) } label: { FileGridCard(file: file) }.buttonStyle(PressableButtonStyle())
    }
    private func open(_ file: SharedFile) {
        router.push(isReader ? .file(.viewer(file.id)) : .file(.detail(file.id)))
    }

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 96)
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Colors.line))
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden).redacted(reason: .placeholder)
    }

    private func stateCard(icon: String, title: String, message: String, action: String?, perform: (() -> Void)?) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: icon, size: 64, radius: 20,
                     foreground: icon.contains("wifi") ? Theme.Colors.destructive : Theme.Colors.blue600,
                     background: icon.contains("wifi") ? Theme.Colors.errorBackground : Theme.Colors.blue50)
            Text(title).font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(message).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            if let action, let perform {
                Button(action: perform) {
                    Label(action, systemImage: icon.contains("wifi") ? "arrow.clockwise" : "arrow.up.doc")
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                        .padding(.horizontal, 20).frame(height: 48).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle()).padding(.top, 4)
            }
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16).frame(maxHeight: .infinity, alignment: .top)
    }

    private var createButton: some View {
        Button { router.push(.file(.upload)) } label: {
            Image(systemName: "plus").font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.Colors.white)
                .frame(width: 56, height: 56).background(Theme.Colors.blue600, in: Circle())
                .shadow(color: Theme.Colors.blue600.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(PressableButtonStyle()).padding(20).accessibilityLabel("Upload files")
    }
}

#Preview("Admin") {
    NavigationStack { FileListView(isReader: false, role: .management) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}

#Preview("Reader") {
    NavigationStack { FileListView(isReader: true, role: .student) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
