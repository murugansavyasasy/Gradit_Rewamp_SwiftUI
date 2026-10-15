//
//  FileViewerView.swift
//  Gradit
//
//  Student / parent file viewer: preview + Share / Download (or view-only).
//  Design: filesModule.pdf p24–31.
//

import SwiftUI

struct FileViewerView: View {
    let fileID: String
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: FileDetailViewModel?

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: model?.detail?.name ?? String(localized: "File"),
                             subtitle: model?.detail?.authorDate, showsBack: true) { dismiss() }
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
            if model == nil { model = FileDetailViewModel(fileID: fileID, isReader: true, role: role, service: dependencies.fileService) }
            await model?.load()
        }
    }

    private func content(_ detail: FileDetail) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    FilePreviewPane(kind: detail.kind, extraText: detail.extraText)
                        .padding(12).dashboardCard(radius: 16)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            StatusBadge(text: detail.typeLabel, tone: detail.kind.chipTone, weight: .bold)
                            Text("\(detail.sizeText) · \(detail.category.title)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        }
                        Text(detail.description).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700)
                            .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
                    PoweredByFooter()
                }
                .padding(16).padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            bottomBar(detail)
        }
    }

    private func bottomBar(_ detail: FileDetail) -> some View {
        HStack(spacing: 12) {
            ShareLink(item: detail.name) {
                Label("Share", systemImage: "square.and.arrow.up").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
            }
            if detail.downloadAllowed {
                Button {} label: {
                    Label("Download", systemImage: "arrow.down.to.line").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
            } else {
                Label("Download not allowed", systemImage: "lock")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.white)
    }
}

#Preview("Downloadable") {
    NavigationStack { FileViewerView(fileID: "f2", role: .student) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}

#Preview("View only") {
    NavigationStack { FileViewerView(fileID: "f3", role: .student) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
