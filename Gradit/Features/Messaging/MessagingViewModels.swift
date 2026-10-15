//
//  MessagingViewModels.swift
//  Gradit
//

import Foundation
import Observation
internal import os

/// Messages inbox (text + voice), filterable, grouped by day. Parent accounts can
/// switch between linked students.
@Observable
final class MessagesInboxViewModel {
    let role: UserRole
    private(set) var messages: [Message] = []
    private(set) var students: [LinkedStudent] = []
    private(set) var selectedStudentID: LinkedStudent.ID?
    private(set) var isLoading = false
    var errorMessage: String?
    var filter: MessageFilter

    private let service: MessagingServiceProtocol

    init(role: UserRole, service: MessagingServiceProtocol, filter: MessageFilter = .all) {
        self.role = role
        self.service = service
        self.filter = filter
    }

    var isParent: Bool { role == .parent }
    var isStaff: Bool { role == .faculty || role == .management }

    var selectedStudent: LinkedStudent? {
        students.first { $0.id == selectedStudentID }
    }

    func count(for filter: MessageFilter) -> Int {
        messages.filter(filter.matches).count
    }

    /// Messages for the active filter, newest first, grouped into Today / Yesterday / Earlier.
    var sections: [(section: MessageSection, messages: [Message])] {
        let filtered = messages.filter(filter.matches).sorted { $0.sentAt > $1.sentAt }
        return MessageSection.allCases.compactMap { section in
            let items = filtered.filter { MessageFormat.section(for: $0.sentAt) == section }
            return items.isEmpty ? nil : (section, items)
        }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if isParent {
                if students.isEmpty { students = try await service.linkedStudents() }
                if selectedStudentID == nil { selectedStudentID = students.first?.id }
            }
            messages = try await service.messages(studentID: isParent ? selectedStudentID : nil)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Messages load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func select(_ student: LinkedStudent) async {
        guard student.id != selectedStudentID else { return }
        selectedStudentID = student.id
        messages = []
        await load()
    }

    var hasUnread: Bool { messages.contains { $0.isUnread } }

    /// "Mark all as read" from the header menu (optimistic).
    func markAllRead() {
        let unreadIDs = messages.filter(\.isUnread).map(\.id)
        guard !unreadIDs.isEmpty else { return }
        for index in messages.indices { messages[index].isUnread = false }
        Task { [service] in
            for id in unreadIDs { try? await service.markRead(id: id) }
        }
    }

    /// Mark a message read when it's opened (optimistic).
    func open(_ message: Message) {
        guard message.isUnread, let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        messages[index].isUnread = false
        Task { try? await service.markRead(id: message.id) }
    }
}

/// Playback state for the voice-message detail screen (simulated until real audio is wired).
@Observable
final class VoiceMessagePlayerViewModel {
    let message: Message
    private(set) var isPlaying = false
    private(set) var progress: Double = 0      // 0...1
    var speed: PlaybackSpeed = .normal
    var isTranscriptExpanded = true

    private var ticker: Task<Void, Never>?

    enum PlaybackSpeed: Double, CaseIterable {
        case normal = 1, oneHalf = 1.5, double = 2
        var label: String { self == .normal ? "1x" : (self == .oneHalf ? "1.5x" : "2x") }
    }

    init(message: Message) {
        self.message = message
    }

    private var duration: Double { Double(max(message.durationSeconds ?? 1, 1)) }

    var elapsedLabel: String {
        let seconds = Int(progress * duration)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var totalLabel: String { message.durationLabel }

    func togglePlay() {
        isPlaying ? pause() : play()
    }

    func play() {
        if progress >= 1 { progress = 0 }
        isPlaying = true
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, self.isPlaying else { break }
                let step = 0.1 * self.speed.rawValue / self.duration
                self.progress = min(1, self.progress + step)
                if self.progress >= 1 { self.pause() }
            }
        }
    }

    func pause() {
        isPlaying = false
        ticker?.cancel()
        ticker = nil
    }

    func skip(_ seconds: Double) {
        progress = min(1, max(0, progress + seconds / duration))
    }

    func cycleSpeed() {
        let all = PlaybackSpeed.allCases
        let next = (all.firstIndex(of: speed)! + 1) % all.count
        speed = all[next]
    }
}
