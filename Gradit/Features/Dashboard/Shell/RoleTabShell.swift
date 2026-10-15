//
//  RoleTabShell.swift
//  Gradit
//
//  Signed-in container: one NavigationStack per tab (each keeps its own state)
//  plus the design's custom bottom navigation, which hides on pushed screens.
//

import SwiftUI

struct RoleTabShell: View {
    let role: UserRole
    @Environment(AppRouter.self) private var router
    @State private var profileStore: ProfileStore

    init(role: UserRole, profileService: ProfileServiceProtocol) {
        self.role = role
        _profileStore = State(initialValue: ProfileStore(role: role, service: profileService))
    }

    private var tabs: [DashboardTab] { DashboardTab.tabs(for: role) }
    private var showsTabBar: Bool { router.isAtRoot(router.selectedTab) }

    var body: some View {
        ZStack {
            ForEach(tabs) { tab in
                let isSelected = router.selectedTab == tab
                NavigationStack(path: router.path(for: tab)) {
                    root(for: tab)
                        .navigationDestination(for: Route.self) { $0.destination }
                }
                .opacity(isSelected ? 1 : 0)
                .allowsHitTesting(isSelected)
                .accessibilityHidden(!isSelected)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsTabBar {
                DashboardTabBar(tabs: tabs, selection: router.selectedTab) { tab in
                    router.select(tab)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .environment(profileStore)
        .animation(.easeInOut(duration: 0.2), value: showsTabBar)
        .onAppear {
            if !tabs.contains(router.selectedTab) { router.reset() }
        }
        .onChange(of: role) {
            router.reset()
        }
    }

    @ViewBuilder
    private func root(for tab: DashboardTab) -> some View {
        switch tab {
        case .home:
            RoleDashboardView(role: role)
        case .profile, .me:
            ProfileView()
        case .messages:
            MessagesInboxView(role: role)
        case .chat:
            // Student / parent "Chat" tab opens the Discussion Board.
            DiscussionRouteView(route: .board)
        case .notices:
            NoticeEntryView()
        case .campus:
            EventsEntryView()
        case .attendance:
            AttendanceEntryView()
        default:
            FeaturePlaceholderView(feature: tab.placeholderFeature)
        }
    }
}

/// Picks the dashboard for the signed-in role.
struct RoleDashboardView: View {
    let role: UserRole
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        switch role {
        case .management:
            ManagementDashboardView(service: dependencies.dashboardService)
        case .faculty:
            FacultyDashboardView(service: dependencies.dashboardService)
        case .parent, .student:
            LearnerDashboardView(role: role, service: dependencies.dashboardService)
                .id(role)
        }
    }
}

/// Bottom navigation from the design (BottomNav): pill highlight on the active tab.
struct DashboardTabBar: View {
    let tabs: [DashboardTab]
    let selection: DashboardTab
    let onSelect: (DashboardTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                let isSelected = tab == selection
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .symbolVariant(isSelected ? .fill : .none)
                            .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                            .frame(width: 56, height: 30)
                            .background(isSelected ? Theme.Colors.blue50 : .clear, in: Capsule())
                        Text(tab.title)
                            .font(AppFont.jakarta(12, isSelected ? .bold : .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(isSelected ? Theme.Colors.blue600 : Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 2)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background {
            Theme.Colors.white.ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.Colors.line)
                .frame(height: 1)
        }
        .animation(.easeOut(duration: 0.15), value: selection)
    }
}

/// Stand-in for screens that are in the design but not built in the app yet.
struct FeaturePlaceholderView: View {
    let feature: DashboardFeature

    var body: some View {
        ContentUnavailableView {
            Label(feature.title, systemImage: feature.systemImage)
        } description: {
            Text("This screen is in the design and hasn’t been built in the app yet.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle(feature.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Parent") {
    RoleTabShell(role: .parent, profileService: MockProfileService())
        .environment(AppRouter())
        .environment(AppDependencies.preview)
        .environment(AuthSession.preview())
        .environment(OnboardingStore.preview())
}

#Preview("Management") {
    RoleTabShell(role: .management, profileService: MockProfileService())
        .environment(AppRouter())
        .environment(AppDependencies.preview)
        .environment(AuthSession.preview())
        .environment(OnboardingStore.preview())
}
