//
//  PasswordPolicy.swift
//  Gradit
//

import Foundation

nonisolated enum PasswordStrength: Int, Comparable, Sendable {
    case empty = 0, weak, fair, strong, veryStrong

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

nonisolated struct PasswordEvaluation: Equatable, Sendable {
    var hasMinLength: Bool
    var hasMixedCase: Bool
    var hasNumberOrSymbol: Bool
    var matchesConfirmation: Bool
    var strength: PasswordStrength

    var isValid: Bool { hasMinLength && hasMixedCase && hasNumberOrSymbol && matchesConfirmation }
}

/// Rules shown on Create password. Keep in sync with the backend.
nonisolated enum PasswordPolicy {
    static let minLength = 8

    static func evaluate(_ password: String, confirmation: String) -> PasswordEvaluation {
        let hasMinLength = password.count >= minLength
        let hasMixedCase = password.contains(where: \.isUppercase) && password.contains(where: \.isLowercase)
        let hasNumberOrSymbol = password.contains { $0.isNumber || (!$0.isLetter && !$0.isWhitespace) }
        let matches = !password.isEmpty && password == confirmation

        let score = [hasMinLength, hasMixedCase, hasNumberOrSymbol, password.count >= 12].filter { $0 }.count
        let strength: PasswordStrength = password.isEmpty ? .empty : (PasswordStrength(rawValue: max(1, score)) ?? .weak)

        return PasswordEvaluation(
            hasMinLength: hasMinLength,
            hasMixedCase: hasMixedCase,
            hasNumberOrSymbol: hasNumberOrSymbol,
            matchesConfirmation: matches,
            strength: strength
        )
    }
}
