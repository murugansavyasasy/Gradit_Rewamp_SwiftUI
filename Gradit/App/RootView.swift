//
//  RootView.swift
//  Gradit
//

import SwiftUI

/// Switches between launch, the auth flow, role selection and the main app based on `AuthSession.state`.
struct RootView: View {
    @Environment(AuthSession.self) private var session
    @Environment(OnboardingStore.self) private var onboarding

    /// Branded splash covers every cold start until its loading beat finishes.
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            content

            if !splashFinished {
                SplashView { splashFinished = true }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.state)
        .animation(.easeInOut(duration: 0.3), value: onboarding.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: splashFinished)
        .task {
            if case .restoring = session.state {
                await session.restore()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !onboarding.hasCompletedOnboarding {
            // First launch only: App intro → Country selection → (Login below).
            OnboardingFlowView()
                .transition(.opacity)
        } else {
            switch session.state {
            case .restoring:
                LaunchView()
            case .signedOut:
                AuthFlowView()
            case .choosingRole(let user):
                RoleSelectView(user: user, preferredRole: session.preferredRole)
            case .signedIn:
                MainTabView()
            }
        }
    }
}

struct LaunchView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            AppLogoMark(size: 72)
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.white)
    }
}

#Preview {
    RootView()
        .environment(AppRouter())
        .environment(AppDependencies.preview)
        .environment(AuthSession.preview())
        .environment(OnboardingStore.preview())
}
