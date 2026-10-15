//
//  AuthSession.swift
//  Gradit
//

import Foundation
import Observation
internal import os

/// Single source of truth for who is signed in. Injected via `.environment(session)`.
///
/// Flow: signedOut → (login | password reset | biometrics) → choosingRole (if 2+ roles) → signedIn
@Observable
final class AuthSession {
    enum State: Equatable {
        case restoring
        case signedOut
        case choosingRole(AuthUser)
        case signedIn(AuthUser, role: UserRole, college: College?)
    }

    private(set) var state: State = .restoring
    private(set) var hasBiometricLogin = false

    private let service: AuthServiceProtocol
    private let apiClient: APIClient
    private let store: SecureStore
    private let biometrics: BiometricAuthenticating
    private let defaults: UserDefaults
    private var tokens: AuthTokens?

    enum Keys {
        static let tokens = "auth.tokens"
        static let biometricToken = "auth.biometricRefreshToken"
        static let lastRole = "auth.lastRole"
        static let lastCollege = "auth.lastCollege"
    }

    init(
        service: AuthServiceProtocol,
        apiClient: APIClient,
        store: SecureStore = KeychainStore(),
        biometrics: BiometricAuthenticating = BiometricAuthenticator(),
        defaults: UserDefaults = .standard
    ) {
        self.service = service
        self.apiClient = apiClient
        self.store = store
        self.biometrics = biometrics
        self.defaults = defaults
        self.hasBiometricLogin = store.data(for: Keys.biometricToken) != nil
    }

    // MARK: - Derived state

    var biometryKind: BiometryKind { biometrics.kind }

    var canUseBiometricLogin: Bool { hasBiometricLogin && biometryKind != .none }

    var currentUser: AuthUser? {
        switch state {
        case .choosingRole(let user), .signedIn(let user, _, _): user
        case .restoring, .signedOut: nil
        }
    }

    var currentRole: UserRole? {
        if case .signedIn(_, let role, _) = state { role } else { nil }
    }

    var currentCollege: College? {
        if case .signedIn(_, _, let college) = state { college } else { nil }
    }

    var preferredRole: UserRole? {
        defaults.string(forKey: Keys.lastRole).flatMap(UserRole.init(rawValue:))
    }

    // MARK: - Sign in

    /// Called once at launch. Restores a "Keep me signed in" session from the Keychain.
    func restore() async {
        guard let saved = store.value(AuthTokens.self, for: Keys.tokens) else {
            state = .signedOut
            return
        }
        do {
            let result = try await service.refresh(refreshToken: saved.refreshToken)
            try apply(result, persist: true, resumeLastRole: true)
        } catch {
            AppLogger.app.error("Session restore failed: \(error.localizedDescription)")
            store.removeValue(for: Keys.tokens)
            state = .signedOut
        }
    }

    func signIn(identifier: String, password: String, keepSignedIn: Bool) async throws {
        let result = try await service.login(identifier: identifier.trimmed, password: password)
        try apply(result, persist: keepSignedIn, resumeLastRole: false)
        enableBiometricLogin(refreshToken: result.tokens.refreshToken)
    }

    /// Returns false when the user cancels the Face ID / Touch ID prompt.
    @discardableResult
    func signInWithBiometrics() async throws -> Bool {
        guard canUseBiometricLogin,
              let data = store.data(for: Keys.biometricToken),
              let refreshToken = String(data: data, encoding: .utf8)
        else { return false }

        guard await biometrics.authenticate(reason: String(localized: "Sign in to your college account")) else {
            return false
        }

        do {
            let result = try await service.refresh(refreshToken: refreshToken)
            try apply(result, persist: true, resumeLastRole: false)
            enableBiometricLogin(refreshToken: result.tokens.refreshToken)
            return true
        } catch {
            disableBiometricLogin()
            throw error
        }
    }

    /// Final step of Forgot password → OTP → Create password.
    func completePasswordReset(with result: AuthResult) throws {
        try apply(result, persist: true, resumeLastRole: false)
        enableBiometricLogin(refreshToken: result.tokens.refreshToken)
    }

    // MARK: - Role

    func selectRole(_ role: UserRole, college: College?) {
        guard let user = currentUser, user.roles.contains(role) else { return }
        defaults.set(role.rawValue, forKey: Keys.lastRole)
        defaults.set(college?.id, forKey: Keys.lastCollege)
        state = .signedIn(user, role: role, college: college)
    }

    func switchRole() {
        guard let user = currentUser, user.roles.count > 1 else { return }
        state = .choosingRole(user)
    }

    // MARK: - Sign out

    func signOut() async {
        state = .signedOut
        await service.logout()
        tokens = nil
        apiClient.authToken = nil
        store.removeValue(for: Keys.tokens)
    }

    /// Removes saved tokens without calling the server. Used on a fresh install.
    func forgetStoredCredentials() {
        tokens = nil
        apiClient.authToken = nil
        store.removeValue(for: Keys.tokens)
        disableBiometricLogin()
    }

    func disableBiometricLogin() {
        store.removeValue(for: Keys.biometricToken)
        hasBiometricLogin = false
    }

    // MARK: - Private

    private func enableBiometricLogin(refreshToken: String) {
        guard biometrics.kind != .none else { return }
        do {
            try store.setData(Data(refreshToken.utf8), for: Keys.biometricToken)
            hasBiometricLogin = true
        } catch {
            AppLogger.app.error("Couldn't save biometric token: \(error.localizedDescription)")
        }
    }

    private func apply(_ result: AuthResult, persist: Bool, resumeLastRole: Bool) throws {
        let user = result.user
        guard !user.roles.isEmpty else { throw AuthError.noRoleAssigned }

        tokens = result.tokens
        apiClient.authToken = result.tokens.accessToken

        if persist {
            try? store.setValue(result.tokens, for: Keys.tokens)
        } else {
            store.removeValue(for: Keys.tokens)
        }

        let lastCollegeID = defaults.string(forKey: Keys.lastCollege)
        let college = user.colleges.first { $0.id == lastCollegeID } ?? user.colleges.first

        if user.roles.count == 1 {
            state = .signedIn(user, role: user.roles[0], college: college)
        } else if resumeLastRole, let role = preferredRole, user.roles.contains(role) {
            state = .signedIn(user, role: role, college: college)
        } else {
            state = .choosingRole(user)
        }
    }
}

extension AuthSession {
    /// Session backed by mocks, for SwiftUI previews.
    static func preview(biometrics: BiometryKind = .faceID, hasBiometricLogin: Bool = false) -> AuthSession {
        let store = InMemorySecureStore()
        if hasBiometricLogin {
            try? store.setData(Data("preview".utf8), for: Keys.biometricToken)
        }
        return AuthSession(
            service: MockAuthService(latency: .milliseconds(400)),
            apiClient: APIClient(baseURL: AppConfig.baseURL),
            store: store,
            biometrics: StubBiometrics(kind: biometrics),
            defaults: UserDefaults(suiteName: "preview") ?? .standard
        )
    }
}
