//
//  CreatePasswordViewModel.swift
//  Gradit
//

import Foundation
import Observation

@Observable
final class CreatePasswordViewModel {
    var password = ""
    var confirmation = ""
    var errorMessage: String?
    private(set) var isSaving = false

    private let resetToken: ResetToken
    private let service: AuthServiceProtocol

    init(resetToken: ResetToken, service: AuthServiceProtocol) {
        self.resetToken = resetToken
        self.service = service
    }

    var evaluation: PasswordEvaluation { PasswordPolicy.evaluate(password, confirmation: confirmation) }
    var canSubmit: Bool { evaluation.isValid && !isSaving }

    func save() async -> AuthResult? {
        guard canSubmit else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            return try await service.setPassword(password, resetToken: resetToken)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
