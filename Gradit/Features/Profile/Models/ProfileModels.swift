//
//  ProfileModels.swift
//  Gradit
//

import Foundation

/// The signed-in person's editable profile (Profile › Edit profile).
nonisolated struct UserProfile: Codable, Equatable, Sendable {
    var fullName: String
    /// Registered with the college; read-only in the app.
    var mobile: String?
    var email: String?
    /// "yyyy-MM-dd" as sent by the API.
    var dateOfBirth: String?
    /// Line under the role badge, e.g. "Parent of Aarav Sharma · B.E. CSE".
    var summary: String?
    var photoURL: URL?

    nonisolated(unsafe) private static let isoDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var birthDate: Date? {
        get { dateOfBirth.flatMap { Self.isoDay.date(from: $0) } }
        set { dateOfBirth = newValue.map { Self.isoDay.string(from: $0) } }
    }
}

/// Notification settings switches, in the design's order.
nonisolated struct NotificationPreferences: Codable, Equatable, Sendable {
    var attendance: Bool
    var fees: Bool
    var exams: Bool
    var bus: Bool
    var messages: Bool

    static let defaults = NotificationPreferences(attendance: true, fees: true, exams: true, bus: false, messages: true)
}

nonisolated enum ProfileError: LocalizedError, Equatable, Sendable {
    case wrongCurrentPassword
    case invalidEmail
    case emptyName

    var errorDescription: String? {
        switch self {
        case .wrongCurrentPassword: String(localized: "Your current password isn’t right.")
        case .invalidEmail: String(localized: "Enter a valid email address.")
        case .emptyName: String(localized: "Enter your full name.")
        }
    }
}
