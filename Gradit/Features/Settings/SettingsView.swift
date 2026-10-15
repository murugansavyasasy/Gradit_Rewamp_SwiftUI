//
//  SettingsView.swift
//  Gradit
//
//  Design: 01 Common › Profile and Settings › Notification settings (Settings.dc).
//  Opened from Profile › Notification settings.
//

import SwiftUI

struct SettingsView: View {
    @Environment(ProfileStore.self) private var store
    @Environment(AuthSession.self) private var session

    private struct Item: Identifiable {
        let id: String
        let title: String
        let hint: String
        let keyPath: WritableKeyPath<NotificationPreferences, Bool>
    }

    private let items: [Item] = [
        Item(id: "attendance", title: String(localized: "Attendance alerts"), hint: String(localized: "When marked absent or late"), keyPath: \.attendance),
        Item(id: "fees", title: String(localized: "Fee reminders"), hint: String(localized: "7 days and 1 day before due"), keyPath: \.fees),
        Item(id: "exams", title: String(localized: "Results & exams"), hint: String(localized: "Marks, timetables, hall tickets"), keyPath: \.exams),
        Item(id: "bus", title: String(localized: "Bus arrival"), hint: String(localized: "When the bus is 10 min away"), keyPath: \.bus),
        Item(id: "messages", title: String(localized: "Voice notes & messages"), hint: String(localized: "From teachers and the college office"), keyPath: \.messages),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose which alerts reach this phone.")
                    .font(AppFont.jakarta(14))
                    .foregroundStyle(Theme.Colors.ink600)

                if let preferences = store.preferences {
                    SettingsCard(radius: 16) {
                        ForEach(items) { item in
                            SettingsToggleRow(
                                title: item.title,
                                hint: item.hint,
                                isOn: Binding(
                                    get: { preferences[keyPath: item.keyPath] },
                                    set: { newValue in Task { await store.setPreference(item.keyPath, to: newValue) } }
                                )
                            )
                        }
                    }
                } else if let error = store.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await store.loadPreferences() }
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                }

                // Face ID / Touch ID quick sign-in (existing feature; Help & FAQ points here).
                if session.hasBiometricLogin {
                    SettingsCard(radius: 16) {
                        SettingsToggleRow(
                            title: String(localized: "\(session.biometryKind.displayName) sign-in"),
                            hint: String(localized: "Sign in without your password on this phone"),
                            isOn: Binding(
                                get: { session.hasBiometricLogin },
                                set: { if !$0 { session.disableBiometricLogin() } }
                            )
                        )
                    }
                }

                if let error = store.errorMessage, store.preferences != nil {
                    ErrorBanner(message: error)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 14)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .navigationTitle("Notification settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            store.errorMessage = nil
            await store.loadPreferences()
        }
        .sensoryFeedback(.selection, trigger: store.preferences)
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(ProfileStore(role: .parent, service: MockProfileService()))
        .environment(AuthSession.preview(hasBiometricLogin: true))
}
