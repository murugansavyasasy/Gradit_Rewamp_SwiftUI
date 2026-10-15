//
//  MessageDetailView.swift
//  Gradit
//
//  Opens a message from the inbox: full text, or a voice note with a player and
//  transcript. Receiver side — read only.
//

import SwiftUI

struct MessageDetailView: View {
    let message: Message

    var body: some View {
        switch message.kind {
        case .text: TextMessageDetailView(message: message)
        case .voice: VoiceMessageDetailView(message: message)
        }
    }
}

// MARK: - Shared header

private struct MessageSenderHeader: View {
    let message: Message

    var body: some View {
        HStack(spacing: 12) {
            InitialsAvatar(
                initials: DashboardGreeting.initials(message.senderName),
                size: 44,
                foreground: message.avatarForeground,
                background: message.avatarBackground
            )
            VStack(alignment: .leading, spacing: 1) {
                Text(message.senderName)
                    .font(AppFont.jakarta(15, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                Text([message.senderRole, MessageFormat.timestamp(message.sentAt)].compactMap { $0 }.joined(separator: " · "))
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Text

private struct TextMessageDetailView: View {
    let message: Message
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MessageSenderHeader(message: message)
                Text(message.title)
                    .font(AppFont.jakarta(20, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message.body)
                    .font(AppFont.jakarta(15))
                    .foregroundStyle(Theme.Colors.ink700)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(radius: 16)
            .padding(16)
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle("Message")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Back") { dismiss() }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.Colors.white)
        }
    }
}

// MARK: - Voice

private struct VoiceMessageDetailView: View {
    @State private var model: VoiceMessagePlayerViewModel
    @Environment(\.dismiss) private var dismiss

    init(message: Message) {
        _model = State(initialValue: VoiceMessagePlayerViewModel(message: message))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                playerCard
                transcriptCard
            }
            .padding(16)
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle("Message")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Back") { dismiss() }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.Colors.white)
        }
        .onDisappear { model.pause() }
    }

    private var playerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            MessageSenderHeader(message: model.message)

            Text(model.message.title)
                .font(AppFont.jakarta(18, .heavy))
                .foregroundStyle(Theme.Colors.ink900)

            VoiceWaveform(progress: model.progress, height: 44)

            HStack {
                Text(model.elapsedLabel)
                Spacer()
                Text(model.totalLabel)
            }
            .font(AppFont.jakarta(12, .semibold))
            .foregroundStyle(Theme.Colors.ink500)
            .monospacedDigit()

            HStack {
                Button {
                    model.cycleSpeed()
                } label: {
                    Text(model.speed.label)
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 52, height: 40)
                        .background(Theme.Colors.surfaceMuted, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Playback speed \(model.speed.label)")

                Spacer()

                HStack(spacing: 20) {
                    skipButton(seconds: -10, systemImage: "gobackward.10")
                    Button {
                        model.togglePlay()
                    } label: {
                        Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.Colors.white)
                            .frame(width: 64, height: 64)
                            .background(Theme.Colors.blue600, in: Circle())
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel(model.isPlaying ? "Pause" : "Play")
                    skipButton(seconds: 10, systemImage: "goforward.10")
                }

                Spacer()
                Color.clear.frame(width: 52, height: 40)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 18)
    }

    private func skipButton(seconds: Double, systemImage: String) -> some View {
        Button {
            model.skip(seconds)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink700)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(seconds < 0 ? "Back 10 seconds" : "Forward 10 seconds")
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { model.isTranscriptExpanded.toggle() }
            } label: {
                HStack {
                    Text("Transcript")
                        .font(AppFont.jakarta(14, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Spacer()
                    Image(systemName: model.isTranscriptExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if model.isTranscriptExpanded {
                Text(model.message.body)
                    .font(AppFont.jakarta(14))
                    .foregroundStyle(Theme.Colors.ink700)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }
}

#Preview("Voice") {
    NavigationStack {
        MessageDetailView(message: Message(
            id: "1", kind: .voice, senderName: "Dr. K. Suresh", senderRole: "Principal",
            title: "Holiday announcement",
            body: "College will remain closed on 2 October for the public holiday. Classes resume on 3 October as usual.",
            durationSeconds: 12, sentAt: .now, isUnread: true
        ))
    }
}

#Preview("Text") {
    NavigationStack {
        MessageDetailView(message: Message(
            id: "2", kind: .text, senderName: "Controller of Exams", senderRole: "Exam Cell",
            title: "Mid-semester exam timetable",
            body: "UG exams run from 12 to 17 Oct. Download the full timetable from the Exams section and check your hall-ticket details.",
            durationSeconds: nil, sentAt: .now, isUnread: true
        ))
    }
}
