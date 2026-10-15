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
        case .text: "text.bubble"
        case .voice: "mic"
        }
    }
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

    // Text
    var priority: MessagePriority = .message
    var subject = ""
    var text = ""

    // Voice (simulated recorder)
    var caption = ""
    private(set) var isRecording = false
    private(set) var hasRecording = false
    private(set) var elapsed = 0

    // Shared
    var notifyBySMS = true
    private(set) var isSending = false
    private(set) var didSend = false
    var errorMessage: String?

    private var timerTask: Task<Void, Never>?

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

    func toggleAudience(_ audience: MessageAudience) {
        if selectedAudienceIDs.contains(audience.id) {
            selectedAudienceIDs.remove(audience.id)
        } else {
            selectedAudienceIDs.insert(audience.id)
        }
    }

    /// "0:34"
    var elapsedLabel: String {
        String(format: "%d:%02d", elapsed / 60, elapsed % 60)
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
        timerTask?.cancel()
        timerTask = nil
        isRecording = false
        hasRecording = false
        elapsed = 0
    }

    // MARK: - Send

    func send() async {
        guard canSend else { return }
        isSending = true
        defer { isSending = false }

        // Placeholder: simulate the network round-trip until a send API exists.
        try? await Task.sleep(for: .milliseconds(600))
        didSend = true
    }

    func reset() {
        discardRecording()
        subject = ""
        text = ""
        caption = ""
        didSend = false
        errorMessage = nil
    }
}
