//
//  DiscussionThreadView.swift
//  Gradit
//
//  A single discussion thread: the original post, its replies, and a composer.
//

import SwiftUI

struct DiscussionThreadView: View {
    @State private var viewModel: DiscussionThreadViewModel
    @FocusState private var replyFocused: Bool

    init(thread: DiscussionThread, service: DiscussionServiceProtocol) {
        _viewModel = State(initialValue: DiscussionThreadViewModel(thread: thread, service: service))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                threadHeader
                repliesSection
            }
            .padding(16)
            .padding(.bottom, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle("Discussion")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { replyBar }
        .task { await viewModel.load() }
    }

    // MARK: - Original post

    private var threadHeader: some View {
        let thread = viewModel.thread
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                InitialsAvatar(initials: DashboardGreeting.initials(thread.authorName), size: 44)
                VStack(alignment: .leading, spacing: 1) {
                    Text(thread.authorName)
                        .font(AppFont.jakarta(15, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text(metaLine(role: thread.authorRole, date: thread.createdAt))
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                if thread.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Colors.amber800)
                        .accessibilityLabel("Pinned")
                }
            }

            StatusBadge(text: thread.category.title, tone: thread.category.tone)

            Text(thread.title)
                .font(AppFont.jakarta(19, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
                .fixedSize(horizontal: false, vertical: true)

            Text(thread.body)
                .font(AppFont.jakarta(15))
                .foregroundStyle(Theme.Colors.ink700)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 18) {
                Label("\(thread.likeCount)", systemImage: thread.isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(thread.isLiked ? Theme.Colors.error : Theme.Colors.ink500)
                Label("\(thread.replyCount)", systemImage: "bubble.left")
                    .foregroundStyle(Theme.Colors.ink500)
                Spacer(minLength: 0)
            }
            .font(AppFont.jakarta(13, .bold))
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    // MARK: - Replies

    private var repliesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(repliesTitle)
                .font(AppFont.jakarta(14, .heavy))
                .foregroundStyle(Theme.Colors.ink700)
                .accessibilityAddTraits(.isHeader)

            if viewModel.replies.isEmpty {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
                } else {
                    Text("No replies yet. Be the first to reply.")
                        .font(AppFont.jakarta(13))
                        .foregroundStyle(Theme.Colors.ink500)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            } else {
                ForEach(viewModel.replies) { reply in
                    replyRow(reply)
                }
            }
        }
    }

    private func replyRow(_ reply: DiscussionReply) -> some View {
        HStack(alignment: .top, spacing: 10) {
            InitialsAvatar(initials: DashboardGreeting.initials(reply.authorName), size: 36)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(reply.authorName)
                        .font(AppFont.jakarta(13, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text(DiscussionFormat.relative(reply.createdAt))
                        .font(AppFont.jakarta(11))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Text(reply.body)
                    .font(AppFont.jakarta(14))
                    .foregroundStyle(Theme.Colors.ink700)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 14)
    }

    // MARK: - Reply composer

    private var replyBar: some View {
        VStack(spacing: 6) {
            if let error = viewModel.sendErrorMessage {
                Text(error)
                    .font(AppFont.jakarta(12, .semibold))
                    .foregroundStyle(Theme.Colors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 10) {
                TextField("Write a reply…", text: $viewModel.draft, axis: .vertical)
                    .font(AppFont.jakarta(15))
                    .lineLimit(1...4)
                    .focused($replyFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.Colors.line))

                Button {
                    replyFocused = false
                    Task { await viewModel.send() }
                } label: {
                    ZStack {
                        if viewModel.isSending {
                            ProgressView().tint(Theme.Colors.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.Colors.white)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(viewModel.canSend ? Theme.Colors.blue600 : Theme.Colors.ink300, in: Circle())
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(!viewModel.canSend)
                .accessibilityLabel("Send reply")
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Theme.Colors.white)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.Colors.line).frame(height: 1)
        }
    }

    // MARK: - Helpers

    private var repliesTitle: String {
        let count = viewModel.thread.replyCount
        return count == 0 ? String(localized: "Replies") : String(localized: "Replies (\(count))")
    }

    private func metaLine(role: String?, date: Date) -> String {
        if let role {
            return "\(role) · \(DiscussionFormat.relative(date))"
        }
        return DiscussionFormat.relative(date)
    }
}

#Preview {
    let thread = DiscussionThread(
        id: "2",
        authorName: "Prof. Karthik Raman",
        authorRole: "Faculty",
        category: .academics,
        title: "Extra DSA doubt-clearing session Saturday",
        body: "Holding an optional Data Structures session this Saturday at 10 AM in B-204 before the exams. Bring your questions on trees and graphs.",
        createdAt: .now.addingTimeInterval(-8 * 3600),
        replyCount: 3,
        likeCount: 16,
        isPinned: false,
        isLiked: true
    )
    return NavigationStack {
        DiscussionThreadView(thread: thread, service: MockDiscussionService(latency: .zero))
    }
}
