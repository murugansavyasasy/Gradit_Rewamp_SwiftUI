//
//  NotificationModels.swift
//  Gradit
//
//  Payloads for the in-app Notifications screen (opened from the header bell).
//

import SwiftUI

nonisolated enum AppNotificationKind: String, Codable, Sendable {
    case notice, assignment, attendance, fee, exam, event, message, result, general

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AppNotificationKind(rawValue: raw) ?? .general
    }

    var systemImage: String {
        switch self {
        case .notice: "megaphone"
        case .assignment: "book.closed"
        case .attendance: "calendar.badge.checkmark"
        case .fee: "creditcard"
        case .exam: "doc.text"
        case .event: "calendar"
        case .message: "bubble.left"
        case .result: "chart.bar"
        case .general: "bell"
        }
    }

    var foreground: Color {
        switch self {
        case .attendance, .result: Theme.Colors.green700
        case .fee: Theme.Colors.amber800
        case .general: Theme.Colors.ink700
        default: Theme.Colors.blue600
        }
    }

    var background: Color {
        switch self {
        case .attendance, .result: Theme.Colors.green50
        case .fee: Theme.Colors.warningBackground
        case .general: Theme.Colors.surfaceMuted
        default: Theme.Colors.blue50
        }
    }
}

nonisolated struct AppNotification: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let message: String
    var kind: AppNotificationKind
    let date: Date
    var isRead: Bool
}
