//
//  CreatePasswordView.swift
//  Gradit
//

import SwiftUI

/// Common › Sign in › Create password.
struct CreatePasswordView: View {
    @Environment(AuthSession.self) private var session
    @State private var viewModel: CreatePasswordViewModel

    init(resetToken: ResetToken, service: AuthServiceProtocol) {
        _viewModel = State(initialValue: CreatePasswordViewModel(resetToken: resetToken, service: service))
    }

    var body: some View {
        let evaluation = viewModel.evaluation

        AuthScaffold(spacing: Theme.Spacing.md) {
            AuthHeader(
                systemImage: "key",
                title: "Create a password",
                subtitle: Text("Your number is verified. Set a password you’ll use to sign in next time.")
            )
            .padding(.bottom, Theme.Spacing.sm)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                AppTextField(label: "New password", text: $viewModel.password, isSecure: true, contentType: .newPassword)
                if evaluation.strength != .empty {
                    StrengthMeter(strength: evaluation.strength)
                }
            }

            AppTextField(
                label: "Confirm password",
                text: $viewModel.confirmation,
                isSecure: true,
                contentType: .newPassword,
                submitLabel: .done,
                onSubmit: save
            )

            rules(evaluation)

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }
        } bottom: {
            PrimaryButton(title: "Save & continue", isLoading: viewModel.isSaving, isEnabled: viewModel.canSubmit, action: save)
        }
        .animation(.easeOut(duration: 0.15), value: evaluation)
    }

    private func rules(_ evaluation: PasswordEvaluation) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            RuleRow(text: "At least \(PasswordPolicy.minLength) characters", isMet: evaluation.hasMinLength)
            RuleRow(text: "One uppercase and one lowercase letter", isMet: evaluation.hasMixedCase)
            RuleRow(text: "One number or symbol", isMet: evaluation.hasNumberOrSymbol)
            RuleRow(text: "Passwords match", isMet: evaluation.matchesConfirmation)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
    }

    private func save() {
        Task {
            guard let result = await viewModel.save() else { return }
            do {
                try session.completePasswordReset(with: result)
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}

private struct RuleRow: View {
    let text: LocalizedStringKey
    let isMet: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isMet ? Theme.Colors.green600 : Theme.Colors.ink300)
            Text(text)
                .font(AppFont.jakarta(13))
                .foregroundStyle(isMet ? Theme.Colors.ink900 : Theme.Colors.ink500)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(isMet ? "Done" : "Not yet")
    }
}

private struct StrengthMeter: View {
    let strength: PasswordStrength

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { index in
                    Capsule()
                        .fill(index <= strength.rawValue ? barColor : Theme.Colors.line)
                        .frame(height: 6)
                }
            }
            .padding(.top, 4)
            .accessibilityHidden(true)

            Text(label)
                .font(AppFont.jakarta(13, .semibold))
                .foregroundStyle(textColor)
        }
    }

    private var barColor: Color {
        switch strength {
        case .empty, .weak: Theme.Colors.error
        case .fair: Theme.Colors.warning
        case .strong, .veryStrong: Theme.Colors.green600
        }
    }

    private var textColor: Color {
        switch strength {
        case .empty, .weak: Theme.Colors.error
        case .fair: Theme.Colors.warning
        case .strong, .veryStrong: Theme.Colors.green700
        }
    }

    private var label: LocalizedStringKey {
        switch strength {
        case .empty, .weak: "Weak password"
        case .fair: "Fair password"
        case .strong: "Strong password"
        case .veryStrong: "Very strong password"
        }
    }
}

#Preview {
    NavigationStack {
        CreatePasswordView(resetToken: ResetToken(token: "preview"), service: MockAuthService())
    }
    .environment(AuthSession.preview())
}
