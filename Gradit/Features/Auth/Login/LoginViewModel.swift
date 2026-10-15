//
//  LoginViewModel.swift
//  Gradit
//

import Foundation
import Observation

@Observable
final class LoginViewModel {
    var identifier = ""
    var password = ""
    var keepSignedIn = true
    var errorMessage: String?
    private(set) var isLoading = false

    var canSubmit: Bool { !identifier.isBlank && !password.isEmpty && !isLoading }

    func signIn(using session: AuthSession) async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await session.signIn(identifier: identifier, password: password, keepSignedIn: keepSignedIn)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithBiometrics(using session: AuthSession) async {
        errorMessage = nil
        do {
            try await session.signInWithBiometrics()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
