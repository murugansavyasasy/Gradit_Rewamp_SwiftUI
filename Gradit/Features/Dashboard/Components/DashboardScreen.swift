//
//  DashboardScreen.swift
//  Gradit
//

import SwiftUI

/// Shared dashboard scaffold: fixed header, then loading / error / scrolling content.
/// Pull to refresh reloads; the previous content stays visible while refreshing.
struct DashboardScreen<Dashboard, Content: View>: View {
    let role: UserRole
    var subtitle: String?
    var unreadNotifications: Int = 0
    let dashboard: Dashboard?
    let errorMessage: String?
    let reload: () async -> Void
    @ViewBuilder let content: (Dashboard) -> Content

    var body: some View {
        VStack(spacing: 0) {
            DashboardHeader(role: role, subtitle: subtitle, unreadNotifications: unreadNotifications)

            if let dashboard {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        content(dashboard)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
                .refreshable { await reload() }
            } else if let errorMessage {
                ErrorStateView(message: errorMessage) {
                    Task { await reload() }
                }
                .frame(maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if dashboard == nil { await reload() }
        }
    }
}

/// "Upcoming events ……… See all"
struct DashboardSectionHeader: View {
    let title: String
    var trailing: String?
    var trailingIsAction = true
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.jakarta(16, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let trailing {
                if let action, trailingIsAction {
                    Button(trailing, action: action)
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(Theme.Colors.blue600)
                        .frame(minHeight: 44)
                        .padding(.vertical, -14)
                } else {
                    Text(trailing)
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(Theme.Colors.blue700)
                }
            }
        }
    }
}

/// Red alert strip with a dismiss button. Dismissal is remembered per alert ID.
struct DismissibleAlertBanner: View {
    let alert: DashboardAlert
    @AppStorage("dashboard.dismissedAlertID") private var dismissedAlertID = ""

    var body: some View {
        if dismissedAlertID != alert.id {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.top, 2)
                    .accessibilityHidden(true)
                Text(alert.message)
                    .font(AppFont.jakarta(13, .semibold))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { dismissedAlertID = alert.id }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.vertical, -10)
                .accessibilityLabel("Dismiss alert")
            }
            .foregroundStyle(Theme.Colors.red700)
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 10)
            .background(Theme.Colors.errorBackground, in: .rect(cornerRadius: 14))
            .accessibilityElement(children: .contain)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}
