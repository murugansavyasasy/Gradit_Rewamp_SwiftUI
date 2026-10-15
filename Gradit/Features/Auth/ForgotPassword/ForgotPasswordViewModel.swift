//
//  ForgotPasswordViewModel.swift
//  Gradit
//

import Foundation
import Observation

@Observable
final class ForgotPasswordViewModel {
    var identifier: String
    var selectedChannel: OTPChannel = .sms
    var errorMessage: String?
    private(set) var options: [ResetOption] = []
    private(set) var isLoadingOptions = false
    private(set) var isSending = false

    private let service: AuthServiceProtocol

    init(identifier: String, service: AuthServiceProtocol) {
        self.identifier = identifier
        self.service = service
    }

    var hasOptions: Bool { !options.isEmpty }
    var canContinue: Bool { !identifier.isBlank && !isLoadingOptions }

    /// Looks up the masked phone/email for the account.
    func loadOptions() async {
        guard !identifier.isBlank else { return }
        isLoadingOptions = true
        errorMessage = nil
        defer { isLoadingOptions = false }

        do {
            options = try await service.resetOptions(for: identifier.trimmed)
            if !options.contains(where: { $0.channel == selectedChannel }), let first = options.first {
                selectedChannel = first.channel
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendCode() async -> OTPChallenge? {
        isSending = true
        errorMessage = nil
        defer { isSending = false }

        do {
            return try await service.sendResetCode(identifier: identifier.trimmed, channel: selectedChannel)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
