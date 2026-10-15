//
//  OTPVerifyViewModel.swift
//  Gradit
//

import Foundation
import Observation

@Observable
final class OTPVerifyViewModel {
    static let codeLength = 6

    var code = ""
    var errorMessage: String?
    private(set) var challenge: OTPChallenge
    private(set) var secondsRemaining: Int
    private(set) var isVerifying = false
    private(set) var isResending = false

    let identifier: String
    private let service: AuthServiceProtocol
    private var countdownTask: Task<Void, Never>?

    init(challenge: OTPChallenge, identifier: String, service: AuthServiceProtocol) {
        self.challenge = challenge
        self.identifier = identifier
        self.service = service
        self.secondsRemaining = challenge.resendAfter
    }

    var isComplete: Bool { code.count == Self.codeLength }
    var canResend: Bool { secondsRemaining == 0 && !isResending }
    var countdownText: String { String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60) }

    func startCountdown() {
        countdownTask?.cancel()
        secondsRemaining = challenge.resendAfter
        countdownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled, self.secondsRemaining > 0 else { return }
                self.secondsRemaining -= 1
            }
        }
    }

    func stopCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    func verify() async -> ResetToken? {
        guard isComplete, !isVerifying else { return nil }
        isVerifying = true
        errorMessage = nil
        defer { isVerifying = false }

        do {
            return try await service.verifyCode(code, challenge: challenge)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func resend() async {
        guard canResend else { return }
        isResending = true
        defer { isResending = false }

        do {
            challenge = try await service.sendResetCode(identifier: identifier, channel: challenge.channel)
            code = ""
            errorMessage = nil
            startCountdown()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
