//
//  AuthFlowView.swift
//  Gradit
//

import SwiftUI

/// Screens pushed on top of Login. Role selection is driven by `AuthSession.state` instead.
enum AuthRoute: Hashable {
    case forgotPassword(identifier: String)
    case verifyCode(OTPChallenge, identifier: String)
    case createPassword(ResetToken)
}

/// Login → Forgot password → OTP → Create password.
struct AuthFlowView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LoginView { identifier in
                path.append(.forgotPassword(identifier: identifier))
            }
            .navigationDestination(for: AuthRoute.self, destination: destination)
        }
        .tint(Theme.Colors.ink900)
    }

    @ViewBuilder
    private func destination(for route: AuthRoute) -> some View {
        switch route {
        case .forgotPassword(let identifier):
            ForgotPasswordView(
                identifier: identifier,
                service: dependencies.authService,
                onCodeSent: { challenge, identifier in
                    path.append(.verifyCode(challenge, identifier: identifier))
                },
                onBackToSignIn: { path.removeAll() }
            )

        case .verifyCode(let challenge, let identifier):
            OTPVerifyView(
                challenge: challenge,
                identifier: identifier,
                service: dependencies.authService,
                onVerified: { token in path.append(.createPassword(token)) },
                onChangeDestination: { path.removeLast() }
            )

        case .createPassword(let token):
            CreatePasswordView(resetToken: token, service: dependencies.authService)
        }
    }
}

#Preview {
    AuthFlowView()
        .environment(AppDependencies.preview)
        .environment(AuthSession.preview(hasBiometricLogin: true))
}
