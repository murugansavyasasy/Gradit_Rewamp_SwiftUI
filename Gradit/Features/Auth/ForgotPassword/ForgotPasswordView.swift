//
//  ForgotPasswordView.swift
//  Gradit
//

import SwiftUI

/// Common › Sign in › Forgot password.
/// If Login passed an ID we go straight to the "Send code via" options; otherwise we ask for it first.
struct ForgotPasswordView: View {
    @State private var viewModel: ForgotPasswordViewModel
    private let onCodeSent: (OTPChallenge, String) -> Void
    private let onBackToSignIn: () -> Void

    init(
        identifier: String,
        service: AuthServiceProtocol,
        onCodeSent: @escaping (OTPChallenge, String) -> Void,
        onBackToSignIn: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: ForgotPasswordViewModel(identifier: identifier, service: service))
        self.onCodeSent = onCodeSent
        self.onBackToSignIn = onBackToSignIn
    }

    var body: some View {
        AuthScaffold {
            AuthHeader(
                systemImage: "lock",
                title: "Forgot password?",
                subtitle: viewModel.hasOptions
                    ? Text("Choose where we should send a 6-digit code to reset it.")
                    : Text("Enter your mobile number, email or ID and we’ll send a 6-digit code to reset it.")
            )

            if viewModel.hasOptions {
                optionsList
            } else {
                AppTextField(
                    label: "Mobile number, email or ID",
                    text: $viewModel.identifier,
                    placeholder: "98765 43210",
                    contentType: .username,
                    submitLabel: .continue,
                    onSubmit: loadOptions
                )
            }

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }
        } bottom: {
            if viewModel.hasOptions {
                PrimaryButton(title: "Send code", isLoading: viewModel.isSending, action: sendCode)
            } else {
                PrimaryButton(
                    title: "Continue",
                    isLoading: viewModel.isLoadingOptions,
                    isEnabled: viewModel.canContinue,
                    action: loadOptions
                )
            }
            AuthLinkButton(title: "Back to sign in", action: onBackToSignIn)
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.hasOptions)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
        .task {
            if !viewModel.hasOptions && !viewModel.identifier.isBlank {
                await viewModel.loadOptions()
            }
        }
    }

    private var optionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Send code via")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.ink700)
            ForEach(viewModel.options) { option in
                SelectionCard(
                    title: option.channel == .sms
                        ? String(localized: "SMS to registered mobile")
                        : String(localized: "Email"),
                    subtitle: option.maskedDestination,
                    systemImage: option.channel == .sms ? "iphone" : "envelope",
                    isSelected: viewModel.selectedChannel == option.channel
                ) {
                    viewModel.selectedChannel = option.channel
                }
            }
        }
    }

    private func loadOptions() {
        Task { await viewModel.loadOptions() }
    }

    private func sendCode() {
        Task {
            if let challenge = await viewModel.sendCode() {
                onCodeSent(challenge, viewModel.identifier.trimmed)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView(identifier: "9876543210", service: MockAuthService(), onCodeSent: { _, _ in }, onBackToSignIn: {})
    }
}
