//
//  LoginView.swift
//  Gradit
//

import SwiftUI

/// Common › Sign in › Login (+ Language popup, + Fingerprint).
struct LoginView: View {
    var onForgotPassword: (String) -> Void

    @Environment(AuthSession.self) private var session
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .english
    @State private var viewModel = LoginViewModel()
    @State private var showLanguages = false

    var body: some View {
        AuthScaffold(spacing: 26) {
            topRow
            header
            form
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }
            actions
        } bottom: {
            legal
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
        .sheet(isPresented: $showLanguages) {
            LanguagePickerSheet(selection: $language)
        }
    }

    // MARK: - Sections

    private var topRow: some View {
        HStack {
            AppLogoMark()
            Spacer()
            Button {
                showLanguages = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Colors.blue600)
                    Text(verbatim: language.englishName)
                        .font(AppFont.jakarta(14, .bold))
                        .foregroundStyle(Theme.Colors.ink900)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                .padding(.leading, 14)
                .padding(.trailing, 12)
                .frame(height: 44)
                .overlay(Capsule().strokeBorder(Theme.Colors.border))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change language, current \(language.englishName)")
        }
        .padding(.top, 4)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome back")
                .font(Theme.Typography.display)
                .foregroundStyle(Theme.Colors.ink900)
                .accessibilityAddTraits(.isHeader)
            Text("\(AppConfig.collegeName) — sign in to follow attendance, marks and fees.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.ink700)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var form: some View {
        VStack(spacing: 18) {
            AppTextField(
                label: "Mobile number, email or ID",
                text: $viewModel.identifier,
                placeholder: "98765 43210",
                contentType: .username
            )

            AppTextField(
                label: "Password",
                text: $viewModel.password,
                isSecure: true,
                contentType: .password,
                submitLabel: .go,
                onSubmit: signIn
            )

            HStack {
                Toggle("Keep me signed in", isOn: $viewModel.keepSignedIn)
                    .toggleStyle(CheckboxToggleStyle())
                Spacer()
                AuthLinkButton(title: "Forgot password?") {
                    onForgotPassword(viewModel.identifier.trimmed)
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                PrimaryButton(title: "Sign in", isLoading: viewModel.isLoading, isEnabled: viewModel.canSubmit, action: signIn)

                if session.canUseBiometricLogin {
                    Button {
                        Task { await viewModel.signInWithBiometrics(using: session) }
                    } label: {
                        Image(systemName: session.biometryKind.systemImage)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Theme.Colors.green600)
                            .frame(width: 52, height: 52)
                            .background(Theme.Colors.green50, in: .rect(cornerRadius: Theme.Radius.button))
                            .overlay {
                                RoundedRectangle(cornerRadius: Theme.Radius.button)
                                    .strokeBorder(Theme.Colors.green600, lineWidth: 1.5)
                            }
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("Sign in with \(session.biometryKind.displayName)")
                }
            }

            if session.canUseBiometricLogin {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.Colors.green600)
                        .frame(width: 8, height: 8)
                    Text("\(session.biometryKind.displayName) sign-in is on for this device")
                }
                .font(AppFont.jakarta(13, .semibold))
                .foregroundStyle(Theme.Colors.green700)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var legal: some View {
        VStack(spacing: 2) {
            Text(termsText)
            Text("Need access? Call the college office at \(AppConfig.collegeOfficePhone)")
        }
        .font(AppFont.jakarta(13))
        .foregroundStyle(Theme.Colors.ink500)
        .multilineTextAlignment(.center)
        .tint(Theme.Colors.blue600)
        .frame(maxWidth: .infinity)
    }

    private var termsText: AttributedString {
        let markdown = String(
            localized: "By signing in you agree to our **[Terms](\(AppConfig.termsURL.absoluteString))** and **[Privacy policy](\(AppConfig.privacyURL.absoluteString))**."
        )
        return (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }

    private func signIn() {
        Task { await viewModel.signIn(using: session) }
    }
}

#Preview("Login") {
    NavigationStack {
        LoginView { _ in }
    }
    .environment(AuthSession.preview())
}

#Preview("Login · Face ID on") {
    NavigationStack {
        LoginView { _ in }
    }
    .environment(AuthSession.preview(biometrics: .faceID, hasBiometricLogin: true))
}
