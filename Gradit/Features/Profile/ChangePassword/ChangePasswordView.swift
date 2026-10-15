//
//  ChangePasswordView.swift
//  Gradit
//
//  Design: 01 Common › Profile and Settings › Change password.
//

import SwiftUI
import Observation

@Observable
final class ChangePasswordViewModel {
    var currentPassword = ""
    var newPassword = ""
    var confirmation = ""
    var signOutOtherDevices = true
    var errorMessage: String?
    private(set) var isSaving = false
    private(set) var didSucceed = false

    var evaluation: PasswordEvaluation { PasswordPolicy.evaluate(newPassword, confirmation: confirmation) }

    /// Shown under Confirm once the user has typed something that doesn't match.
    var showsMismatch: Bool { !confirmation.isEmpty && !evaluation.matchesConfirmation }

    var canSubmit: Bool { !currentPassword.isEmpty && evaluation.isValid && newPassword != currentPassword && !isSaving }

    func submit(using store: ProfileStore) async {
        guard canSubmit else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await store.changePassword(current: currentPassword, new: newPassword, signOutOtherDevices: signOutOtherDevices)
            didSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ChangePasswordView: View {
    @Environment(ProfileStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ChangePasswordViewModel()

    var body: some View {
        let evaluation = viewModel.evaluation

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Use a password you don’t use for other apps.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.ink700)

                AppTextField(label: "Current password", text: $viewModel.currentPassword, isSecure: true, contentType: .password)
                    .overlay(alignment: .topTrailing) {
                        AuthLinkButton(title: "Forgot?") {
                            router.push(.profile(.forgotPassword))
                        }
                        .padding(.top, -13)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    AppTextField(label: "New password", text: $viewModel.newPassword, isSecure: true, contentType: .newPassword)
                    if evaluation.strength != .empty {
                        PasswordStrengthMeter(strength: evaluation.strength)
                    }
                    if !viewModel.newPassword.isEmpty, !evaluation.isValid || viewModel.newPassword == viewModel.currentPassword {
                        Text(ruleHint(evaluation))
                            .font(AppFont.jakarta(12))
                            .foregroundStyle(Theme.Colors.ink500)
                    }
                }

                AppTextField(
                    label: "Confirm new password",
                    text: $viewModel.confirmation,
                    isSecure: true,
                    contentType: .newPassword,
                    submitLabel: .done,
                    errorMessage: viewModel.showsMismatch ? String(localized: "Passwords don’t match") : nil,
                    onSubmit: submit
                )

                Toggle("Sign me out on other devices", isOn: $viewModel.signOutOtherDevices)
                    .toggleStyle(CheckboxToggleStyle())

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Update password", isLoading: viewModel.isSaving, isEnabled: viewModel.canSubmit, action: submit)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.Colors.white)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .navigationTitle("Change password")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeOut(duration: 0.15), value: evaluation)
        .alert("Password updated", isPresented: .constant(viewModel.didSucceed)) {
            Button("OK") { dismiss() }
        } message: {
            Text(viewModel.signOutOtherDevices
                 ? "Use your new password next time. Other devices have been signed out."
                 : "Use your new password next time you sign in.")
        }
    }

    private func ruleHint(_ evaluation: PasswordEvaluation) -> String {
        if viewModel.newPassword == viewModel.currentPassword { return String(localized: "Choose a password different from your current one.") }
        if !evaluation.hasMinLength { return String(localized: "Use at least \(PasswordPolicy.minLength) characters.") }
        if !evaluation.hasMixedCase { return String(localized: "Add an uppercase and a lowercase letter.") }
        if !evaluation.hasNumberOrSymbol { return String(localized: "Add a number or symbol.") }
        return ""
    }

    private func submit() {
        Task { await viewModel.submit(using: store) }
    }
}

#Preview {
    NavigationStack { ChangePasswordView() }
        .environment(ProfileStore(role: .parent, service: MockProfileService()))
        .environment(AppRouter())
}
