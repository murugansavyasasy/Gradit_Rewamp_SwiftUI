//
//  MessageModels.swift
//  Gradit
//
//  Payloads for the Messages inbox (text + voice messages the college sends to
//  parents and students). Receiver side is read-only.
//

import SwiftUI

nonisolated enum MessageKind: String, Codable, Sendable {
    case text, voice

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = MessageKind(rawValue: raw) ?? .text
    }
}

nonisolated struct Message: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var kind: MessageKind
    let senderName: String
    var senderRole: String?
    let title: String
    /// Text body (text messages) or the voice-note transcript (voice messages).
    var body: String
    /// Voice note length in seconds.
    var durationSeconds: Int?
    let sentAt: Date
    var isUnread: Bool
}

extension Message {
    /// "0:12"
    var durationLabel: String {
        guard let seconds = durationSeconds else { return "" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// Stable avatar colour derived from the sender's name.
    var avatarForeground: Color { Self.palette[paletteIndex].0 }
    var avatarBackground: Color { Self.palette[paletteIndex].1 }

    private var paletteIndex: Int {
        let sum = senderName.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return sum % Self.palette.count
    }

    private static let palette: [(Color, Color)] = [
        (Theme.Colors.blue700, Theme.Colors.blue100),
        (Theme.Colors.green700, Theme.Colors.green100),
        (Theme.Colors.amber800, Theme.Colors.warningBackground),
        (Theme.Colors.red700, Theme.Colors.errorBackground),
    ]
}

/// Inbox filter chips.
nonisolated enum MessageFilter: String, CaseIterable, Identifiable, Sendable {
    case all, unread, text, voice
    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .unread: String(localized: "Unread")
        case .text: String(localized: "Text")
        case .voice: String(localized: "Voice")
        }
    }

    func matches(_ message: Message) -> Bool {
        switch self {
        case .all: true
        case .unread: message.isUnread
        case .text: message.kind == .text
        case .voice: message.kind == .voice
        }
    }
}

enum MessageFormat {
    private static let time: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()
    private static let dayMonth: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f
    }()

    /// Today → "12:13 PM", otherwise "1 Oct".
    static func timestamp(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        calendar.isDate(date, inSameDayAs: now) ? time.string(from: date) : dayMonth.string(from: date)
    }

    /// Section bucket for grouping.
    static func section(for date: Date, now: Date = .now, calendar: Calendar = .current) -> MessageSection {
        if calendar.isDate(date, inSameDayAs: now) { return .today }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) { return .yesterday }
        return .earlier
    }
}

enum MessageSection: Int, CaseIterable {
    case today, yesterday, earlier

    var title: String {
        switch self {
        case .today: String(localized: "Today")
        case .yesterday: String(localized: "Yesterday")
        case .earlier: String(localized: "Earlier")
        }
    }
}
