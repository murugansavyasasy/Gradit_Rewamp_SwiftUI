//
//  LearnerDashboardView.swift
//  Gradit
//
//  Design: 03 Parent / Student App › Home (Parent) and Home (Student).
//  Parent adds the student switcher and the fees card; otherwise the screens match.
//

import SwiftUI

struct LearnerDashboardView: View {
    @State private var viewModel: LearnerDashboardViewModel
    @Environment(AppRouter.self) private var router

    init(role: UserRole, service: DashboardServiceProtocol) {
        _viewModel = State(initialValue: LearnerDashboardViewModel(role: role, service: service))
    }

    var body: some View {
        DashboardScreen(
            role: viewModel.role,
            unreadNotifications: viewModel.dashboard?.unreadNotifications ?? 0,
            dashboard: viewModel.dashboard,
            errorMessage: viewModel.errorMessage,
            reload: viewModel.load
        ) { dashboard in
            if viewModel.isParent, let student = viewModel.selectedStudent {
                StudentSwitcher(
                    selected: student,
                    students: viewModel.students,
                    onSelect: { student in Task { await viewModel.select(student) } }
                )
            }

            if let alert = dashboard.alert {
                DismissibleAlertBanner(alert: alert)
            }

            QuickAccessGrid(actions: DashboardMenus.learner, collapsedCount: 8) { action in
                router.push(.feature(action.feature))
            }

            AttendanceRingCard(
                percent: dashboard.attendance.overallPercent,
                caption: String(localized: "TODAY · OVERALL \(DashboardFormat.percent(dashboard.attendance.overallPercent))"),
                headline: attendanceHeadline(dashboard),
                detail: dashboard.attendance.nextClass.map { String(localized: "Next: \($0)") }
            ) {
                router.push(.feature(.attendance))
            }

            if let fee = dashboard.feeDue {
                FeeDueCard(fee: fee) { router.push(.feature(.feeDetails)) }
            }

            if !dashboard.classesToday.isEmpty {
                ClassesTodayCard(
                    title: viewModel.isParent
                        ? String(localized: "\(dashboard.studentFirstName)’s classes today")
                        : String(localized: "Today’s classes"),
                    periods: dashboard.classesToday
                ) {
                    router.push(.feature(.timetable))
                }
            }

            if !dashboard.events.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    DashboardSectionHeader(title: String(localized: "Upcoming events"), trailing: String(localized: "See all")) {
                        router.push(.feature(.events))
                    }
                    HorizontalCardStrip(items: dashboard.events) { event in
                        EventCard(event: event) { router.push(.feature(.events)) }
                    }
                }
            }

            if !dashboard.assignments.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    DashboardSectionHeader(title: String(localized: "Assignments due"), trailing: String(localized: "See all")) {
                        router.push(.feature(.assignment))
                    }
                    HorizontalCardStrip(items: dashboard.assignments) { assignment in
                        AssignmentCard(assignment: assignment) { router.push(.feature(.assignment)) }
                    }
                }
            }

            if !dashboard.notices.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    DashboardSectionHeader(title: String(localized: "Notice board"), trailing: String(localized: "See all")) {
                        router.push(.feature(.noticeBoard))
                    }
                    DividedListCard(items: dashboard.notices) { notice in
                        NoticeRow(notice: notice) { router.push(.feature(.noticeBoard)) }
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

            if let message = dashboard.sponsoredMessage {
                SponsoredBanner(message: message)
            }
        }
    }

    private func attendanceHeadline(_ dashboard: LearnerDashboard) -> String {
        let name = dashboard.studentFirstName
        let parent = viewModel.isParent
        switch dashboard.attendance.status {
        case .present:
            return parent ? String(localized: "\(name) is marked Present") : String(localized: "You’re marked Present")
        case .absent:
            return parent ? String(localized: "\(name) is marked Absent") : String(localized: "You’re marked Absent")
        case .late:
            return parent ? String(localized: "\(name) is marked Late") : String(localized: "You’re marked Late")
        case .notMarked:
            return parent ? String(localized: "\(name)’s attendance isn’t marked yet") : String(localized: "Attendance isn’t marked yet")
        }
    }
}

/// "AS  Aarav  B.E. CSE · Sem 5  ⌄" pill that switches between linked students.
private struct StudentSwitcher: View {
    let selected: LinkedStudent
    let students: [LinkedStudent]
    let onSelect: (LinkedStudent) -> Void

    var body: some View {
        Menu {
            ForEach(students) { student in
                Button {
                    onSelect(student)
                } label: {
                    if student.id == selected.id {
                        Label("\(student.name) · \(student.program)", systemImage: "checkmark")
                    } else {
                        Text("\(student.name) · \(student.program)")
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                InitialsAvatar(initials: DashboardGreeting.initials(selected.name), size: 32)
                Text(DashboardGreeting.shortName(selected.name))
                    .font(AppFont.jakarta(14, .bold))
                    .foregroundStyle(Theme.Colors.ink900)
                Text("\(selected.program) · \(selected.term)")
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink500)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .frame(minHeight: 44)
            .background(Theme.Colors.white, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.Colors.border))
        }
        .disabled(students.count < 2)
        .accessibilityLabel("Viewing \(selected.name). Switch student")
    }
}

private struct FeeDueCard: View {
    let fee: FeeDue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconTile(systemImage: "creditcard", foreground: Theme.Colors.warning, background: Theme.Colors.warningBackground)
                VStack(alignment: .leading, spacing: 2) {
                    Text("FEES DUE")
                        .font(AppFont.jakarta(12, .bold))
                        .foregroundStyle(Theme.Colors.amber800)
                    Text("\(Text(DashboardFormat.currency(fee.amount, code: fee.currencyCode)).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)) \(Text("· by \(DashboardFormat.shortDate(fee.dueDate))").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink500))")
                }
                Spacer(minLength: 0)
                Text("Pay now")
                    .font(AppFont.jakarta(13, .bold))
                    .foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.green600, in: .rect(cornerRadius: 10))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .dashboardCard()
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
    }
}

#Preview("Parent") {
    NavigationStack {
        LearnerDashboardView(role: .parent, service: MockDashboardService())
    }
    .environment(AppRouter())
    .environment(AuthSession.preview())
}

#Preview("Student") {
    NavigationStack {
        LearnerDashboardView(role: .student, service: MockDashboardService())
    }
    .environment(AppRouter())
    .environment(AuthSession.preview())
}
