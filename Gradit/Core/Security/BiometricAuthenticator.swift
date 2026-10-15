//
//  BiometricAuthenticator.swift
//  Gradit
//

import Foundation
import LocalAuthentication
internal import os

enum BiometryKind {
    case none, touchID, faceID, opticID

    var displayName: String {
        switch self {
        case .none: ""
        case .touchID: "Touch ID"
        case .faceID: "Face ID"
        case .opticID: "Optic ID"
        }
    }

    var systemImage: String {
        switch self {
        case .none, .touchID: "touchid"
        case .faceID: "faceid"
        case .opticID: "opticid"
        }
    }
}

protocol BiometricAuthenticating {
    var kind: BiometryKind { get }
    func authenticate(reason: String) async -> Bool
}

/// Face ID / Touch ID via LocalAuthentication. Requires `NSFaceIDUsageDescription` (set in build settings).
final class BiometricAuthenticator: BiometricAuthenticating {
    var kind: BiometryKind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return .none }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .none
        }
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = String(localized: "Use password")
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            AppLogger.app.info("Biometric authentication ended: \(error.localizedDescription)")
            return false
        }
    }
}

/// Fixed result, for previews and tests.
struct StubBiometrics: BiometricAuthenticating {
    var kind: BiometryKind = .faceID
    var succeeds = true

    func authenticate(reason: String) async -> Bool { succeeds }
}
