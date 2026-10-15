//
//  DashboardHeader.swift
//  Gradit
//

import SwiftUI

/// Greeting row at the top of every dashboard: logo, "Good morning, …", role badge, search and bell.
struct DashboardHeader: View {
    let role: UserRole
    /// Overrides the college name (e.g. "Dept. of CSE" for faculty).
    var subtitle: String?
    var unreadNotifications: Int = 0

    @Environment(AuthSession.self) private var session
    @Environment(AppRouter.self) private var router

    var body: some View {
        HStack(spacing: 12) {
            AppLogoMark(size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(DashboardGreeting.text(name: session.currentUser?.name ?? ""))
                    .font(AppFont.jakarta(15, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: 6) {
                    Text(role.badgeTitle)
                        .font(AppFont.jakarta(12, .bold))
                        .foregroundStyle(Theme.Colors.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(role.badgeColor, in: Capsule())
                    if let context = subtitle ?? collegeName {
                        Text(context)
                            .font(AppFont.jakarta(12, .semibold))
                            .foregroundStyle(Theme.Colors.ink500)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            CircleIconButton(systemImage: "magnifyingglass", accessibilityLabel: String(localized: "Search")) {
                router.push(.feature(.search))
            }
            CircleIconButton(
                systemImage: "bell",
                accessibilityLabel: unreadNotifications > 0
                    ? String(localized: "Notifications, \(unreadNotifications) unread")
                    : String(localized: "Notifications"),
                showsDot: unreadNotifications > 0
            ) {
                router.push(.feature(.notifications))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var collegeName: String? {
        guard let college = session.currentCollege else { return nil }
        return college.shortName ?? college.name
    }
}

struct CircleIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var showsDot = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.Colors.ink900)
                .frame(width: 44, height: 44)
                .background(Theme.Colors.white, in: Circle())
                .overlay(Circle().strokeBorder(Theme.Colors.line))
                .overlay(alignment: .topTrailing) {
                    if showsDot {
                        Circle()
                            .fill(Theme.Colors.error)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().strokeBorder(Theme.Colors.white, lineWidth: 2))
                            .offset(x: -11, y: 9)
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}
