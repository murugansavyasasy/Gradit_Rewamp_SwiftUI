//
//  MessagesInboxView.swift
//  Gradit
//
//  Messages inbox (text + voice). Voice plays and text expands inline in the
//  list — no detail screen. Parent/student is read-only; staff get a composer.
//

import SwiftUI

struct MessagesInboxView: View {
    let role: UserRole
    var initialFilter: MessageFilter = .all

    @Environment(AppDependencies.self) private var dependencies
    @State private var model: MessagesInboxViewModel?
    @State private var searchText = ""
    @State private var isComposing = false
    @State private var nowPlayingID: String?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let model {
                    content(model)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            if model?.isStaff == true {
                composeButton
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model == nil {
                model = MessagesInboxViewModel(role: role, service: dependencies.messagingService, filter: initialFilter)
            }
            if model?.messages.isEmpty == true { await model?.load() }
        }
        .sheet(isPresented: $isComposing) {
            NavigationStack {
                MessageComposeView(mode: .text, showsCancel: true)
            }
        }
    }

    private var navigationTitle: String {
        switch initialFilter {
        case .text: String(localized: "Text Msg")
        case .voice: String(localized: "Voice Msg")
        default: String(localized: "Messages")
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ model: MessagesInboxViewModel) -> some View {
        if model.messages.isEmpty {
            if model.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = model.errorMessage {
                ErrorStateView(message: error) { Task { await model.load() } }
                    .frame(maxHeight: .infinity)
            } else {
                MessagesEmptyState(filter: model.filter)
            }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if model.isParent { studentSwitcher(model) }
                    readOnlyBannerIfNeeded(model)
                    filterBar(model)

                    let sections = visibleSections(model)
                    if sections.isEmpty {
                        MessagesEmptyState(filter: model.filter).padding(.top, 30)
                    } else {
                        ForEach(sections, id: \.section) { group in
                            Text(group.section.title.uppercased())
                                .font(AppFont.jakarta(12, .heavy))
                                .tracking(0.6)
                                .foregroundStyle(Theme.Colors.ink500)
                                .padding(.top, 4)
                            ForEach(group.messages) { message in
                                if message.kind == .voice {
                                    VoiceMessageCard(message: message, nowPlayingID: $nowPlayingID) {
                                        model.open(message)
                                    }
                                } else {
                                    TextMessageCard(message: message) {
                                        model.open(message)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 90)
            }
            .scrollIndicators(.hidden)
            .refreshable { await model.load() }
            .searchable(text: $searchText, prompt: Text("Search messages"))
        }
    }

    /// Sections with the search term applied (counts stay based on the full inbox).
    private func visibleSections(_ model: MessagesInboxViewModel) -> [(section: MessageSection, messages: [Message])] {
        let query = searchText.trimmed.lowercased()
        guard !query.isEmpty else { return model.sections }
        return model.sections.compactMap { group in
            let matches = group.messages.filter {
                $0.title.lowercased().contains(query)
                    || $0.body.lowercased().contains(query)
                    || $0.senderName.lowercased().contains(query)
            }
            return matches.isEmpty ? nil : (group.section, matches)
        }
    }

    // MARK: - Header pieces

    private func studentSwitcher(_ model: MessagesInboxViewModel) -> some View {
        Menu {
            ForEach(model.students) { student in
                Button {
                    Task { await model.select(student) }
                } label: {
                    Text("\(student.name) · \(student.program) · \(student.term)")
                }
            }
        } label: {
            HStack(spacing: 10) {
                if let student = model.selectedStudent {
                    InitialsAvatar(initials: DashboardGreeting.initials(student.name), size: 32)
                    Text(student.name)
                        .font(AppFont.jakarta(14, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text("\(student.program) · \(student.term)")
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(radius: 24)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func readOnlyBannerIfNeeded(_ model: MessagesInboxViewModel) -> some View {
        if !model.isStaff {
            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.blue700)
                Text("Messages from your college. You cannot reply to these.")
                    .font(AppFont.jakarta(12, .semibold))
                    .foregroundStyle(Theme.Colors.blue700)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.blue50, in: .rect(cornerRadius: 12))
        }
    }

    private func filterBar(_ model: MessagesInboxViewModel) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(MessageFilter.allCases) { filter in
                    let isOn = model.filter == filter
                    Button {
                        model.filter = filter
                    } label: {
                        HStack(spacing: 6) {
                            Text(filter.title)
                            Text("\(model.count(for: filter))")
                                .foregroundStyle(isOn ? Theme.Colors.white.opacity(0.9) : Theme.Colors.ink500)
                        }
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? [.isSelected] : [])
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
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
        .accessibilityLabel("New message")
    }
}

// MARK: - Shared card header

private struct MessageCardHeader: View {
    let message: Message

    var body: some View {
        HStack(spacing: 10) {
            InitialsAvatar(
                initials: DashboardGreeting.initials(message.senderName),
                size: 40,
                foreground: message.avatarForeground,
                background: message.avatarBackground
            )
            VStack(alignment: .leading, spacing: 1) {
                Text(message.senderName)
                    .font(AppFont.jakarta(14, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                if let role = message.senderRole {
                    Text(role)
                        .font(AppFont.jakarta(11, .bold))
                        .foregroundStyle(message.avatarForeground)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Text(MessageFormat.timestamp(message.sentAt))
                .font(AppFont.jakarta(11))
                .foregroundStyle(Theme.Colors.ink500)
        }
    }
}

private struct MessageTitleRow: View {
    let message: Message
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(message.avatarForeground)
            Text(message.title)
                .font(AppFont.jakarta(15, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
                .lineLimit(1)
            if message.isUnread {
                Text("New")
                    .font(AppFont.jakarta(10, .heavy))
                    .foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.blue600, in: Capsule())
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Text card (expand inline)

private struct TextMessageCard: View {
    let message: Message
    let onOpen: () -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MessageCardHeader(message: message)
            HStack(alignment: .firstTextBaseline) {
                MessageTitleRow(message: message, systemImage: "envelope.fill")
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            Text(message.body)
                .font(AppFont.jakarta(13))
                .foregroundStyle(Theme.Colors.ink700)
                .lineSpacing(3)
                .lineLimit(isExpanded ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
        .contentShape(.rect)
        .onTapGesture { toggle() }
        .accessibilityHint(isExpanded ? "Collapse" : "Expand to read")
    }

    private func toggle() {
        if !isExpanded { onOpen() }
        withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
    }
}

// MARK: - Voice card (play inline)

private struct VoiceMessageCard: View {
    let message: Message
    @Binding var nowPlayingID: String?
    let onOpen: () -> Void

    @State private var player: VoiceMessagePlayerViewModel
    @State private var showTranscript = false

    init(message: Message, nowPlayingID: Binding<String?>, onOpen: @escaping () -> Void) {
        self.message = message
        self._nowPlayingID = nowPlayingID
        self.onOpen = onOpen
        _player = State(initialValue: VoiceMessagePlayerViewModel(message: message))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MessageCardHeader(message: message)
            HStack {
                MessageTitleRow(message: message, systemImage: "mic.fill")
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showTranscript.toggle() }
                } label: {
                    Image(systemName: showTranscript ? "chevron.up" : "text.quote")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink500)
                        .frame(width: 28, height: 28)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showTranscript ? "Hide transcript" : "Show transcript")
            }

            HStack(spacing: 12) {
                Button(action: togglePlay) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Colors.white)
                        .frame(width: 40, height: 40)
                        .background(Theme.Colors.blue600, in: Circle())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

                VoiceWaveform(progress: player.progress, height: 28)
                    .frame(maxWidth: .infinity)

                Text("\(player.elapsedLabel) / \(player.totalLabel)")
                    .font(AppFont.jakarta(11, .bold))
                    .foregroundStyle(Theme.Colors.ink500)
                    .monospacedDigit()
            }

            if showTranscript {
                Text(message.body)
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink700)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
        .onChange(of: nowPlayingID) { _, newID in
            if newID != message.id, player.isPlaying { player.pause() }
        }
        .onDisappear { player.pause() }
    }

    private func togglePlay() {
        onOpen()
        if player.isPlaying {
            player.pause()
        } else {
            nowPlayingID = message.id
            player.play()
        }
    }
}

// MARK: - Empty state

struct MessagesEmptyState: View {
    let filter: MessageFilter

    private var message: String {
        switch filter {
        case .voice: String(localized: "No voice messages")
        case .unread: String(localized: "You're all caught up")
        default: String(localized: "No messages yet")
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            IconTile(systemImage: filter == .voice ? "mic.slash" : "tray", size: 56, radius: 18)
            Text(message)
                .font(AppFont.jakarta(15, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
            Text("Messages from your college will appear here.")
                .font(AppFont.jakarta(13))
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

#Preview {
    let deps = AppDependencies(
        apiClient: APIClient(baseURL: AppConfig.baseURL),
        userService: MockUserService(),
        authService: MockAuthService(latency: .zero),
        dashboardService: MockDashboardService(latency: .zero),
        profileService: MockProfileService(latency: .zero),
        discussionService: MockDiscussionService(latency: .zero),
        messagingService: MockMessagingService(latency: .zero)
    )
    return NavigationStack {
        MessagesInboxView(role: .parent)
    }
    .environment(AppRouter())
    .environment(deps)
    .environment(AuthSession.preview())
}
