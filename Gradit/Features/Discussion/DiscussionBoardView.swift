//
//  DiscussionBoardView.swift
//  Gradit
//
//  Discussion Board list: category filter, thread cards, pull-to-refresh and a
//  compose button. Opened from a dashboard menu via Route.feature(.discussionBoard).
//

import SwiftUI

struct DiscussionBoardView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: DiscussionBoardViewModel
    @State private var isComposing = false

    private let service: DiscussionServiceProtocol

    init(service: DiscussionServiceProtocol) {
        self.service = service
        _viewModel = State(initialValue: DiscussionBoardViewModel(service: service))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content
            composeButton
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle("Discussion Board")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.threads.isEmpty { await viewModel.load() }
        }
        .sheet(isPresented: $isComposing) {
            ComposeThreadView(service: service) { newThread in
                viewModel.insert(newThread)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.threads.isEmpty {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) { Task { await viewModel.load() } }
                    .frame(maxHeight: .infinity)
            } else {
                emptyState(String(localized: "No discussions yet. Start the first one."))
            }
        } else {
            VStack(spacing: 0) {
                categoryBar
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if viewModel.visibleThreads.isEmpty {
                            emptyState(String(localized: "Nothing in this category yet."))
                                .padding(.top, 40)
                        } else {
                            ForEach(viewModel.visibleThreads) { thread in
                                DiscussionThreadCard(
                                    thread: thread,
                                    onOpen: { router.push(.discussion(.thread(thread))) },
                                    onLike: { Task { await viewModel.toggleLike(thread) } }
                                )
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
                .scrollIndicators(.hidden)
                .refreshable { await viewModel.load() }
            }
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                categoryChip(title: String(localized: "All"), isOn: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(DiscussionCategory.allCases) { category in
                    categoryChip(title: category.title, isOn: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .background(Theme.Colors.surfaceMuted)
    }

    private func categoryChip(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(AppFont.jakarta(13, isOn ? .bold : .semibold))
            .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
            .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
            .buttonStyle(.plain)
            .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private func emptyState(_ message: String) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "bubble.left.and.bubble.right", size: 56, radius: 18)
            Text(message)
                .font(AppFont.jakarta(14))
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var composeButton: some View {
        Button {
            isComposing = true
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.Colors.white)
                .frame(width: 56, height: 56)
                .background(Theme.Colors.blue600, in: Circle())
                .shadow(color: Color(hex: 0x101828, opacity: 0.22), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(20)
        .accessibilityLabel("New discussion")
    }
}

/// A thread summary card in the board list.
struct DiscussionThreadCard: View {
    let thread: DiscussionThread
    let onOpen: () -> Void
    let onLike: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    InitialsAvatar(initials: DashboardGreeting.initials(thread.authorName), size: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(thread.authorName)
                            .font(AppFont.jakarta(14, .heavy))
                            .foregroundStyle(Theme.Colors.ink900)
                        Text(metaLine)
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
                    .font(AppFont.jakarta(16, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(thread.body)
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink700)
                    .lineSpacing(2)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 18) {
                    Button(action: onLike) {
                        Label("\(thread.likeCount)", systemImage: thread.isLiked ? "heart.fill" : "heart")
                            .font(AppFont.jakarta(13, .bold))
                            .foregroundStyle(thread.isLiked ? Theme.Colors.error : Theme.Colors.ink500)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(thread.isLiked ? "Unlike" : "Like")

                    Label("\(thread.replyCount)", systemImage: "bubble.left")
                        .font(AppFont.jakarta(13, .semibold))
                        .foregroundStyle(Theme.Colors.ink500)
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(radius: 16)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var metaLine: String {
        if let role = thread.authorRole {
            return "\(role) · \(DiscussionFormat.relative(thread.createdAt))"
        }
        return DiscussionFormat.relative(thread.createdAt)
    }
}

#Preview {
    NavigationStack {
        DiscussionBoardView(service: MockDiscussionService(latency: .zero))
    }
    .environment(AppRouter())
}
