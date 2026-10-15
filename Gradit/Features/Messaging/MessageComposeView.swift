//
//  MessageComposeView.swift
//  Gradit
//
//  Sender-side composer (faculty/management) opened from the Text Msg / Voice Msg
//  menu tiles. Text mode follows "Management › Text Msg" (ComposeText); voice mode
//  follows "Management › Voice Msg" (ComposeMessage). The mic button and the
//  Text / Voice tabs switch between them on the same screen.
//

import SwiftUI
import UniformTypeIdentifiers

struct MessageComposeView: View {
    @State private var viewModel: MessageComposeViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var isImportingFile = false

    private enum Field { case recipient, subject, body, caption }

    /// True when presented as a sheet (the top-bar button closes it), false when pushed.
    private let showsCancel: Bool

    init(mode: MessageMode = .text, showsCancel: Bool = false) {
        _viewModel = State(initialValue: MessageComposeViewModel(mode: mode))
        self.showsCancel = showsCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            MessagingTopBar(
                title: viewModel.mode == .voice ? String(localized: "Voice Msg") : String(localized: "Text Msg"),
                backIcon: showsCancel ? "xmark" : "chevron.left",
                onBack: { dismiss() }
            )

            if viewModel.didSend {
                sentState
            } else {
                composer
            }
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .keepsSwipeBack()
        .fileImporter(isPresented: $isImportingFile, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                urls.forEach { viewModel.addAttachment(named: $0.lastPathComponent) }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.mode)
        .animation(.easeInOut(duration: 0.2), value: viewModel.didSend)
    }

    // MARK: - Composer

    private var composer: some View {
        ScrollView {
            Group {
                if viewModel.mode == .text {
                    textForm
                } else {
                    voiceForm
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            bottomActions
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Theme.Colors.white)
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 10) {
            if viewModel.mode == .text {
                Button {
                    focusedField = nil
                    viewModel.mode = .voice
                } label: {
                    Image(systemName: "mic")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.Colors.green600)
                        .frame(width: 52, height: 52)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.green600, lineWidth: 1.5))
                        .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Switch to voice message")
            }
            sendButton
        }
    }

    private var sendTitle: String {
        if viewModel.scheduleLater { return String(localized: "Schedule message") }
        return String(localized: "Send to \(viewModel.recipientCount) \(viewModel.recipientNoun)")
    }

    private var sendButton: some View {
        Button {
            focusedField = nil
            Task { await viewModel.send() }
        } label: {
            ZStack {
                HStack(spacing: 10) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 16, weight: .semibold))
                    Text(sendTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .opacity(viewModel.isSending ? 0 : 1)
                if viewModel.isSending { ProgressView().tint(Theme.Colors.white) }
            }
            .font(AppFont.jakarta(16, .bold))
            .foregroundStyle(Theme.Colors.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!viewModel.canSend)
        .opacity(viewModel.canSend || viewModel.isSending ? 1 : 0.5)
    }

    // MARK: - Text form (ComposeText)

    private var textForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            sendAsSection
            recipientsSection
            subjectField
            messageEditor
            optionsCard
        }
    }

    private func fieldLabel(_ text: LocalizedStringKey, size: CGFloat = 13) -> some View {
        Text(text)
            .font(AppFont.jakarta(size, .semibold))
            .foregroundStyle(Theme.Colors.ink700)
    }

    private var sendAsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Send as")
            HStack(spacing: 8) {
                ForEach(MessagePriority.allCases) { priority in
                    let isOn = viewModel.priority == priority
                    Button {
                        viewModel.priority = priority
                    } label: {
                        Text(priority.title)
                            .font(AppFont.jakarta(14, isOn ? .bold : .semibold))
                            .foregroundStyle(isOn ? Theme.Colors.blue700 : Theme.Colors.ink700)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(isOn ? Theme.Colors.blue50 : Theme.Colors.white, in: .rect(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(isOn ? Theme.Colors.blue600 : Theme.Colors.border, lineWidth: isOn ? 2 : 1)
                            }
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? [.isSelected] : [])
                }
            }
        }
    }

    private var recipientsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("To")

            FlowLayout(spacing: 8) {
                ForEach(viewModel.selectedAudiences) { audience in
                    recipientChip(audience, showsCount: false)
                }
                TextField("Add class, student or parent", text: $viewModel.recipientQuery)
                    .font(AppFont.jakarta(14))
                    .foregroundStyle(Theme.Colors.ink900)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .recipient)
                    .submitLabel(.done)
                    .onSubmit {
                        if let first = viewModel.suggestedAudiences.first, !viewModel.recipientQuery.trimmed.isEmpty {
                            viewModel.addAudience(first)
                        }
                    }
                    .padding(.horizontal, 4)
                    .frame(width: recipientFieldWidth, height: 32)
                    .accessibilityLabel("Add recipient")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(Theme.Colors.white, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
            .contentShape(.rect)
            .onTapGesture { focusedField = .recipient }

            if focusedField == .recipient, !viewModel.suggestedAudiences.isEmpty {
                recipientSuggestions
            }

            if !viewModel.selectedAudiences.isEmpty {
                Text("\(viewModel.recipientCount) \(viewModel.recipientNoun) will receive this")
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
            }
        }
    }

    /// Fills the rest of a row like the design's `flex: 1; min-width: 120px` input.
    private var recipientFieldWidth: CGFloat {
        viewModel.selectedAudiences.isEmpty ? 300 : 200
    }

    private var recipientSuggestions: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.suggestedAudiences) { audience in
                Button {
                    viewModel.addAudience(audience)
                } label: {
                    HStack(spacing: 8) {
                        Text(audience.title)
                            .font(AppFont.jakarta(14, .semibold))
                            .foregroundStyle(Theme.Colors.ink900)
                        Spacer(minLength: 0)
                        Text("\(audience.count)")
                            .font(AppFont.jakarta(12))
                            .foregroundStyle(Theme.Colors.ink500)
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                if audience.id != viewModel.suggestedAudiences.last?.id {
                    Divider().overlay(Theme.Colors.divider)
                }
            }
        }
        .dashboardCard(radius: 14)
    }

    private func recipientChip(_ audience: MessageAudience, showsCount: Bool) -> some View {
        let isStudents = audience.id.hasPrefix("s-")
        let foreground = isStudents ? Theme.Colors.green700 : Theme.Colors.blue700
        let background = isStudents ? Theme.Colors.green50 : Theme.Colors.blue50
        return HStack(spacing: showsCount ? 6 : 4) {
            Text(showsCount ? "\(audience.title) (\(audience.count))" : audience.title)
                .font(AppFont.jakarta(13, .bold))
                .foregroundStyle(foreground)
                .lineLimit(1)
            Button {
                viewModel.toggleAudience(audience)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(foreground)
                    .frame(width: 24, height: 24)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(audience.title)")
        }
        .padding(.leading, 12)
        .padding(.trailing, showsCount ? 6 : 4)
        .frame(height: 32)
        .background(background, in: Capsule())
    }

    private var subjectField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Subject")
            TextField("What's this about?", text: $viewModel.subject)
                .font(AppFont.jakarta(15))
                .foregroundStyle(Theme.Colors.ink900)
                .textInputAutocapitalization(.sentences)
                .focused($focusedField, equals: .subject)
                .submitLabel(.next)
                .onSubmit { focusedField = .body }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .designFieldChrome(isFocused: focusedField == .subject, radius: 12)
                .contentShape(.rect)
                .onTapGesture { focusedField = .subject }
        }
    }

    private var messageEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Message")
            VStack(spacing: 0) {
                formattingToolbar
                Rectangle().fill(Theme.Colors.line).frame(height: 1)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.text)
                        .font(AppFont.jakarta(15))
                        .lineSpacing(3)
                        .foregroundStyle(Theme.Colors.ink900)
                        .scrollContentBackground(.hidden)
                        .focused($focusedField, equals: .body)
                        .frame(height: 156)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .onChange(of: viewModel.text) { viewModel.limitText() }
                    if viewModel.text.isEmpty {
                        Text("Write your message. Parents get it with a transcript.")
                            .font(AppFont.jakarta(15))
                            .foregroundStyle(Theme.Colors.ink500)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }

                Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                editorFooter
            }
            .designFieldChrome(isFocused: focusedField == .body, radius: 14)
        }
    }

    private var formattingToolbar: some View {
        HStack(spacing: 2) {
            formatButton(.bold, isOn: viewModel.isBoldOn, label: "Bold") {
                Text(verbatim: "B").font(AppFont.jakarta(15, .heavy))
            }
            formatButton(.italic, isOn: viewModel.isItalicOn, label: "Italic") {
                Text(verbatim: "I").font(AppFont.jakarta(15, .semibold)).italic()
            }
            formatButton(.bulletList, isOn: false, label: "Bulleted list") {
                Image(systemName: "list.bullet").font(.system(size: 16, weight: .medium))
            }
            formatButton(.link, isOn: false, label: "Insert link") {
                Image(systemName: "link").font(.system(size: 16, weight: .medium))
            }
            Spacer(minLength: 0)
            Menu {
                ForEach(MessageComposeViewModel.templates) { template in
                    Button(template.title) { viewModel.apply(template) }
                }
            } label: {
                Text("Templates")
                    .font(AppFont.jakarta(13, .bold))
                    .foregroundStyle(Theme.Colors.blue700)
                    .padding(.horizontal, 10)
                    .frame(height: 40)
                    .contentShape(.rect)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color(hex: 0xF7F9FC))
    }

    private func formatButton<Content: View>(
        _ formatting: MessageFormatting,
        isOn: Bool,
        label: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button {
            viewModel.applyFormatting(formatting)
            focusedField = .body
        } label: {
            content()
                .foregroundStyle(isOn ? Theme.Colors.blue700 : Theme.Colors.ink700)
                .frame(width: 44, height: 40)
                .background(isOn ? Theme.Colors.blue100 : .clear, in: .rect(cornerRadius: 8))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private var editorFooter: some View {
        HStack(spacing: 8) {
            if !viewModel.attachments.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.attachments, id: \.self) { name in
                            attachmentChip(name)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                focusedField = nil
                isImportingFile = true
            } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink700)
                    .frame(width: 40, height: 40)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Attach file")
            if viewModel.attachments.isEmpty { Spacer(minLength: 0) }
            Text(verbatim: "\(viewModel.text.count) / \(MessageComposeViewModel.maxTextLength)")
                .font(AppFont.jakarta(12))
                .foregroundStyle(Theme.Colors.ink500)
                .monospacedDigit()
                .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func attachmentChip(_ name: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "doc")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Colors.error)
            Text(name)
                .font(AppFont.jakarta(12, .semibold))
                .foregroundStyle(Theme.Colors.ink900)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 8))
        .contextMenu {
            Button("Remove", systemImage: "trash", role: .destructive) {
                viewModel.removeAttachment(named: name)
            }
        }
        .accessibilityLabel("Attachment \(name)")
    }

    private var optionsCard: some View {
        VStack(spacing: 0) {
            optionRow(title: "Also notify by SMS", hint: String(localized: "For parents without the app"),
                      isOn: $viewModel.notifyBySMS)
            optionRow(title: "Schedule for later", hint: viewModel.scheduleHint,
                      isOn: $viewModel.scheduleLater)
            if viewModel.scheduleLater {
                DatePicker("Send at",
                           selection: $viewModel.scheduledDate,
                           in: Date.now...,
                           displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .font(AppFont.jakarta(14, .semibold))
                    .foregroundStyle(Theme.Colors.ink900)
                    .tint(Theme.Colors.blue600)
                    .frame(minHeight: 52)
            }
        }
        .padding(.horizontal, 14)
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.line))
        .animation(.easeInOut(duration: 0.2), value: viewModel.scheduleLater)
    }

    private func optionRow(title: LocalizedStringKey, hint: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppFont.jakarta(14, .semibold))
                    .foregroundStyle(Theme.Colors.ink900)
                Text(hint)
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle(isOn: isOn) { Text(title) }
                .toggleStyle(DesignSwitchToggleStyle())
        }
        .frame(minHeight: 52)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
        }
    }

    // MARK: - Voice form (ComposeMessage)

    private var voiceForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            recipientsSection
            modeTabs
            recorderCard
            captionField
            optionsCard
        }
    }

    private var modeTabs: some View {
        HStack(spacing: 6) {
            ForEach(MessageMode.allCases) { mode in
                let isOn = viewModel.mode == mode
                Button {
                    focusedField = nil
                    viewModel.mode = mode
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 16, weight: .medium))
                        Text(mode.title)
                    }
                    .font(AppFont.jakarta(15, isOn ? .bold : .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.ink900 : Theme.Colors.ink500)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                    .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.1) : .clear, radius: 1.5, y: 1)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Message type")
    }

    private var recorderCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isRecording ? Theme.Colors.error : Theme.Colors.ink300)
                    .frame(width: 10, height: 10)
                Text(recorderStatus)
                    .font(AppFont.jakarta(13, .bold))
                    .foregroundStyle(viewModel.isRecording ? Theme.Colors.red700 : Theme.Colors.ink700)
                    .monospacedDigit()
            }

            RecorderWaveform(playedBars: playedBars)

            HStack(spacing: 28) {
                recorderSideButton(systemImage: "trash", color: Theme.Colors.ink700,
                                   label: "Delete recording",
                                   isEnabled: viewModel.hasRecording || viewModel.isRecording) {
                    viewModel.discardRecording()
                }

                Button {
                    viewModel.toggleRecording()
                } label: {
                    ZStack {
                        Circle().fill(viewModel.isRecording ? Theme.Colors.errorBackground : Theme.Colors.blue100)
                        Circle()
                            .fill(viewModel.isRecording ? Theme.Colors.error : Theme.Colors.blue600)
                            .padding(6)
                        if viewModel.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.Colors.white)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(Theme.Colors.white)
                        }
                    }
                    .frame(width: 72, height: 72)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(viewModel.isRecording ? "Stop recording" : "Start recording")

                recorderSideButton(systemImage: viewModel.isPreviewing ? "pause.fill" : "play.fill",
                                   color: Theme.Colors.blue600,
                                   label: viewModel.isPreviewing ? "Pause recording" : "Play recording",
                                   isEnabled: viewModel.hasRecording && !viewModel.isRecording) {
                    viewModel.togglePreview()
                }
            }

            Text("Up to 2 minutes. Receivers can replay it anytime.")
                .font(AppFont.jakarta(12))
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0xF7F9FE), in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.Colors.blue100))
    }

    private func recorderSideButton(systemImage: String, color: Color, label: LocalizedStringKey,
                                    isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(Theme.Colors.white, in: Circle())
                .overlay(Circle().strokeBorder(Theme.Colors.border))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }

    /// Bars drawn blue: grows while recording, follows playback while previewing.
    private var playedBars: Int {
        let total = RecorderWaveform.heights.count
        if viewModel.isRecording { return min(total, viewModel.elapsed + 1) }
        if viewModel.isPreviewing || viewModel.previewProgress > 0 {
            return Int((Double(total) * viewModel.previewProgress).rounded())
        }
        return viewModel.hasRecording ? min(total, viewModel.elapsed) : 0
    }

    private var recorderStatus: String {
        if viewModel.isRecording { return String(localized: "Recording · \(viewModel.elapsedLabel)") }
        if viewModel.hasRecording { return String(localized: "Recorded · \(viewModel.elapsedLabel)") }
        return String(localized: "Tap to record")
    }

    private var captionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Caption (optional)", size: 14)
            TextField("Add a short caption", text: $viewModel.caption)
                .font(AppFont.jakarta(15))
                .foregroundStyle(Theme.Colors.ink900)
                .textInputAutocapitalization(.sentences)
                .focused($focusedField, equals: .caption)
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .frame(height: 52)
                .designFieldChrome(isFocused: focusedField == .caption, radius: 12)
                .contentShape(.rect)
                .onTapGesture { focusedField = .caption }
        }
    }

    // MARK: - Sent

    private var sentTitle: String {
        if viewModel.scheduleLater {
            return String(localized: "Scheduled for \(viewModel.recipientCount) recipients")
        }
        return String(localized: "Sent to \(viewModel.recipientCount) recipients")
    }

    private var sentSubtitle: String {
        if viewModel.scheduleLater {
            return String(localized: "It will be sent \(viewModel.scheduleHint).")
        }
        return viewModel.mode == .voice
            ? String(localized: "Your voice note was delivered with a transcript.")
            : String(localized: "Your message was delivered with a transcript.")
    }

    private var sentState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.Colors.green700)
                .frame(width: 72, height: 72)
                .background(Theme.Colors.green50, in: Circle())
            Text(sentTitle)
                .font(AppFont.jakarta(18, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
                .multilineTextAlignment(.center)
            Text(sentSubtitle)
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
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recorder waveform

/// 36 bars, 4 pt wide with 3 pt gaps, in a 56 pt tall strip (blue = recorded / played).
private struct RecorderWaveform: View {
    static let heights: [CGFloat] = [10, 18, 28, 40, 22, 14, 32, 48, 36, 20, 12, 26, 44, 30, 16, 24, 38, 52,
                                     34, 18, 10, 22, 30, 14, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8]
    let playedBars: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(Self.heights.enumerated()), id: \.offset) { index, height in
                Capsule()
                    .fill(index < playedBars ? Theme.Colors.blue600 : Theme.Colors.ink300)
                    .frame(width: 4, height: height)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .animation(.easeOut(duration: 0.2), value: playedBars)
        .accessibilityHidden(true)
    }
}

#Preview("Text") {
    NavigationStack { MessageComposeView(mode: .text) }
}

#Preview("Voice") {
    NavigationStack { MessageComposeView(mode: .voice) }
}
