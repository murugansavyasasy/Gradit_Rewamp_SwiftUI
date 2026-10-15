//
//  MessageComposeViewModel.swift
//  Gradit
//
//  Sender-side composer (faculty/management): one screen that switches between a
//  text message and a voice note, with audience, subject/caption and SMS options.
//  Design: 02 Management App › Text Msg / Voice Msg.
//

import Foundation
import Observation

enum MessageMode: String, CaseIterable, Identifiable {
    case text, voice
    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: String(localized: "Text")
        case .voice: String(localized: "Voice")
        }
    }

    var systemImage: String {
        switch self {
        case .text: "text.alignleft"
        case .voice: "mic"
        }
    }
}

/// Formatting buttons on the message editor toolbar (inserted as Markdown).
enum MessageFormatting {
    case bold, italic, bulletList, link
}

/// Ready-made text for the "Templates" menu.
struct MessageTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let subject: String
    let body: String
}

/// How prominently a text message is delivered.
enum MessagePriority: String, CaseIterable, Identifiable {
    case message, announcement, urgent
    var id: String { rawValue }

    var title: String {
        switch self {
        case .message: String(localized: "Message")
        case .announcement: String(localized: "Announcement")
        case .urgent: String(localized: "Urgent")
        }
    }
}

/// A selectable audience group (e.g. "Parents · CSE Sem 5 A").
struct MessageAudience: Identifiable, Hashable {
    let id: String
    let title: String
    let count: Int
}

@Observable
final class MessageComposeViewModel {
    var mode: MessageMode

    // Audience
    var selectedAudienceIDs: Set<String> = ["p-cse5a"]
    /// Text typed in the "Add class, student or parent" field.
    var recipientQuery = ""

    // Text
    var priority: MessagePriority = .message
    var subject = ""
    var text = ""
    private(set) var isBoldOn = false
    private(set) var isItalicOn = false
    private(set) var attachments: [String] = []
    var scheduleLater = false
    var scheduledDate = MessageComposeViewModel.defaultScheduleDate()
    static let maxTextLength = 1000

    // Voice (simulated recorder)
    var caption = ""
    private(set) var isRecording = false
    private(set) var hasRecording = false
    private(set) var elapsed = 0
    private(set) var isPreviewing = false
    private(set) var previewProgress: Double = 0   // 0...1

    // Shared
    var notifyBySMS = true
    private(set) var isSending = false
    private(set) var didSend = false
    var errorMessage: String?

    private var timerTask: Task<Void, Never>?
    private var previewTask: Task<Void, Never>?

    /// Demo audiences until the backend provides class/section lists.
    static let allAudiences: [MessageAudience] = [
        MessageAudience(id: "p-cse5a", title: "Parents · CSE Sem 5 A", count: 42),
        MessageAudience(id: "s-cse5a", title: "Students · CSE Sem 5 A", count: 43),
        MessageAudience(id: "p-cse5b", title: "Parents · CSE Sem 5 B", count: 40),
        MessageAudience(id: "all-staff", title: "All staff", count: 58),
    ]

    init(mode: MessageMode = .text) {
        self.mode = mode
    }

    var selectedAudiences: [MessageAudience] {
        Self.allAudiences.filter { selectedAudienceIDs.contains($0.id) }
    }

    var availableAudiences: [MessageAudience] {
        Self.allAudiences.filter { !selectedAudienceIDs.contains($0.id) }
    }

    var recipientCount: Int {
        selectedAudiences.reduce(0) { $0 + $1.count }
    }

    /// "parents" / "students" when every selected group is one kind, otherwise "people".
    var recipientNoun: String {
        let ids = selectedAudiences.map(\.id)
        if !ids.isEmpty, ids.allSatisfy({ $0.hasPrefix("p-") }) { return String(localized: "parents") }
        if !ids.isEmpty, ids.allSatisfy({ $0.hasPrefix("s-") }) { return String(localized: "students") }
        return String(localized: "people")
    }

    /// Audiences matching the "Add recipient" field (all available ones when it is empty).
    var suggestedAudiences: [MessageAudience] {
        let query = recipientQuery.trimmed.lowercased()
        guard !query.isEmpty else { return availableAudiences }
        return availableAudiences.filter { $0.title.lowercased().contains(query) }
    }

    func addAudience(_ audience: MessageAudience) {
        selectedAudienceIDs.insert(audience.id)
        recipientQuery = ""
    }

    func toggleAudience(_ audience: MessageAudience) {
        if selectedAudienceIDs.contains(audience.id) {
            selectedAudienceIDs.remove(audience.id)
        } else {
            selectedAudienceIDs.insert(audience.id)
        }
    }

    /// "00:34"
    var elapsedLabel: String {
        String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }

    static let templates: [MessageTemplate] = [
        MessageTemplate(id: "exam", title: String(localized: "Exam reminder"),
                        subject: String(localized: "Upcoming exam"),
                        body: String(localized: "Dear parents,\nThe exams begin soon. Please make sure your ward revises the units shared in class.")),
        MessageTemplate(id: "meeting", title: String(localized: "Parent-teacher meeting"),
                        subject: String(localized: "Parent-teacher meeting"),
                        body: String(localized: "Dear parents,\nA parent-teacher meeting is scheduled this week. Please confirm your attendance in the app.")),
        MessageTemplate(id: "holiday", title: String(localized: "Holiday notice"),
                        subject: String(localized: "Holiday notice"),
                        body: String(localized: "Dear parents,\nThe college will remain closed on the upcoming holiday. Classes resume the next working day.")),
    ]

    func apply(_ template: MessageTemplate) {
        if subject.trimmed.isEmpty { subject = template.subject }
        text = String(template.body.prefix(Self.maxTextLength))
    }

    // MARK: - Formatting & attachments

    func applyFormatting(_ formatting: MessageFormatting) {
        let insertion: String
        switch formatting {
        case .bold:
            insertion = "**"
            isBoldOn.toggle()
        case .italic:
            insertion = "_"
            isItalicOn.toggle()
        case .bulletList:
            insertion = (text.isEmpty || text.hasSuffix("\n")) ? "• " : "\n• "
        case .link:
            insertion = "[link](https://)"
        }
        guard text.count + insertion.count <= Self.maxTextLength else { return }
        text += insertion
    }

    func limitText() {
        if text.count > Self.maxTextLength { text = String(text.prefix(Self.maxTextLength)) }
    }

    func addAttachment(named name: String) {
        guard !attachments.contains(name) else { return }
        attachments.append(name)
    }

    func removeAttachment(named name: String) {
        attachments.removeAll { $0 == name }
    }

    /// Default send time: tomorrow at 8:00 AM.
    static func defaultScheduleDate(now: Date = .now, calendar: Calendar = .current) -> Date {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    private static let scheduleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM · h:mm a"
        return formatter
    }()

    /// Formatted send time when scheduling, otherwise "Sends immediately".
    var scheduleHint: String {
        scheduleLater ? Self.scheduleFormatter.string(from: scheduledDate) : String(localized: "Sends immediately")
    }

    var canSend: Bool {
        guard !isSending, !selectedAudiences.isEmpty else { return false }
        switch mode {
        case .text: return !subject.trimmed.isEmpty && !text.trimmed.isEmpty
        case .voice: return hasRecording && !isRecording
        }
    }

    // MARK: - Recording

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    func startRecording() {
        stopPreview()
        hasRecording = false
        elapsed = 0
        isRecording = true
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                self?.elapsed += 1
            }
        }
    }

    func stopRecording() {
        timerTask?.cancel()
        timerTask = nil
        isRecording = false
        hasRecording = elapsed > 0
    }

    func discardRecording() {
        stopPreview()
        timerTask?.cancel()
        timerTask = nil
        isRecording = false
        hasRecording = false
        elapsed = 0
    }

    // MARK: - Preview playback (simulated)

    func togglePreview() {
        isPreviewing ? stopPreview() : startPreview()
    }

    private func startPreview() {
        guard hasRecording, !isRecording else { return }
        if previewProgress >= 1 { previewProgress = 0 }
        isPreviewing = true
        let duration = Double(max(elapsed, 1))
        previewTask?.cancel()
        previewTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, self.isPreviewing else { break }
                self.previewProgress = min(1, self.previewProgress + 0.1 / duration)
                if self.previewProgress >= 1 { self.stopPreview() }
            }
        }
    }

    func stopPreview() {
        isPreviewing = false
        previewTask?.cancel()
        previewTask = nil
        if previewProgress >= 1 { previewProgress = 0 }
    }

    // MARK: - Send

    func send() async {
        guard canSend else { return }
        isSending = true
        defer { isSending = false }

        stopPreview()
        // Placeholder: simulate the network round-trip until a send API exists.
        try? await Task.sleep(for: .milliseconds(600))
        didSend = true
    }

    func reset() {
        discardRecording()
        subject = ""
        text = ""
        caption = ""
        recipientQuery = ""
        attachments = []
        isBoldOn = false
        isItalicOn = false
        scheduleLater = false
        scheduledDate = Self.defaultScheduleDate()
        previewProgress = 0
        didSend = false
        errorMessage = nil
    }
}
