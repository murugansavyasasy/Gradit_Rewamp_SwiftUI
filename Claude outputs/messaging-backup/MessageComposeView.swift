//
//  MessageComposeView.swift
//  Gradit
//
//  Sender-side composer (faculty/management). One screen, Text / Voice switch:
//  choose recipients, then send a text message or record a voice note.
//  Design: 02 Management App › Text Msg / Voice Msg.
//

import SwiftUI

struct MessageComposeView: View {
    @State private var viewModel: MessageComposeViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field { case subject, body, caption }

    /// Shows a Cancel button — true when presented as a sheet, false when pushed (uses the back button).
    private let showsCancel: Bool

    init(mode: MessageMode = .text, showsCancel: Bool = false) {
        _viewModel = State(initialValue: MessageComposeViewModel(mode: mode))
        self.showsCancel = showsCancel
    }

    var body: some View {
        Group {
            if viewModel.didSend {
                sentState
            } else {
                composer
            }
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .navigationTitle(viewModel.mode == .voice ? "Voice Msg" : "Text Msg")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCancel {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.font(AppFont.jakarta(15))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.mode)
        .animation(.easeInOut(duration: 0.2), value: viewModel.didSend)
    }

    // MARK: - Composer

    private var composer: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                recipientsSection
                modeSwitch

                if viewModel.mode == .text {
                    prioritySection
                    AppTextField(label: "Subject", text: $viewModel.subject,
                                 placeholder: "What's this about?", capitalization: .sentences)
                        .focused($focusedField, equals: .subject)
                    messageEditor
                } else {
                    recorderCard
                    AppTextField(label: "Caption (optional)", text: $viewModel.caption,
                                 placeholder: "Add a short caption", capitalization: .sentences)
                        .focused($focusedField, equals: .caption)
                }

                smsToggle
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: viewModel.mode == .voice ? "Send voice note" : "Send message",
                style: viewModel.mode == .voice ? .success : .primary,
                isLoading: viewModel.isSending,
                isEnabled: viewModel.canSend
            ) {
                focusedField = nil
                Task { await viewModel.send() }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(Theme.Colors.white)
        }
    }

    // MARK: - Recipients

    private var recipientsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("To")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.ink700)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.selectedAudiences) { audience in
                    recipientChip(audience)
                }
                if !viewModel.availableAudiences.isEmpty {
                    Menu {
                        ForEach(viewModel.availableAudiences) { audience in
                            Button("\(audience.title) (\(audience.count))") {
                                viewModel.toggleAudience(audience)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .font(AppFont.jakarta(12, .bold))
                        .foregroundStyle(Theme.Colors.blue600)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .overlay(Capsule().strokeBorder(Theme.Colors.blueBorder))
                    }
                }
            }

            if !viewModel.selectedAudiences.isEmpty {
                Text("\(viewModel.recipientCount) recipients will receive this")
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
            }
        }
    }

    private func recipientChip(_ audience: MessageAudience) -> some View {
        HStack(spacing: 6) {
            Text("\(audience.title) (\(audience.count))")
                .font(AppFont.jakarta(12, .bold))
                .foregroundStyle(Theme.Colors.blue700)
            Button {
                viewModel.toggleAudience(audience)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.Colors.blue700)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(audience.title)")
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Theme.Colors.blue50, in: Capsule())
    }

    // MARK: - Mode switch

    private var modeSwitch: some View {
        HStack(spacing: 4) {
            ForEach(MessageMode.allCases) { mode in
                let isOn = viewModel.mode == mode
                Button {
                    focusedField = nil
                    viewModel.mode = mode
                } label: {
                    Label(mode.title, systemImage: mode.systemImage)
                        .font(AppFont.jakarta(14, .bold))
                        .foregroundStyle(isOn ? Theme.Colors.blue600 : Theme.Colors.ink500)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(isOn ? Theme.Colors.white : .clear, in: Capsule())
                        .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Theme.Colors.surfaceMuted, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.Colors.line))
    }

    // MARK: - Text

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Send as")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.ink700)
            HStack(spacing: 8) {
                ForEach(MessagePriority.allCases) { priority in
                    let isOn = viewModel.priority == priority
                    Button(priority.title) { viewModel.priority = priority }
                        .font(AppFont.jakarta(13, isOn ? .bold : .semibold))
                        .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isOn ? [.isSelected] : [])
                }
            }
        }
    }

    private var messageEditor: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Message")
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Colors.ink700)
                Spacer()
                Text("\(viewModel.text.count)/1000")
                    .font(AppFont.jakarta(11))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.text)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.ink900)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .body)
                    .frame(minHeight: 150, alignment: .topLeading)
                    .padding(10)
                if viewModel.text.isEmpty {
                    Text("Write your message. Parents get it with a transcript.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.ink500)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            .background(Theme.Colors.white, in: .rect(cornerRadius: Theme.Radius.input))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.input).strokeBorder(Theme.Colors.border))
        }
    }

    // MARK: - Voice recorder

    private var recorderCard: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isRecording ? Theme.Colors.error : Theme.Colors.ink300)
                        .frame(width: 10, height: 10)
                    Text(recorderStatus)
                        .font(AppFont.jakarta(14, .heavy))
                        .foregroundStyle(viewModel.isRecording ? Theme.Colors.red700 : Theme.Colors.ink700)
                }
                Spacer()
                StatusBadge(text: "To \(viewModel.recipientCount)", tone: .blueSoft)
            }

            VoiceWaveform(progress: viewModel.isRecording ? 1 : (viewModel.hasRecording ? 0.5 : 0), height: 40)

            HStack(spacing: 24) {
                Button {
                    viewModel.discardRecording()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 48, height: 48)
                        .overlay(Circle().strokeBorder(Theme.Colors.border))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(!viewModel.hasRecording && !viewModel.isRecording)
                .opacity((viewModel.hasRecording || viewModel.isRecording) ? 1 : 0.4)
                .accessibilityLabel("Discard recording")

                Button {
                    viewModel.toggleRecording()
                } label: {
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Theme.Colors.white)
                        .frame(width: 72, height: 72)
                        .background(viewModel.isRecording ? Theme.Colors.error : Theme.Colors.blue600, in: Circle())
                        .padding(6)
                        .background(viewModel.isRecording ? Theme.Colors.errorBackground : Theme.Colors.blue100, in: Circle())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(viewModel.isRecording ? "Stop recording" : "Start recording")

                Color.clear.frame(width: 48, height: 48)
            }

            Text("Up to 2 minutes. Receivers can replay it anytime.")
                .font(AppFont.jakarta(12))
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .dashboardCard(radius: 18)
    }

    private var recorderStatus: String {
        if viewModel.isRecording { return "Recording · \(viewModel.elapsedLabel)" }
        if viewModel.hasRecording { return "Recorded · \(viewModel.elapsedLabel)" }
        return String(localized: "Tap to record")
    }

    // MARK: - SMS toggle

    private var smsToggle: some View {
        Toggle(isOn: $viewModel.notifyBySMS) {
            Text("Also notify by SMS")
                .font(AppFont.jakarta(14, .semibold))
                .foregroundStyle(Theme.Colors.ink900)
        }
        .toggleStyle(CheckboxToggleStyle())
    }

    // MARK: - Sent

    private var sentState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.Colors.green700)
                .frame(width: 72, height: 72)
                .background(Theme.Colors.green50, in: Circle())
            Text("Sent to \(viewModel.recipientCount) recipients")
                .font(AppFont.jakarta(18, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
                .multilineTextAlignment(.center)
            Text(viewModel.mode == .voice
                 ? "Your voice note was delivered with a transcript."
                 : "Your message was delivered with a transcript.")
                .font(AppFont.jakarta(14))
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: "New message", style: .secondary) { viewModel.reset() }
                .padding(.horizontal, 20)
            Button("Done") { dismiss() }
                .font(AppFont.jakarta(15, .bold))
                .foregroundStyle(Theme.Colors.blue600)
                .padding(.bottom, 8)
        }
        .padding(.vertical, 8)
    }
}

#Preview("Text") {
    NavigationStack { MessageComposeView(mode: .text, showsCancel: true) }
}

#Preview("Voice") {
    NavigationStack { MessageComposeView(mode: .voice, showsCancel: true) }
}
