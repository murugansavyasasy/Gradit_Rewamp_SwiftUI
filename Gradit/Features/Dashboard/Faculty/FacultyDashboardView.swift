//
//  FacultyDashboardView.swift
//  Gradit
//
//  Design: 02 Management App › Other screens › Faculty home (HomeTeacher).
//

import SwiftUI

struct FacultyDashboardView: View {
    @State private var viewModel: FacultyDashboardViewModel
    @Environment(AppRouter.self) private var router

    init(service: DashboardServiceProtocol) {
        _viewModel = State(initialValue: FacultyDashboardViewModel(service: service))
    }

    var body: some View {
        let content = viewModel.content

        DashboardScreen(
            role: .faculty,
            subtitle: content.dashboard?.department,
            unreadNotifications: content.dashboard?.unreadNotifications ?? 0,
            dashboard: content.dashboard,
            errorMessage: content.errorMessage,
            reload: content.load
        ) { dashboard in
            if let alert = dashboard.alert {
                DismissibleAlertBanner(alert: alert)
            }

            QuickAccessGrid(actions: DashboardMenus.faculty) { action in
                router.push(.feature(action.feature))
            }

            if let swap = dashboard.swapRequest {
                PromptCard(
                    systemImage: "arrow.left.arrow.right",
                    iconForeground: Theme.Colors.white,
                    iconBackground: Theme.Colors.blue600,
                    badgeCount: swap.pendingCount,
                    title: String(localized: "Swap request"),
                    subtitle: "\(swap.requesterName) · \(swap.summary)",
                    background: Theme.Colors.blue50
                ) {
                    router.push(.feature(.swapRequest))
                }
            }

            MyTimetableButton(coverPeriods: dashboard.coverPeriodsToday) {
                router.push(.feature(.timetable))
            }

            TeacherClassesCard(classes: dashboard.classesToday) {
                router.push(.feature(.attendance))
            }

            if !dashboard.leaveRequests.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    DashboardSectionHeader(
                        title: String(localized: "Pending leave requests"),
                        trailing: String(localized: "\(viewModel.pendingLeaveCount) pending"),
                        trailingIsAction: false
                    )
                    DividedListCard(items: dashboard.leaveRequests) { request in
                        LeaveRequestRow(
                            request: request,
                            decision: viewModel.decisions[request.id],
                            onDecision: { decision in
                                Task { await viewModel.respond(to: request, with: decision) }
                            }
                        )
                    }
                    if let message = viewModel.actionErrorMessage {
                        ErrorBanner(message: message)
                    }
                }
            }

            if !dashboard.notifications.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    DashboardSectionHeader(title: String(localized: "Recent notifications"), trailing: String(localized: "See all")) {
                        router.push(.feature(.notifications))
                    }
                    DividedListCard(items: dashboard.notifications) { notice in
                        NoticeRow(notice: notice) { router.push(.feature(.notifications)) }
                    }
                }
            }

            if let chat = dashboard.latestChat {
                VStack(alignment: .leading, spacing: 10) {
                    DashboardSectionHeader(title: String(localized: "Messages"), trailing: String(localized: "See all")) {
                        router.push(.feature(.messages))
                    }
                    ChatPreviewCard(chat: chat) { router.push(.feature(.messages)) }
                }
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.decisions.count)
    }
}

private struct MyTimetableButton: View {
    let coverPeriods: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                Text("My timetable")
                if coverPeriods > 0 {
                    Text("\(coverPeriods) cover today")
                        .font(AppFont.jakarta(12, .heavy))
                        .foregroundStyle(Theme.Colors.green700)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 1)
                        .background(Theme.Colors.green50, in: Capsule())
                }
            }
            .font(AppFont.jakarta(14, .bold))
            .foregroundStyle(Theme.Colors.blue700)
            .frame(maxWidth: .infinity, minHeight: 48)
            .dashboardCard(radius: 14, border: Theme.Colors.border)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct TeacherClassesCard: View {
    let classes: [FacultyClass]
    let onMarkAttendance: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today’s classes")
                    .font(AppFont.jakarta(16, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                StatusBadge(text: String(localized: "\(classes.count) classes"), tone: .blueSoft)
            }

            if classes.isEmpty {
                Text("No classes scheduled today.")
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink500)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(classes) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Text(item.startTime)
                                .font(AppFont.jakarta(14, .heavy))
                                .foregroundStyle(item.isCover ? Theme.Colors.green700 : Theme.Colors.blue600)
                                .frame(width: 48, alignment: .leading)
                                .monospacedDigit()
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.subject)
                                    .font(AppFont.jakarta(14, .bold))
                                    .foregroundStyle(Theme.Colors.ink900)
                                Text(item.detail)
                                    .font(AppFont.jakarta(12))
                                    .foregroundStyle(Theme.Colors.ink500)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            if item.isCover {
                                StatusBadge(text: String(localized: "Cover"), tone: .green)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            Button(action: onMarkAttendance) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                    Text("Mark attendance")
                }
                .font(AppFont.jakarta(15, .bold))
                .foregroundStyle(Theme.Colors.blue700)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Theme.Colors.blue50, in: .rect(cornerRadius: 12))
                .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .dashboardCard(radius: 18)
    }
}

private struct LeaveRequestRow: View {
    let request: LeaveRequest
    let decision: LeaveDecision?
    let onDecision: (LeaveDecision) -> Void

    var body: some View {
        HStack(spacing: 10) {
            InitialsAvatar(
                initials: DashboardGreeting.initials(request.studentName),
                size: 40,
                foreground: Theme.Colors.green700,
                background: Theme.Colors.green50
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(request.studentName)
                    .font(AppFont.jakarta(14, .bold))
                    .foregroundStyle(Theme.Colors.ink900)
                Text(request.summary)
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            switch decision {
            case .none:
                HStack(spacing: 6) {
                    Button("Reject") { onDecision(.rejected) }
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(Theme.Colors.ink700)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .dashboardCard(radius: 10, border: Theme.Colors.border)
                        .accessibilityLabel("Reject leave for \(request.studentName)")
                    Button("Approve") { onDecision(.approved) }
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(Theme.Colors.white)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 10))
                        .accessibilityLabel("Approve leave for \(request.studentName)")
                }
                .buttonStyle(.plain)
            case .approved?:
                StatusBadge(text: String(localized: "Approved"), tone: .green)
            case .rejected?:
                StatusBadge(text: String(localized: "Rejected"), tone: .red)
            }
        }
        .padding(.vertical, 8)
        .animation(.easeOut(duration: 0.2), value: decision)
    }
}

#Preview {
    NavigationStack {
        FacultyDashboardView(service: MockDashboardService())
    }
    .environment(AppRouter())
    .environment(AuthSession.preview())
}
