//
//  DiscussionModels.swift
//  Gradit
//
//  API payloads for the Discussion Board (threads and replies).
//

import SwiftUI

nonisolated enum DiscussionCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case announcements, academics, events, general

    var id: String { rawValue }

    var title: String {
        switch self {
        case .announcements: String(localized: "Announcements")
        case .academics: String(localized: "Academics")
        case .events: String(localized: "Events")
        case .general: String(localized: "General")
        }
    }

    /// Badge colour for the category chip.
    var tone: StatusBadge.Tone {
        switch self {
        case .announcements: .amber
        case .academics: .blueSoft
        case .events: .green
        case .general: .neutral
        }
    }

    /// Unknown values from the backend fall back to `.general` instead of failing to decode.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = DiscussionCategory(rawValue: raw) ?? .general
    }
}

nonisolated struct DiscussionThread: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let authorName: String
    var authorRole: String?
    var category: DiscussionCategory
    let title: String
    let body: String
    let createdAt: Date
    var replyCount: Int
    var likeCount: Int
    var isPinned: Bool
    var isLiked: Bool
}

nonisolated struct DiscussionReply: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let authorName: String
    var authorRole: String?
    let body: String
    let createdAt: Date
}

/// A thread with its replies, returned by the detail endpoint.
nonisolated struct DiscussionThreadDetail: Codable, Sendable {
    var thread: DiscussionThread
    var replies: [DiscussionReply]
}

enum DiscussionFormat {
    /// "2h ago", "3d ago", "just now".
    static func relative(_ date: Date, now: Date = .now) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
