//
//  AuthModels.swift
//  Gradit
//

import Foundation

nonisolated enum UserRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case parent
    case student
    case faculty
    case management

    var id: String { rawValue }
}

nonisolated struct College: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// e.g. "UCE Chennai" — shown in the dashboard header when present.
    var shortName: String? = nil
}

nonisolated struct AuthUser: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let maskedPhone: String?
    let maskedEmail: String?
    let roles: [UserRole]
    let colleges: [College]
}

nonisolated struct AuthTokens: Codable, Hashable, Sendable {
    let accessToken: String
    let refreshToken: String
    var expiresAt: Date?
}

nonisolated struct AuthResult: Codable, Sendable {
    let user: AuthUser
    let tokens: AuthTokens
}

nonisolated enum OTPChannel: String, Codable, Hashable, Sendable {
    case sms
    case email
}

/// Where a reset code can be sent (masked by the server).
nonisolated struct ResetOption: Codable, Identifiable, Hashable, Sendable {
    let channel: OTPChannel
    let maskedDestination: String

    var id: OTPChannel { channel }
}

nonisolated struct OTPChallenge: Codable, Hashable, Sendable {
    let requestId: String
    let channel: OTPChannel
    let maskedDestination: String
    /// Seconds before "Resend" is enabled.
    let resendAfter: Int
}

nonisolated struct ResetToken: Codable, Hashable, Sendable {
    let token: String
}

nonisolated enum AuthError: LocalizedError, Equatable, Sendable {
    case invalidCredentials
    case accountNotFound
    case invalidCode
    case tooManyAttempts
    case noRoleAssigned

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: String(localized: "That ID and password don’t match. Check and try again.")
        case .accountNotFound: String(localized: "We couldn’t find an account with that mobile number, email or ID.")
        case .invalidCode: String(localized: "That code isn’t right or has expired. Try again or resend it.")
        case .tooManyAttempts: String(localized: "Too many attempts. Please wait a few minutes and try again.")
        case .noRoleAssigned: String(localized: "Your account isn’t linked to a role yet. Please contact the college office.")
        }
    }
}
