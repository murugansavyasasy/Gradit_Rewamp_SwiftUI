//
//  ProfileRoute.swift
//  Gradit
//
//  Screens pushed from the Profile tab. Wired into the shared `Route` enum
//  so they use the tab's existing NavigationStack (no second navigation system).
//

import SwiftUI

enum ProfileRoute: Hashable {
    case editProfile
    case changePassword
    case notificationSettings
    case helpFAQ
    case privacyPolicy
    case terms
    case country
    // "Forgot?" on Change password reuses the sign-in reset screens.
    case forgotPassword
    case verifyCode(OTPChallenge, identifier: String)
    case createPassword(ResetToken)
}

/// Builds the destination for a `ProfileRoute`; reads dependencies from the environment.
struct ProfileRouteView: View {
    let route: ProfileRoute

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(AuthSession.self) private var session
    @Environment(OnboardingStore.self) private var onboarding
    @Environment(ProfileStore.self) private var profileStore

    var body: some View {
        switch route {
        case .editProfile:
            EditProfileView()
        case .changePassword:
            ChangePasswordView()
        case .notificationSettings:
            SettingsView()
        case .helpFAQ:
            HelpFAQView()
        case .privacyPolicy:
            PrivacyPolicyView()
        case .terms:
            TermsView()
        case .country:
            CountrySelectionView(mode: .settings, selected: onboarding.selectedCountry) { country in
                onboarding.selectCountry(country)
                router.popToRoot()
            }
        case .forgotPassword:
            ForgotPasswordView(
                identifier: profileStore.profile?.mobile ?? "",
                service: dependencies.authService,
                onCodeSent: { challenge, identifier in
                    router.push(.profile(.verifyCode(challenge, identifier: identifier)))
                },
                onBackToSignIn: { router.popToRoot() }
            )
        case .verifyCode(let challenge, let identifier):
            OTPVerifyView(
                challenge: challenge,
                identifier: identifier,
                service: dependencies.authService,
                onVerified: { token in router.push(.profile(.createPassword(token))) },
                onChangeDestination: { router.popToRoot() }
            )
        case .createPassword(let token):
            CreatePasswordView(resetToken: token, service: dependencies.authService)
        }
    }
}
