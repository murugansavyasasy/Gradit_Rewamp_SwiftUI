//
//  FacultyAttendanceView.swift
//  Gradit
//
//  Faculty (teacher) "Attendance" tab: today's classes to mark + student leave
//  requests to approve or reject. Design: attendanceGradit.pdf p33, p36, p38.
//

import SwiftUI

struct FacultyAttendanceView: View {
    /// Hidden when embedded under another screen's header (e.g. management reuse).
    var showsHeader: Bool = true

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: FacultyAttendanceViewModel?
    @State private var rejecting: StudentLeaveRequest?

    var body: some View {
        VStack(spacing: 0) {
            if showsHeader { header }
            if let model {
                tabBar(model)
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = FacultyAttendanceViewModel(service: dependencies.attendanceService) }
            await model?.load()
        }
        .sheet(item: $rejecting) { leave in
            RejectLeaveSheet(leave: leave) { model?.respond(to: leave, decision: .rejected) }
                .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            // Pushed from a menu tile → back button; tab root → none.
            if isPresented {
                TopBarBackButton { dismiss() }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Attendance").font(AppFont.jakarta(24, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("Dr. Meena Krishnan · CSE").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func tabBar(_ model: FacultyAttendanceViewModel) -> some View {
        HStack(spacing: 4) {
            segment(model, tab: .classes, title: String(localized: "Classes"), count: model.classes.count)
            segment(model, tab: .leaveRequests, title: String(localized: "Leave requests"), count: model.pendingLeaveCount)
        }
        .padding(4)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func segment(_ model: FacultyAttendanceViewModel, tab: FacultyAttendanceViewModel.Tab,
                         title: String, count: Int) -> some View {
        let isOn = model.tab == tab
        return Button { model.tab = tab } label: {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .font(AppFont.jakarta(12, .heavy))
                    .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                    .padding(.horizontal, 7).frame(minHeight: 20)
                    .background(isOn ? Theme.Colors.blue600 : Theme.Colors.blue50, in: Capsule())
            }
            .font(AppFont.jakarta(15, .bold))
            .foregroundStyle(isOn ? Theme.Colors.ink900 : Theme.Colors.ink500)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
            .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    @ViewBuilder
    private func content(_ model: FacultyAttendanceViewModel) -> some View {
        if let error = model.errorMessage, model.classes.isEmpty {
            ErrorStateView(message: error) { model.reload() }.frame(maxHeight: .infinity)
        } else if model.isLoading, model.classes.isEmpty {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if model.tab == .classes { classesContent(model) } else { leavesContent(model) }
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    // MARK: - Classes

    private func classesContent(_ model: FacultyAttendanceViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            WeekStrip()
            HStack {
                Text("Today, Tue 06 Oct").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                if model.pendingClassCount > 0 {
                    StatusBadge(text: "\(model.pendingClassCount) pending", tone: .amber, weight: .heavy)
                }
            }
            ForEach(model.classes) { session in
                classCard(session)
            }
        }
    }

    private func classCard(_ session: FacultyClassSession) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                IconTile(systemImage: "book.closed", size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.subject).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(session.classLabel).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
                    Text(session.room).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                Text("\(session.period) · \(session.time)")
                    .font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.blue700)
                    .padding(.horizontal, 10).frame(height: 28)
                    .background(Theme.Colors.blue50, in: Capsule())
            }
            .padding(14)

            Rectangle().fill(Theme.Colors.divider).frame(height: 1)

            HStack {
                if let taken = session.takenCount {
                    StatusBadge(text: "Taken · \(taken) / \(session.total)", tone: .green, weight: .heavy)
                    Spacer()
                    Button("Edit") { router.push(.markAttendance(session)) }
                        .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.blue600)
                        .padding(.horizontal, 18).frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
                } else {
                    StatusBadge(text: "Pending", tone: .amber, weight: .heavy)
                    Spacer()
                    Button { router.push(.markAttendance(session)) } label: {
                        Label("Take attendance", systemImage: "calendar.badge.checkmark")
                            .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.white)
                            .padding(.horizontal, 16).frame(height: 44)
                            .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(14)
        }
        .dashboardCard(radius: 16, border: session.isTaken ? Theme.Colors.line : Theme.Colors.amberBorder, borderWidth: session.isTaken ? 1 : 1.5)
    }

    // MARK: - Leave requests

    private func leavesContent(_ model: FacultyAttendanceViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ForEach(LeaveStatus.allCases) { status in
                    let isOn = model.leaveFilter == status
                    Button("\(status.title) \(model.leaveCount(status))") { model.leaveFilter = status }
                        .font(AppFont.jakarta(13, isOn ? .bold : .semibold))
                        .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 14).frame(height: 36)
                        .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                        .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
            if model.visibleLeaves.isEmpty {
                Text("No \(model.leaveFilter.title.lowercased()) requests.")
                    .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500)
                    .frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                ForEach(model.visibleLeaves) { leave in
                    leaveCard(model, leave: leave)
                }
            }
        }
    }

    private func leaveCard(_ model: FacultyAttendanceViewModel, leave: StudentLeaveRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                InitialsAvatar(initials: DashboardGreeting.initials(leave.studentName), size: 40,
                               foreground: Theme.Colors.green700, background: Theme.Colors.green50)
                VStack(alignment: .leading, spacing: 1) {
                    Text(leave.studentName).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(leave.classLabel).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                StatusBadge(text: leave.leaveType, tone: .blueSoft)
                Text(leave.appliedText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            HStack(spacing: 8) {
                leaveBox(title: "From", value: leave.fromText)
                leaveBox(title: "To", value: leave.toText)
                leaveBox(title: "Days", value: "\(leave.days)", emphasized: true)
            }
            Text(leave.reason)
                .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
                .lineSpacing(2).fixedSize(horizontal: false, vertical: true)

            if leave.status == .pending {
                HStack(spacing: 12) {
                    Button("Reject") { rejecting = leave }
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.destructive)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.destructive))
                    Button { model.respond(to: leave, decision: .approved) } label: {
                        Text("Approve").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            } else {
                StatusBadge(text: leave.status.title, tone: leave.status == .approved ? .green : .red, weight: .heavy)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func leaveBox(title: LocalizedStringKey, value: String, emphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            Text(value).font(AppFont.jakarta(15, .heavy)).foregroundStyle(emphasized ? Theme.Colors.blue700 : Theme.Colors.ink900)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(emphasized ? Theme.Colors.blue50 : Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))
    }
}

/// Mon–Sat day strip for the current week (display of the design's selector).
private struct WeekStrip: View {
    private let days: [(String, Int)] = [("Sun", 4), ("Mon", 5), ("Tue", 6), ("Wed", 7), ("Thu", 8), ("Fri", 9), ("Sat", 10)]
    @State private var selected = 6

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "chevron.left").foregroundStyle(Theme.Colors.ink500)
                Spacer()
                Text("4 Oct – 10 Oct 2026").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.Colors.ink500)
            }
            HStack(spacing: 6) {
                ForEach(days, id: \.1) { day in
                    let isOn = selected == day.1
                    Button { selected = day.1 } label: {
                        VStack(spacing: 4) {
                            Text(day.0).font(AppFont.jakarta(11, .semibold))
                                .foregroundStyle(isOn ? Theme.Colors.white.opacity(0.9) : Theme.Colors.ink500)
                            Text("\(day.1)").font(AppFont.jakarta(16, .heavy))
                                .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink900)
                        }
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(isOn ? Theme.Colors.blue600 : .clear, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .dashboardCard(radius: 16)
    }
}

/// Reject-leave bottom sheet (reason + quick reasons). Design p38.
private struct RejectLeaveSheet: View {
    let leave: StudentLeaveRequest
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""

    private let quickReasons = ["Exam week", "Certificate not valid", "Incomplete details"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reject leave request?").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("\(leave.studentName) · \(leave.leaveType) · \(leave.fromText)–\(leave.toText)")
                        .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reason for rejection *").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
                    TextEditor(text: $reason)
                        .font(AppFont.jakarta(15)).scrollContentBackground(.hidden)
                        .frame(minHeight: 110).padding(10)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
                    Text("The student and parent will see this reason.")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick reasons").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
                    FlowLayout(spacing: 8) {
                        ForEach(quickReasons, id: \.self) { quick in
                            let isOn = reason == quick
                            Button(quick) { reason = quick }
                                .font(AppFont.jakarta(13, .bold))
                                .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                                .padding(.horizontal, 14).frame(height: 36)
                                .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                                .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button { onConfirm(); dismiss() } label: {
                    Text("Confirm reject").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.Colors.destructive, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(reason.trimmed.isEmpty)
                .opacity(reason.trimmed.isEmpty ? 0.5 : 1)
                Button("Cancel") { dismiss() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
            .background(Theme.Colors.white)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }
}

#Preview {
    let deps = AppDependencies(
        apiClient: APIClient(baseURL: AppConfig.baseURL),
        userService: MockUserService(),
        authService: MockAuthService(latency: .zero),
        dashboardService: MockDashboardService(latency: .zero),
        profileService: MockProfileService(latency: .zero),
        discussionService: MockDiscussionService(latency: .zero),
        messagingService: MockMessagingService(latency: .zero),
        attendanceService: MockAttendanceService(latency: .zero)
    )
    return NavigationStack { FacultyAttendanceView() }
        .environment(AppRouter())
        .environment(deps)
}
