//
//  AuthTests.swift
//  GraditTests
//

import Foundation
import Testing
@testable import Gradit

@MainActor
struct AuthTests {

    private func makeSession(user: AuthUser = MockAuthService.demoUser, biometrics: BiometryKind = .none) -> AuthSession {
        AuthSession(
            service: MockAuthService(latency: .zero, user: user),
            apiClient: APIClient(baseURL: URL(string: "https://example.com")!),
            store: InMemorySecureStore(),
            biometrics: StubBiometrics(kind: biometrics),
            defaults: UserDefaults(suiteName: UUID().uuidString)!
        )
    }

    // MARK: Session

    @Test func multiRoleUserChoosesRoleAfterLogin() async throws {
        let session = makeSession()
        try await session.signIn(identifier: "9876543210", password: "password123", keepSignedIn: true)

        guard case .choosingRole = session.state else {
            Issue.record("Expected role selection, got \(session.state)")
            return
        }

        session.selectRole(.student, college: nil)
        #expect(session.currentRole == .student)
    }

    @Test func singleRoleUserGoesStraightIn() async throws {
        let user = AuthUser(id: "2", name: "Asha", maskedPhone: nil, maskedEmail: nil, roles: [.faculty], colleges: [])
        let session = makeSession(user: user)
        try await session.signIn(identifier: "asha", password: "password123", keepSignedIn: false)
        #expect(session.currentRole == .faculty)
    }

    @Test func wrongPasswordIsRejected() async {
        let session = makeSession()
        await #expect(throws: AuthError.invalidCredentials) {
            try await session.signIn(identifier: "9876543210", password: "123", keepSignedIn: true)
        }
        #expect(session.currentUser == nil)
    }

    @Test func signOutClearsUser() async throws {
        let session = makeSession()
        try await session.signIn(identifier: "9876543210", password: "password123", keepSignedIn: true)
        await session.signOut()
        #expect(session.state == .signedOut)
    }

    @Test func biometricLoginIsAvailableAfterPasswordLogin() async throws {
        let session = makeSession(biometrics: .faceID)
        try await session.signIn(identifier: "9876543210", password: "password123", keepSignedIn: true)
        await session.signOut()
        #expect(session.canUseBiometricLogin)
        let signedIn = try await session.signInWithBiometrics()
        #expect(signedIn)
    }

    // MARK: Password policy

    @Test func strongPasswordIsValid() {
        let result = PasswordPolicy.evaluate("Campus@2026", confirmation: "Campus@2026")
        #expect(result.isValid)
        #expect(result.strength == .strong)
    }

    @Test func mismatchedPasswordIsInvalid() {
        let result = PasswordPolicy.evaluate("Campus@2026", confirmation: "Campus@2025")
        #expect(!result.matchesConfirmation)
        #expect(!result.isValid)
    }

    @Test func weakPasswordFailsRules() {
        let result = PasswordPolicy.evaluate("abc", confirmation: "abc")
        #expect(!result.hasMinLength)
        #expect(!result.hasMixedCase)
        #expect(result.strength == .weak)
    }

    // MARK: OTP

    @Test func wrongCodeShowsError() async {
        let challenge = OTPChallenge(requestId: "1", channel: .sms, maskedDestination: "+91 ••••• •3210", resendAfter: 0)
        let viewModel = OTPVerifyViewModel(challenge: challenge, identifier: "x", service: MockAuthService(latency: .zero))
        viewModel.code = "000000"
        let token = await viewModel.verify()
        #expect(token == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func correctCodeReturnsResetToken() async {
        let challenge = OTPChallenge(requestId: "1", channel: .sms, maskedDestination: "+91 ••••• •3210", resendAfter: 0)
        let viewModel = OTPVerifyViewModel(challenge: challenge, identifier: "x", service: MockAuthService(latency: .zero))
        viewModel.code = "482913"
        let token = await viewModel.verify()
        #expect(token != nil)
    }
}
