//
//  MessagesInboxView.swift
//  Gradit
//
//  Messages inbox (text + voice), shown by the Text Msg / Voice Msg menu tiles for
//  parents and students. Design: 03 Parent / Student App › Text Msg / Voice Msg
//  (MsgInbox). Voice plays and text expands inline in the list — no detail screen.
//  Parent/student is read-only; staff get a composer.
//

import SwiftUI

struct MessagesInboxView: View {
    let role: UserRole
    var initialFilter: MessageFilter = .all

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: MessagesInboxViewModel?
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isMenuOpen = false
    @State private var isComposing = false
    @State private var nowPlayingID: String?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                searchHeader
            } else {
                header
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let model {
                        if model.isParent, !model.students.isEmpty { studentSwitcher(model) }
                        readOnlyNoteIfNeeded(model)
                        filterChips(model)
                    }
                    stateContent
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, model?.isStaff == true ? 96 : 20)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await model?.load() }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .overlay(alignment: .topTrailing) { moreMenu }
        .overlay(alignment: .bottomTrailing) {
            if model?.isStaff == true { composeButton }
        }
        .navigationTitle(navigationTitle)
        .toolbar(.hidden, for: .navigationBar)
        .keepsSwipeBack()
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
        .animation(.easeOut(duration: 0.15), value: isMenuOpen)
        .animation(.easeOut(duration: 0.2), value: isSearching)
    }

    private var navigationTitle: String {
        switch initialFilter {
        case .text: String(localized: "Text Msg")
        case .voice: String(localized: "Voice Msg")
        default: String(localized: "Messages")
        }
    }

    // MARK: - Header

    /// Pushed from a menu tile → back button; tab root → none.
    private var backAction: (() -> Void)? {
        guard isPresented else { return nil }
        return { dismiss() }
    }

    private var header: some View {
        MessagingTopBar(
            title: navigationTitle,
            titleWeight: .heavy,
            background: Theme.Colors.surfaceMuted,
            spacing: 8,
            trailingPadding: 12,
            titleLeadingPadding: 4,
            onBack: backAction
        ) {
            TopBarIconButton(systemImage: "magnifyingglass", accessibilityLabel: "Search messages") {
                isMenuOpen = false
                isSearching = true
                isSearchFocused = true
            }
            TopBarIconButton(systemImage: "ellipsis", accessibilityLabel: "More options") {
                isMenuOpen.toggle()
            }
            .rotationEffect(.degrees(90))
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 8) {
            TopBarBackButton(accessibilityLabel: "Back to messages") {
                searchText = ""
                isSearchFocused = false
                isSearching = false
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.blue600)
                TextField("Search messages", text: $searchText)
                    .font(AppFont.jakarta(15))
                    .foregroundStyle(Theme.Colors.ink900)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.Colors.ink300)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 6)
            .frame(height: 46)
            .designFieldChrome(isFocused: isSearchFocused, radius: 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(height: 64)
        .background(Theme.Colors.surfaceMuted)
        .onAppear { isSearchFocused = true }
    }

    @ViewBuilder
    private var moreMenu: some View {
        if isMenuOpen {
            ZStack(alignment: .topTrailing) {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { isMenuOpen = false }
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    Button {
                        model?.markAllRead()
                        isMenuOpen = false
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Mark all as read")
                                .font(AppFont.jakarta(14, .semibold))
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(Theme.Colors.ink900)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 48)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: 10))
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(model?.hasUnread != true)
                    .opacity(model?.hasUnread == true ? 1 : 0.5)
                }
                .padding(6)
                .frame(width: 220)
                .background(Theme.Colors.white, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.line))
                .shadow(color: Color(hex: 0x101828, opacity: 0.16), radius: 14, y: 12)
                .padding(.top, 58)
                .padding(.trailing, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
            }
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
            HStack(spacing: 8) {
                if let student = model.selectedStudent {
                    InitialsAvatar(initials: DashboardGreeting.initials(student.name), size: 32)
                    Text(student.name)
                        .font(AppFont.jakarta(14, .bold))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text("\(student.program) · \(student.term)")
                        .font(AppFont.jakarta(13))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink900)
            }
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .frame(minHeight: 44)
            .background(Theme.Colors.white, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.Colors.border))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Viewing messages for \(model.selectedStudent?.name ?? ""). Switch student")
    }

    @ViewBuilder
    private func readOnlyNoteIfNeeded(_ model: MessagesInboxViewModel) -> some View {
        if !model.isStaff {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.top, 1)
                Text("Messages from your college. You cannot reply to these.")
                    .font(AppFont.jakarta(13, .semibold))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.Colors.blue700)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.blue50, in: .rect(cornerRadius: 14))
        }
    }

    private func filterChips(_ model: MessagesInboxViewModel) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(MessageFilter.allCases) { filter in
                    let isOn = model.filter == filter
                    Button {
                        model.filter = filter
                    } label: {
                        HStack(spacing: 5) {
                            Text(filter.title)
                                .font(AppFont.jakarta(13, isOn ? .bold : .semibold))
                            Text("\(model.count(for: filter))")
                                .font(AppFont.jakarta(12, .heavy))
                                .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.blue700)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(isOn ? Theme.Colors.white.opacity(0.22) : Theme.Colors.blue50, in: Capsule())
                        }
                        .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 10)
                        .frame(height: 44)
                        .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -16)
    }

    // MARK: - States

    @ViewBuilder
    private var stateContent: some View {
        if let model {
            if model.messages.isEmpty {
                if model.isLoading {
                    InboxLoadingSkeleton()
                } else if model.errorMessage != nil {
                    errorCard(model)
                } else {
                    InboxEmptyState(kind: .noMessages)
                }
            } else {
                let sections = visibleSections(model)
                let query = searchText.trimmed
                if sections.isEmpty {
                    if query.isEmpty {
                        InboxEmptyState(kind: InboxEmptyState.Kind(filter: model.filter))
                    } else {
                        Text("No messages match “\(query)”.")
                            .font(AppFont.jakarta(14))
                            .foregroundStyle(Theme.Colors.ink500)
                            .multilineTextAlignment(.center)
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .dashboardCard(radius: 16)
                    }
                } else {
                    ForEach(sections, id: \.section) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.section.title.uppercased())
                                .font(AppFont.jakarta(12, .heavy))
                                .tracking(0.72)
                                .foregroundStyle(Theme.Colors.ink500)
                                .padding(.top, 4)
                                .accessibilityAddTraits(.isHeader)
                            ForEach(group.messages) { message in
                                InboxMessageCard(message: message, nowPlayingID: $nowPlayingID) {
                                    model.open(message)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            InboxLoadingSkeleton()
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

    private func errorCard(_ model: MessagesInboxViewModel) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Theme.Colors.red700)
                .frame(width: 60, height: 60)
                .background(Theme.Colors.errorBackground, in: Circle())
            Text("Could not load messages")
                .font(AppFont.jakarta(17, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
            Text("Check your internet connection and try again.")
                .font(AppFont.jakarta(13))
                .lineSpacing(3)
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button {
                    Task { await model.load() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Retry")
                    }
                    .font(AppFont.jakarta(15, .bold))
                    .foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 22)
                    .frame(height: 48)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())
                if isPresented {
                    Button {
                        dismiss()
                    } label: {
                        Text("Go back")
                            .font(AppFont.jakarta(15, .bold))
                            .foregroundStyle(Theme.Colors.blue600)
                            .padding(.horizontal, 22)
                            .frame(height: 48)
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.blue600, lineWidth: 1.5))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .dashboardCard(radius: 18)
        .padding(.top, 24)
        .accessibilityElement(children: .contain)
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

// MARK: - Message card

/// One inbox row. Text cards expand inline; voice cards play inline (tap the card for the transcript).
private struct InboxMessageCard: View {
    let message: Message
    @Binding var nowPlayingID: String?
    let onOpen: () -> Void

    @State private var player: VoiceMessagePlayerViewModel
    @State private var isExpanded = false

    init(message: Message, nowPlayingID: Binding<String?>, onOpen: @escaping () -> Void) {
        self.message = message
        self._nowPlayingID = nowPlayingID
        self.onOpen = onOpen
        _player = State(initialValue: VoiceMessagePlayerViewModel(message: message))
    }

    private var isVoice: Bool { message.kind == .voice }

    var body: some View {
        let style = message.roleStyle
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggleExpanded) {
                HStack(alignment: .top, spacing: 12) {
                    InitialsAvatar(
                        initials: DashboardGreeting.initials(message.senderName),
                        size: 40,
                        foreground: style.avatarForeground,
                        background: style.avatarBackground
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        senderRow(style)
                        titleRow
                        if !isVoice {
                            Text(message.body)
                                .font(AppFont.jakarta(13))
                                .foregroundStyle(Theme.Colors.ink700)
                                .lineSpacing(isExpanded ? 3 : 0)
                                .lineLimit(isExpanded ? nil : 1)
                                .truncationMode(.tail)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: isExpanded)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityText)
            .accessibilityHint(isVoice
                               ? (isExpanded ? "Hide transcript" : "Show transcript")
                               : (isExpanded ? "Collapse" : "Expand to read"))

            if isVoice {
                playerPill
                    .padding(.leading, 66)
                    .padding(.trailing, 14)
                    .padding(.top, -4)
                    .padding(.bottom, 12)

                if isExpanded {
                    Text(message.body)
                        .font(AppFont.jakarta(13))
                        .foregroundStyle(Theme.Colors.ink700)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 66)
                        .padding(.trailing, 14)
                        .padding(.bottom, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.white, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(message.isUnread ? Theme.Colors.blueBorderLight : Theme.Colors.line,
                              lineWidth: message.isUnread ? 1.5 : 1)
        }
        .onChange(of: nowPlayingID) { _, newID in
            if newID != message.id, player.isPlaying { player.pause() }
        }
        .onDisappear { player.pause() }
    }

    private func senderRow(_ style: MessageRoleStyle) -> some View {
        HStack(spacing: 6) {
            Text(message.senderName)
                .font(AppFont.jakarta(13, .bold))
                .foregroundStyle(Theme.Colors.ink900)
                .lineLimit(1)
            if let role = message.senderRole {
                Text(role)
                    .font(AppFont.jakarta(12, .bold))
                    .foregroundStyle(style.pillForeground)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 1)
                    .background(style.pillBackground, in: Capsule())
                    .fixedSize()
            }
            Spacer(minLength: 0)
            Text(MessageFormat.timestamp(message.sentAt))
                .font(AppFont.jakarta(12))
                .foregroundStyle(Theme.Colors.ink500)
                .fixedSize()
        }
    }

    private var titleRow: some View {
        HStack(spacing: 6) {
            Image(systemName: isVoice ? "mic" : "bubble.left")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.blue600)
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)
            Text(message.title)
                .font(AppFont.jakarta(15, message.isUnread ? .heavy : .semibold))
                .foregroundStyle(Theme.Colors.ink900)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if message.isUnread {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Theme.Colors.blue600)
                        .frame(width: 9, height: 9)
                    Text("New")
                        .font(AppFont.jakarta(12, .heavy))
                        .foregroundStyle(Theme.Colors.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 1)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 6))
                }
                .fixedSize()
            }
        }
    }

    private var playerPill: some View {
        HStack(spacing: 12) {
            Button(action: togglePlay) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.Colors.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.blue600, in: Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(player.isPlaying ? "Pause \(message.title)" : "Play \(message.title)")

            GeometryReader { proxy in
                Capsule()
                    .fill(Theme.Colors.blue100)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Theme.Colors.blue600)
                            .frame(width: proxy.size.width * player.progress)
                    }
            }
            .frame(height: 6)
            .accessibilityHidden(true)

            Text(timeLabel)
                .font(AppFont.jakarta(13, .bold))
                .foregroundStyle(Theme.Colors.blue700)
                .monospacedDigit()
                .fixedSize()
        }
        .padding(.leading, 4)
        .padding(.trailing, 12)
        .padding(.vertical, 4)
        .background(Theme.Colors.blue50, in: Capsule())
    }

    private var timeLabel: String {
        (player.isPlaying || player.progress > 0)
            ? "\(player.elapsedLabel) / \(player.totalLabel)"
            : player.totalLabel
    }

    private var accessibilityText: String {
        let prefix = message.isUnread ? String(localized: "New. ") : ""
        let role = message.senderRole.map { ", \($0)" } ?? ""
        return prefix + String(localized: "\(message.title) from \(message.senderName)") + role
            + ", " + MessageFormat.timestamp(message.sentAt)
    }

    private func toggleExpanded() {
        if !isVoice, !isExpanded { onOpen() }
        withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
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

// MARK: - Loading

private struct InboxLoadingSkeleton: View {
    private let fill = Color(hex: 0xE9EDF3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 10).fill(fill).frame(width: 60, height: 14)
            ForEach(0..<4, id: \.self) { _ in
                HStack(alignment: .top, spacing: 12) {
                    Circle().fill(fill).frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 8) {
                        bar(height: 12, fraction: 0.5)
                        bar(height: 14, fraction: 0.85)
                        bar(height: 12, fraction: 0.7)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dashboardCard(radius: 16)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading messages")
    }

    private func bar(height: CGFloat, fraction: CGFloat) -> some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 10)
                .fill(fill)
                .frame(width: proxy.size.width * fraction)
        }
        .frame(height: height)
    }
}

// MARK: - Empty state

struct InboxEmptyState: View {
    enum Kind {
        case noMessages, caughtUp, noVoice, noText

        init(filter: MessageFilter) {
            switch filter {
            case .unread: self = .caughtUp
            case .voice: self = .noVoice
            case .text: self = .noText
            case .all: self = .noMessages
            }
        }
    }

    let kind: Kind

    private var content: (title: LocalizedStringKey, text: LocalizedStringKey, icon: String) {
        switch kind {
        case .noMessages: ("No messages yet", "Messages from your college will appear here", "bubble.left")
        case .caughtUp: ("You are all caught up", "No unread messages", "checkmark")
        case .noVoice: ("No voice messages", "Voice messages from your teachers will appear here", "mic")
        case .noText: ("No text messages", "Text messages from your college will appear here", "bubble.left")
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: content.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(kind == .caughtUp ? Theme.Colors.green600 : Theme.Colors.blue600)
                .frame(width: 72, height: 72)
                .background(kind == .caughtUp ? Theme.Colors.green50 : Theme.Colors.blue50, in: Circle())
                .accessibilityHidden(true)
            Text(content.title)
                .font(AppFont.jakarta(19, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
            Text(content.text)
                .font(AppFont.jakarta(14))
                .lineSpacing(3)
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
        .padding(.top, 32)
        .frame(maxWidth: .infinity)
    }
}

/// Kept for callers outside the inbox.
struct MessagesEmptyState: View {
    let filter: MessageFilter

    var body: some View {
        InboxEmptyState(kind: InboxEmptyState.Kind(filter: filter))
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
        messagingService: MockMessagingService(latency: .zero),
        attendanceService: MockAttendanceService(latency: .zero)
    )
    return NavigationStack {
        MessagesInboxView(role: .parent, initialFilter: .text)
    }
    .environment(AppRouter())
    .environment(deps)
    .environment(AuthSession.preview())
}
