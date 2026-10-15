//
//  NoticeDetailView.swift
//  Gradit
//
//  Notice detail — admin (meta + manage actions + read report) and reader
//  (author + message + mark unread/share). Design: NoticeBoard.pdf p10–12, p22–24, p26.
//

import SwiftUI

struct NoticeDetailView: View {
    let noticeID: String
    let isReader: Bool
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: NoticeDetailViewModel?
    @State private var isConfirmingDelete = false
    @State private var pinned = true

    var body: some View {
        VStack(spacing: 0) {
            header
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
            if model == nil { model = NoticeDetailViewModel(noticeID: noticeID, isReader: isReader, role: role, service: dependencies.noticeService) }
            await model?.load()
            pinned = model?.detail?.pinned ?? true
        }
        .alert("Delete this notice?", isPresented: $isConfirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dismiss() }
        } message: {
            if let detail = model?.detail {
                Text("It will be removed from the notice board for all \(detail.totalCount) recipients and the read report will be lost. This can't be undone.")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            TopBarBackButton { dismiss() }
            Text("Notice").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Spacer(minLength: 0)
            if isReader {
                ShareLink(item: model?.detail?.title ?? "Notice") {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink700).frame(width: 40, height: 40).dashboardCard(radius: 12)
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func content(_ detail: NoticeDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if isReader, detail.isExpired, let note = detail.expiresText { expiredBanner(note) }
                headerCard(detail)
                if !isReader {
                    actionGrid(detail)
                    readReport(detail)
                }
                messageCard(detail)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) { if isReader { readerBar } }
    }

    private func expiredBanner(_ note: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill").font(.system(size: 13, weight: .bold))
            Text(note).font(AppFont.jakarta(12, .semibold)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.Colors.ink500).padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
    }

    private func headerCard(_ detail: NoticeDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                NoticeCategoryChip(category: detail.category)
                if pinned { PinnedChip() }
                Spacer(minLength: 0)
                if !isReader || detail.isExpired {
                    StatusBadge(text: detail.status.title, tone: detail.status.tone, weight: .heavy)
                }
            }
            Text(detail.title).font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .fixedSize(horizontal: false, vertical: true)

            if isReader {
                NoticeAuthorRow(name: detail.authorName, role: detail.authorRole, time: detail.publishedText)
            } else {
                metaRow(icon: "person.2", label: "Audience", value: detail.audienceText)
                metaRow(icon: "calendar", label: "Published", value: detail.publishedText)
                if let expires = detail.expiresText { metaRow(icon: "clock", label: "Expires", value: expires) }
                metaRow(icon: "bell", label: "Notified by", value: detail.notifiedBy)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func metaRow(icon: String, label: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.Colors.ink500).frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func actionGrid(_ detail: NoticeDetail) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            action("pencil", "Edit") {}
            action(pinned ? "pin.slash" : "pin", pinned ? "Unpin" : "Pin") { pinned.toggle() }
            action("paperplane", "Resend") {}
            action("doc.on.doc", "Duplicate") {}
            action("nosign", "Expire now") {}
            action("arrow.down.to.line", "Export") {}
            action("trash", "Delete", destructive: true) { isConfirmingDelete = true }
        }
    }

    private func action(_ icon: String, _ label: LocalizedStringKey, destructive: Bool = false, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                Text(label).font(AppFont.jakarta(10, .semibold))
            }
            .foregroundStyle(destructive ? Theme.Colors.destructive : Theme.Colors.ink700)
            .frame(maxWidth: .infinity).frame(height: 58)
            .dashboardCard(radius: 12, border: destructive ? Theme.Colors.destructive.opacity(0.4) : Theme.Colors.line)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func readReport(_ detail: NoticeDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Read report").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Text("\(detail.readCount) / \(detail.totalCount) read").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Colors.surfaceMuted)
                    Capsule().fill(Theme.Colors.green600)
                        .frame(width: max(0, geo.size.width * (detail.totalCount > 0 ? Double(detail.readCount) / Double(detail.totalCount) : 0)))
                }
            }
            .frame(height: 8)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func messageCard(_ detail: NoticeDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !isReader { Text("Message").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900) }
            Text(detail.message).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            if !detail.attachments.isEmpty {
                Text("Attachments (\(detail.attachments.count))").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                ForEach(detail.attachments) { AttachmentRow(attachment: $0) }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private var readerBar: some View {
        HStack(spacing: 12) {
            Button { model?.markUnread(); dismiss() } label: {
                Label("Mark as unread", systemImage: "envelope").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
            }
            .buttonStyle(.plain)
            ShareLink(item: model?.detail?.title ?? "Notice") {
                Label("Share", systemImage: "square.and.arrow.up").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.surfaceMuted)
    }
}

#Preview("Admin") {
    NavigationStack { NoticeDetailView(noticeID: "n2", isReader: false, role: .management) }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}

#Preview("Reader") {
    NavigationStack { NoticeDetailView(noticeID: "n3", isReader: true, role: .student) }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
