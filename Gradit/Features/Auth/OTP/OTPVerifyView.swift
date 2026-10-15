//
//  OTPVerifyView.swift
//  Gradit
//

import SwiftUI

/// Common › Sign in › OTP.
struct OTPVerifyView: View {
    @State private var viewModel: OTPVerifyViewModel
    private let onVerified: (ResetToken) -> Void
    private let onChangeDestination: () -> Void

    init(
        challenge: OTPChallenge,
        identifier: String,
        service: AuthServiceProtocol,
        onVerified: @escaping (ResetToken) -> Void,
        onChangeDestination: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: OTPVerifyViewModel(challenge: challenge, identifier: identifier, service: service))
        self.onVerified = onVerified
        self.onChangeDestination = onChangeDestination
    }

    var body: some View {
        AuthScaffold {
            AuthHeader(
                systemImage: "checkmark.shield",
                tint: Theme.Colors.green600,
                tintBackground: Theme.Colors.green50,
                title: "Enter the code",
                subtitle: subtitle
            )
            .tint(Theme.Colors.blue600)
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == "gradit-action" else { return .systemAction }
                onChangeDestination()
                return .handled
            })

            VStack(alignment: .leading, spacing: 12) {
                OTPCodeField(code: $viewModel.code, hasError: viewModel.errorMessage != nil)
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Theme.Typography.small)
                        .foregroundStyle(Theme.Colors.error)
                }
            }

            resendRow
        } bottom: {
            PrimaryButton(
                title: "Verify & continue",
                isLoading: viewModel.isVerifying,
                isEnabled: viewModel.isComplete,
                action: verify
            )
        }
        .onAppear { viewModel.startCountdown() }
        .onDisappear { viewModel.stopCountdown() }
        .onChange(of: viewModel.code) { _, newValue in
            if !newValue.isEmpty { viewModel.errorMessage = nil }
            if viewModel.isComplete { verify() }
        }
        .sensoryFeedback(.error, trigger: viewModel.errorMessage) { _, newValue in newValue != nil }
    }

    /// "We sent a 6-digit code to **+91 ••••• •3210**. Change"
    private var subtitle: Text {
        var change = AttributedString(String(localized: "Change"))
        change.link = URL(string: "gradit-action://change")
        change.font = AppFont.jakarta(15, .bold)
        let destination = Text(viewModel.challenge.maskedDestination)
            .bold()
            .foregroundStyle(Theme.Colors.ink900)
        return Text("We sent a 6-digit code to \(destination). \(Text(change))")
    }

    private var resendRow: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 16))
                if viewModel.canResend || viewModel.isResending {
                    Text("Didn’t get the code?")
                } else {
                    Text("Resend code in \(Text(viewModel.countdownText).bold().foregroundStyle(Theme.Colors.ink900))")
                        .monospacedDigit()
                }
            }
            .font(AppFont.jakarta(14))
            .foregroundStyle(Theme.Colors.ink700)

            Spacer()

            Button {
                Task { await viewModel.resend() }
            } label: {
                if viewModel.isResending {
                    ProgressView()
                } else {
                    Text("Resend")
                }
            }
            .font(AppFont.jakarta(14, .bold))
            .foregroundStyle(viewModel.canResend ? Theme.Colors.blue600 : Theme.Colors.ink500)
            .frame(minHeight: 44)
            .padding(.horizontal, 4)
            .disabled(!viewModel.canResend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
    }

    private func verify() {
        Task {
            if let token = await viewModel.verify() {
                onVerified(token)
            }
        }
    }
}

#Preview {
    NavigationStack {
        OTPVerifyView(
            challenge: OTPChallenge(requestId: "1", channel: .sms, maskedDestination: "+91 ••••• •3210", resendAfter: 42),
            identifier: "9876543210",
            service: MockAuthService(),
            onVerified: { _ in },
            onChangeDestination: {}
        )
    }
}
