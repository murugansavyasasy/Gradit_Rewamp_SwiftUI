//
//  MainTabView.swift
//  Gradit
//

import SwiftUI

/// Signed-in app: shows the tab shell and dashboard for the role chosen at sign-in.
struct MainTabView: View {
    @Environment(AuthSession.self) private var session
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        if let role = session.currentRole {
            RoleTabShell(role: role, profileService: dependencies.profileService)
                .id(role)
        } else {
            LaunchView()
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppRouter())
        .environment(AppDependencies.preview)
        .environment(AuthSession.preview())
        .environment(OnboardingStore.preview())
}
