//
//  ProfileView.swift
//  Gradit
//
//  Design: 01 Common › Profile and Settings › Profile (+ Logout confirm, Clear cache confirm).
//  Root of the "Me" tab (Parent / Student) and "Profile" tab (Faculty / Management).
//

import SwiftUI

struct ProfileView: View {
    @Environment(ProfileStore.self) private var store
    @Environment(AuthSession.self) private var session
    @Environment(AppRouter.self) private var router
    @Environment(OnboardingStore.self) private var onboarding
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .english

    private enum Dialog { case logout, clearCache }
    @State private var dialog: Dialog?
    @State private var cacheSize: Int64?
    @State private var isWorking = false
    @State private var showLanguages = false
    @State private var toast: String?

    private var role: UserRole { store.role }
    private var title: String {
        switch role {
        case .parent, .student: String(localized: "Me")
        case .faculty, .management: String(localized: "Profile")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(AppFont.jakarta(28, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                    .frame(minHeight: 44)
                    .accessibilityAddTraits(.isHeader)

                headerCard

                if let error = store.errorMessage, store.profile == nil {
                    ErrorBanner(message: error)
                }

                SettingsCard {
                    SettingsRow(title: String(localized: "Edit profile"), systemImage: "person") {
                        router.push(.profile(.editProfile))
                    }
                    if (session.currentUser?.roles.count ?? 0) > 1 {
                        SettingsRow(title: String(localized: "Switch role"), systemImage: "arrow.left.arrow.right") {
                            router.reset()
                            session.switchRole()
                        }
                    }
                    SettingsRow(title: String(localized: "Change password"), systemImage: "lock") {
                        router.push(.profile(.changePassword))
                    }
                    SettingsRow(title: String(localized: "Notification settings"), systemImage: "bell") {
                        router.push(.profile(.notificationSettings))
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Account")

                SettingsCard {
                    SettingsRow(title: String(localized: "Help & FAQ"), systemImage: "questionmark.circle") {
                        router.push(.profile(.helpFAQ))
                    }
                    SettingsRow(title: String(localized: "Privacy policy"), systemImage: "checkmark.shield") {
                        router.push(.profile(.privacyPolicy))
                    }
                    SettingsRow(title: String(localized: "Terms of service"), systemImage: "doc.text") {
                        router.push(.profile(.terms))
                    }
                    // Kept from the previous Settings screen (not drawn in the Profile design).
                    SettingsRow(title: String(localized: "Language"), systemImage: "globe", value: language.nativeName) {
                        showLanguages = true
                    }
                    SettingsRow(title: String(localized: "Country"), systemImage: "mappin.and.ellipse", value: onboarding.selectedCountry?.shortName) {
                        router.push(.profile(.country))
                    }
                    SettingsRow(title: String(localized: "Clear cache"), systemImage: "trash") {
                        openClearCache()
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Help and app")

                SettingsCard {
                    SettingsRow(title: String(localized: "Log out"), systemImage: "rectangle.portrait.and.arrow.right", isDestructive: true) {
                        withAnimation(.easeOut(duration: 0.2)) { dialog = .logout }
                    }
                }

                Text("Version \(AppConfig.appVersion) (\(AppConfig.buildNumber))")
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)
        }
        .scrollIndicators(.hidden)
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await store.loadProfile() }
        .task { if store.profile == nil { await store.loadProfile() } }
        .overlay { dialogOverlay }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(AppFont.jakarta(14, .semibold))
                    .foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.ink900, in: Capsule())
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showLanguages) {
            LanguagePickerSheet(selection: $language)
        }
    }

    // MARK: Header

    private var headerCard: some View {
        let name = store.profile?.fullName ?? session.currentUser?.name ?? ""
        return Button {
            router.push(.profile(.editProfile))
        } label: {
            HStack(spacing: 14) {
                ProfileAvatar(name: name, photoURL: store.profile?.photoURL)
                VStack(alignment: .leading, spacing: 5) {
                    Text(name)
                        .font(AppFont.jakarta(18, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    HStack(spacing: 8) {
                        Text(role.badgeTitle)
                            .font(AppFont.jakarta(12, .semibold))
                            .foregroundStyle(Theme.Colors.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.ink900, in: Capsule())
                        if let college = session.currentCollege {
                            Text(college.shortName ?? college.name)
                                .font(AppFont.jakarta(13))
                                .foregroundStyle(Theme.Colors.ink600)
                                .lineLimit(1)
                        }
                    }
                    if let summary = store.profile?.summary {
                        Text(summary)
                            .font(AppFont.jakarta(12))
                            .foregroundStyle(Theme.Colors.ink500)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if store.isLoading {
                        Text(verbatim: "Loading profile…")
                            .font(AppFont.jakarta(12))
                            .foregroundStyle(Theme.Colors.ink500)
                            .redacted(reason: .placeholder)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.chevron)
            }
            .padding(16)
            .background(Theme.Colors.white, in: .rect(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.Colors.cardBorder))
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("View and edit your profile")
    }

    // MARK: Dialogs

    @ViewBuilder
    private var dialogOverlay: some View {
        switch dialog {
        case .logout:
            ConfirmationCard(
                systemImage: "rectangle.portrait.and.arrow.right",
                iconForeground: Theme.Colors.destructive,
                iconBackground: Theme.Colors.errorBackground,
                title: String(localized: "Log out?"),
                message: String(localized: "You will need to sign in again to access GradIt."),
                confirmTitle: String(localized: "Log out"),
                confirmColor: Theme.Colors.destructiveStrong,
                isWorking: isWorking,
                onConfirm: logOut,
                onCancel: closeDialog
            )
        case .clearCache:
            ConfirmationCard(
                systemImage: "arrow.counterclockwise",
                title: String(localized: "Clear cache?"),
                message: clearCacheMessage,
                confirmTitle: String(localized: "Clear cache"),
                isWorking: isWorking,
                onConfirm: clearCache,
                onCancel: closeDialog
            )
        case nil:
            EmptyView()
        }
    }

    private var clearCacheMessage: String {
        let freed = cacheSize.map(CacheCleaner.formatted) ?? "…"
        return String(localized: "Frees \(freed) of downloaded files and thumbnails. You stay signed in and nothing in your account is deleted.")
    }

    private func closeDialog() {
        withAnimation(.easeOut(duration: 0.2)) { dialog = nil }
    }

    private func openClearCache() {
        cacheSize = nil
        withAnimation(.easeOut(duration: 0.2)) { dialog = .clearCache }
        Task {
            cacheSize = await Task.detached(priority: .userInitiated) { CacheCleaner.currentSize() }.value
        }
    }

    private func clearCache() {
        isWorking = true
        Task {
            let freed = await Task.detached(priority: .userInitiated) { CacheCleaner.clear() }.value
            isWorking = false
            closeDialog()
            showToast(String(localized: "Cleared \(CacheCleaner.formatted(freed))"))
        }
    }

    private func logOut() {
        isWorking = true
        Task {
            router.reset()
            await session.signOut()
            isWorking = false
            dialog = nil
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toast = nil }
        }
    }
}

#Preview("Parent") {
    NavigationStack { ProfileView() }
        .environment(ProfileStore(role: .parent, service: MockProfileService()))
        .environment(AuthSession.preview())
        .environment(AppRouter())
        .environment(OnboardingStore.preview())
}

#Preview("Management") {
    NavigationStack { ProfileView() }
        .environment(ProfileStore(role: .management, service: MockProfileService()))
        .environment(AuthSession.preview())
        .environment(AppRouter())
        .environment(OnboardingStore.preview())
}
