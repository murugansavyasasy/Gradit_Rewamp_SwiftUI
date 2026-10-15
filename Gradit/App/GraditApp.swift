//
//  GraditApp.swift
//  Gradit
//

import SwiftUI

@main
struct GraditApp: App {
    @State private var router = AppRouter()
    @State private var dependencies: AppDependencies
    @State private var session: AuthSession
    @State private var onboarding: OnboardingStore
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .english

    init() {
        AppFont.registerFonts()
        let dependencies = AppDependencies.live
        _dependencies = State(initialValue: dependencies)
        let session = AuthSession(service: dependencies.authService, apiClient: dependencies.apiClient)
        let onboarding = OnboardingStore()
        // Keychain items survive app deletion. On a fresh install (onboarding not yet
        // completed) drop any leftover sign-in so the flow ends on Login, not a dashboard.
        if !onboarding.hasCompletedOnboarding {
            session.forgetStoredCredentials()
        }
        _session = State(initialValue: session)
        _onboarding = State(initialValue: onboarding)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(dependencies)
                .environment(session)
                .environment(onboarding)
                .environment(\.locale, language.locale)
                .font(Theme.Typography.body)
                .tint(Theme.Colors.blue600)
                .preferredColorScheme(.light) // The design system is light-only for now.
        }
    }
}
