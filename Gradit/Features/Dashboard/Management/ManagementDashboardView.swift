//
//  ManagementDashboardView.swift
//  Gradit
//
//  Design: 02 Management App › Home (HomeManagement).
//

import SwiftUI

struct ManagementDashboardView: View {
    @State private var viewModel: DashboardViewModel<ManagementDashboard>
    @Environment(AppRouter.self) private var router

    init(service: DashboardServiceProtocol) {
        _viewModel = State(initialValue: DashboardViewModel { try await service.managementDashboard() })
    }

    var body: some View {
        DashboardScreen(
            role: .management,
            unreadNotifications: viewModel.dashboard?.unreadNotifications ?? 0,
            dashboard: viewModel.dashboard,
            errorMessage: viewModel.errorMessage,
            reload: viewModel.load
        ) { dashboard in
            if let alert = dashboard.alert {
                DismissibleAlertBanner(alert: alert)
            }

            AttendanceSummaryCard(summary: dashboard.attendance) {
                router.push(.feature(.attendanceReport))
            }

            if let free = dashboard.freePeriods {
                PromptCard(
                    systemImage: "clock.badge.exclamationmark",
                    iconForeground: Theme.Colors.amber800,
                    iconBackground: Theme.Colors.warningBackground,
                    badgeCount: free.unallocated,
                    badgeColor: Theme.Colors.warning,
                    title: String(localized: "Free periods today"),
                    subtitle: String(localized: "\(free.absentStaff) staff absent · \(free.freePeriods) free periods · \(free.unallocated) unallocated"),
                    border: Theme.Colors.amberBorder
                ) {
                    router.push(.feature(.freePeriods))
                }
            }

            if let prompt = dashboard.mediaPrompt {
                PromptCard(
                    systemImage: "photo.on.rectangle",
                    title: String(localized: "\(prompt.eventName) has ended"),
                    subtitle: String(localized: "Add photos and videos for students and parents"),
                    accessory: .button(String(localized: "Add"))
                ) {
                    router.push(.event(.addMedia(eventID: prompt.eventId, source: .home)))
                }
            }

            QuickAccessGrid(actions: DashboardMenus.management, columns: 3, title: String(localized: "MENU")) { action in
                router.push(.feature(action.feature))
            }

            if !dashboard.needsAttention.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    DashboardSectionHeader(title: String(localized: "Needs attention"), trailing: String(localized: "See all")) {
                        router.push(.feature(.attendanceReport))
                    }
                    DividedListCard(items: dashboard.needsAttention) { item in
                        AttentionRow(item: item) {
                            router.push(.feature(.attendanceReport))
                        }
                    }
                }
            }
        }
    }
}

/// "Today’s attendance" card with three stat tiles.
private struct AttendanceSummaryCard: View {
    let summary: CollegeAttendanceSummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today’s attendance")
                        .font(AppFont.jakarta(15, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("View report")
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                    }
                    .font(AppFont.jakarta(13, .bold))
                    .foregroundStyle(Theme.Colors.blue600)
                }

                HStack(spacing: 8) {
                    StatTile(
                        label: String(localized: "Students"),
                        value: Text(DashboardFormat.percent(summary.studentPercent)).foregroundStyle(Theme.Colors.blue700),
                        footnote: changeText,
                        footnoteColor: summary.studentChangePoints >= 0 ? Theme.Colors.green700 : Theme.Colors.red700
                    )
                    StatTile(
                        label: String(localized: "Staff present"),
                        value: Text("\(Text("\(summary.staffPresent)").foregroundStyle(Theme.Colors.green700))\(Text("/\(summary.staffTotal)").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink500))"),
                        footnote: DashboardFormat.percent((summary.staffPercent * 10).rounded() / 10),
                        footnoteColor: Theme.Colors.ink500
                    )
                    StatTile(
                        label: String(localized: "Low attendance"),
                        value: Text("\(summary.lowAttendanceCount)").foregroundStyle(Theme.Colors.red700),
                        footnote: String(localized: "below \(summary.lowAttendanceThreshold)%"),
                        footnoteColor: Theme.Colors.red800,
                        labelColor: Theme.Colors.red800,
                        background: Theme.Colors.errorBackground
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .dashboardCard()
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint("Opens the attendance report")
    }

    private var changeText: String {
        let points = abs(summary.studentChangePoints)
        let arrow = summary.studentChangePoints >= 0 ? "▲" : "▼"
        return "\(arrow) \(String(format: "%.1f", points)) pts"
    }
}

private struct StatTile: View {
    let label: String
    let value: Text
    let footnote: String
    var footnoteColor: Color
    var labelColor: Color = Theme.Colors.ink700
    var background: Color = Theme.Colors.surfaceMuted

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFont.jakarta(12, .semibold))
                .foregroundStyle(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            value
                .font(AppFont.jakarta(20, .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(footnote)
                .font(AppFont.jakarta(12, .semibold))
                .foregroundStyle(footnoteColor)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private struct AttentionRow: View {
    let item: AttentionItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(AppFont.jakarta(14, .bold))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text(item.subtitle)
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                StatusBadge(text: String(localized: "Low"), tone: .red, systemImage: "arrow.down")
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.vertical, 8)
            .frame(minHeight: 60)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ManagementDashboardView(service: MockDashboardService())
    }
    .environment(AppRouter())
    .environment(AuthSession.preview())
}
