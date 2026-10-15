//
//  AuthService.swift
//  Gradit
//

import Foundation

protocol AuthServiceProtocol {
    func login(identifier: String, password: String) async throws -> AuthResult
    func refresh(refreshToken: String) async throws -> AuthResult
    func resetOptions(for identifier: String) async throws -> [ResetOption]
    func sendResetCode(identifier: String, channel: OTPChannel) async throws -> OTPChallenge
    func verifyCode(_ code: String, challenge: OTPChallenge) async throws -> ResetToken
    func setPassword(_ password: String, resetToken: ResetToken) async throws -> AuthResult
    func logout() async
}

/// Live implementation. Paths and payloads are placeholders — align them with the backend.
final class AuthService: AuthServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func login(identifier: String, password: String) async throws -> AuthResult {
        try await mapErrors {
            try await client.send(.json("/auth/login", body: ["identifier": identifier, "password": password]))
        }
    }

    func refresh(refreshToken: String) async throws -> AuthResult {
        try await mapErrors {
            try await client.send(.json("/auth/refresh", body: ["refreshToken": refreshToken]))
        }
    }

    func resetOptions(for identifier: String) async throws -> [ResetOption] {
        try await mapErrors {
            try await client.send(.json("/auth/password/options", body: ["identifier": identifier]))
        }
    }

    func sendResetCode(identifier: String, channel: OTPChannel) async throws -> OTPChallenge {
        try await mapErrors {
            try await client.send(.json("/auth/password/forgot", body: ["identifier": identifier, "channel": channel.rawValue]))
        }
    }

    func verifyCode(_ code: String, challenge: OTPChallenge) async throws -> ResetToken {
        do {
            return try await client.send(.json("/auth/otp/verify", body: ["requestId": challenge.requestId, "code": code]))
        } catch APIError.httpStatus(let status) where [400, 401, 422].contains(status) {
            throw AuthError.invalidCode
        } catch APIError.httpStatus(429) {
            throw AuthError.tooManyAttempts
        }
    }

    func setPassword(_ password: String, resetToken: ResetToken) async throws -> AuthResult {
        try await mapErrors {
            try await client.send(.json("/auth/password/reset", body: ["resetToken": resetToken.token, "password": password]))
        }
    }

    func logout() async {
        _ = try? await client.sendRaw(Endpoint(path: "/auth/logout", method: .post))
    }

    private func mapErrors<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch APIError.httpStatus(401) {
            throw AuthError.invalidCredentials
        } catch APIError.httpStatus(404) {
            throw AuthError.accountNotFound
        } catch APIError.httpStatus(429) {
            throw AuthError.tooManyAttempts
        }
    }
}

/// In-memory backend for development, previews and tests.
/// - Any ID + a password of 6+ characters signs in.
/// - Code `000000` is rejected; any other 6 digits is accepted.
final class MockAuthService: AuthServiceProtocol {
    static let demoUser = AuthUser(
        id: "u-1001",
        name: "Rajesh Sharma",
        maskedPhone: "+91 ••••• •3210",
        maskedEmail: "pa•••••@gmail.com",
        roles: [.parent, .student, .faculty, .management],
        colleges: [College(id: "c-1", name: "University College of Engineering, Chennai", shortName: "UCE Chennai")]
    )

    var latency: Duration
    var user: AuthUser

    init(latency: Duration = .milliseconds(700), user: AuthUser = MockAuthService.demoUser) {
        self.latency = latency
        self.user = user
    }

    func login(identifier: String, password: String) async throws -> AuthResult {
        try await wait()
        guard !identifier.isBlank, password.count >= 6 else { throw AuthError.invalidCredentials }
        return makeResult()
    }

    func refresh(refreshToken: String) async throws -> AuthResult {
        try await wait()
        return makeResult()
    }

    func resetOptions(for identifier: String) async throws -> [ResetOption] {
        try await wait()
        guard !identifier.isBlank else { throw AuthError.accountNotFound }
        return [
            user.maskedPhone.map { ResetOption(channel: .sms, maskedDestination: $0) },
            user.maskedEmail.map { ResetOption(channel: .email, maskedDestination: $0) },
        ].compactMap { $0 }
    }

    func sendResetCode(identifier: String, channel: OTPChannel) async throws -> OTPChallenge {
        try await wait()
        let destination = (channel == .sms ? user.maskedPhone : user.maskedEmail) ?? ""
        return OTPChallenge(requestId: UUID().uuidString, channel: channel, maskedDestination: destination, resendAfter: 45)
    }

    func verifyCode(_ code: String, challenge: OTPChallenge) async throws -> ResetToken {
        try await wait()
        guard code.count == 6, code != "000000" else { throw AuthError.invalidCode }
        return ResetToken(token: UUID().uuidString)
    }

    func setPassword(_ password: String, resetToken: ResetToken) async throws -> AuthResult {
        try await wait()
        return makeResult()
    }

    func logout() async {}

    private func wait() async throws {
        try await Task.sleep(for: latency)
    }

    private func makeResult() -> AuthResult {
        AuthResult(
            user: user,
            tokens: AuthTokens(accessToken: UUID().uuidString, refreshToken: UUID().uuidString, expiresAt: .now.addingTimeInterval(3600))
        )
    }
}
