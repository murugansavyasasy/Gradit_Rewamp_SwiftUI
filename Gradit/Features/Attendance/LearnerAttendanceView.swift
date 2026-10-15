//
//  LearnerAttendanceView.swift
//  Gradit
//
//  Student / parent attendance: overall ring, month calendar, subject-wise and
//  leave history + apply leave. Design: attendanceGradit.pdf p39–44.
//

import SwiftUI

struct LearnerAttendanceView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @State private var model: LearnerAttendanceViewModel?
    @State private var selectedDay: DaySelection?
    @State private var isApplying = false

    private struct DaySelection: Identifiable { let day: Int; var id: Int { day } }

    var body: some View {
        Group {
            if let model, let data = model.data {
                content(model, data: data)
            } else if model?.errorMessage != nil, let model {
                ErrorStateView(message: model.errorMessage ?? "") { model.reload() }
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle("Attendance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: "Attendance.pdf") { Image(systemName: "square.and.arrow.down") }
                    .accessibilityLabel("Download")
            }
        }
        .task {
            if model == nil { model = LearnerAttendanceViewModel(role: role, service: dependencies.attendanceService) }
            await model?.load()
        }
        .sheet(item: $selectedDay) { selection in
            if let data = model?.data {
                DayPeriodsSheet(day: selection.day, month: data.monthLabel, periods: data.periods)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $isApplying) {
            if let data = model?.data { ApplyLeaveSheet(student: data) }
        }
    }

    private func content(_ model: LearnerAttendanceViewModel, data: LearnerAttendance) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    primaryTabs(model, data: data)
                    if model.primaryTab == .attendance {
                        ringCard(data)
                        secondaryTabs(model)
                        if model.secondaryTab == .calendar {
                            calendarCard(model, data: data)
                            dayStats(data)
                        } else {
                            ForEach(data.subjects) { subjectCard($0) }
                        }
                    } else {
                        ForEach(data.leaves) { leaveCard($0) }
                    }
                }
                .padding(16).padding(.bottom, 90)
            }
            .scrollIndicators(.hidden)

            if model.primaryTab == .leaveHistory {
                Button { isApplying = true } label: {
                    Label("Apply leave", systemImage: "plus")
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                        .padding(.horizontal, 18).frame(height: 52)
                        .background(Theme.Colors.blue600, in: Capsule())
                        .shadow(color: Color(hex: 0x101828, opacity: 0.22), radius: 12, y: 6)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(20)
            }
        }
    }

    // MARK: - Tabs

    private func primaryTabs(_ model: LearnerAttendanceViewModel, data: LearnerAttendance) -> some View {
        HStack(spacing: 4) {
            primarySegment(model, tab: .attendance, title: String(localized: "Attendance"), count: nil)
            primarySegment(model, tab: .leaveHistory, title: String(localized: "Leave history"), count: data.leaves.count)
        }
        .padding(4).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
    }

    private func primarySegment(_ model: LearnerAttendanceViewModel, tab: LearnerAttendanceViewModel.PrimaryTab,
                                title: String, count: Int?) -> some View {
        let isOn = model.primaryTab == tab
        return Button { model.primaryTab = tab } label: {
            HStack(spacing: 6) {
                Text(title)
                if let count {
                    Text("\(count)").font(AppFont.jakarta(12, .heavy))
                        .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 7).frame(minHeight: 20)
                        .background(isOn ? Theme.Colors.blue600 : Theme.Colors.blue50, in: Capsule())
                }
            }
            .font(AppFont.jakarta(15, .bold)).foregroundStyle(isOn ? Theme.Colors.ink900 : Theme.Colors.ink500)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
            .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func secondaryTabs(_ model: LearnerAttendanceViewModel) -> some View {
        HStack(spacing: 4) {
            ForEach(LearnerAttendanceViewModel.SecondaryTab.allCases) { tab in
                let isOn = model.secondaryTab == tab
                Button(tab == .calendar ? "Calendar" : "Subject-wise") { model.secondaryTab = tab }
                    .font(AppFont.jakarta(15, isOn ? .bold : .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.ink900 : Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                    .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
                    .buttonStyle(.plain)
            }
        }
        .padding(4).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
    }

    // MARK: - Ring

    private func ringCard(_ data: LearnerAttendance) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Theme.Colors.green100, lineWidth: 9)
                Circle().trim(from: 0, to: CGFloat(data.overallPercent) / 100)
                    .stroke(Theme.Colors.green600, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(data.overallPercent)%").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.green700)
            }
            .frame(width: 92, height: 92)
            VStack(alignment: .leading, spacing: 4) {
                Text(data.rangeLabel).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
                Text("Present \(data.presentDays) of \(data.totalDays) days")
                    .font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                if data.meetsRequirement {
                    Label("Above 75% required", systemImage: "checkmark")
                        .font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.green700)
                        .padding(.horizontal, 10).frame(height: 26)
                        .background(Theme.Colors.green50, in: Capsule())
                } else {
                    Text("Below the 75% minimum")
                        .font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.red700)
                        .padding(.horizontal, 10).frame(height: 26)
                        .background(Theme.Colors.errorBackground, in: Capsule())
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 18)
    }

    // MARK: - Calendar

    private func calendarCard(_ model: LearnerAttendanceViewModel, data: LearnerAttendance) -> some View {
        VStack(spacing: 12) {
            Text(data.monthLabel).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { d in
                    Text(d).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500).frame(height: 24)
                }
                ForEach(0..<data.firstWeekday, id: \.self) { _ in Color.clear.frame(height: 40) }
                ForEach(1...data.daysInMonth, id: \.self) { day in
                    dayCell(model, day: day)
                }
            }
            legend
            Text("Tap a marked day to see period-wise attendance.")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16).dashboardCard(radius: 18)
    }

    private func dayCell(_ model: LearnerAttendanceViewModel, day: Int) -> some View {
        let status = model.status(forDay: day)
        let colors = DayColors.of(status)
        let isToday = model.isToday(day)
        return Button {
            if status != .none { selectedDay = DaySelection(day: day) }
        } label: {
            Text("\(day)")
                .font(AppFont.jakarta(13, .bold))
                .foregroundStyle(colors.fg)
                .frame(maxWidth: .infinity).frame(height: 40)
                .background(colors.bg, in: .rect(cornerRadius: 10))
                .overlay {
                    if isToday { RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.Colors.blue600, lineWidth: 2) }
                }
        }
        .buttonStyle(.plain)
        .disabled(status == .none)
    }

    private var legend: some View {
        FlowLayout(spacing: 12) {
            legendItem(.present, "Present"); legendItem(.absent, "Absent"); legendItem(.partlyPresent, "Partly present")
            legendItem(.onLeave, "On leave"); legendItem(.holiday, "Holiday")
            HStack(spacing: 6) {
                Circle().strokeBorder(Theme.Colors.blue600, lineWidth: 2).frame(width: 12, height: 12)
                Text("Today").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink700)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendItem(_ status: LearnerDayStatus, _ label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(DayColors.of(status).bg).overlay(Circle().strokeBorder(DayColors.of(status).fg.opacity(0.5)))
                .frame(width: 12, height: 12)
            Text(label).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink700)
        }
    }

    private func dayStats(_ data: LearnerAttendance) -> some View {
        let present = data.days.filter { $0.status == .present }.count
        let absent = data.days.filter { $0.status == .absent }.count
        let leave = data.days.filter { $0.status == .onLeave }.count
        return HStack(spacing: 10) {
            dayStatBox("\(present)", "Days present")
            dayStatBox("\(absent)", "Days absent")
            dayStatBox("\(leave)", "Days on leave")
        }
    }

    private func dayStatBox(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(label).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14).dashboardCard(radius: 14)
    }

    // MARK: - Subject-wise

    private func subjectCard(_ subject: LearnerSubject) -> some View {
        let tone = subject.isLow ? Theme.Colors.red700 : (subject.percent >= 85 ? Theme.Colors.green700 : Theme.Colors.amber800)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                IconTile(systemImage: "book.closed", size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(subject.name).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subject.teacher).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                Text("\(subject.percent)%").font(AppFont.jakarta(18, .heavy)).foregroundStyle(tone)
            }
            GeometryReader { proxy in
                Capsule().fill(Theme.Colors.line)
                    .overlay(alignment: .leading) { Capsule().fill(tone).frame(width: proxy.size.width * CGFloat(subject.percent) / 100) }
            }
            .frame(height: 8)
            HStack(spacing: 8) {
                Label("\(subject.hoursAttended) hours attended", systemImage: "checkmark")
                    .font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.green700)
                    .padding(.horizontal, 10).frame(height: 30).background(Theme.Colors.green50, in: Capsule())
                Label("\(subject.hoursAbsent) hour absent", systemImage: "xmark")
                    .font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.red700)
                    .padding(.horizontal, 10).frame(height: 30).background(Theme.Colors.errorBackground, in: Capsule())
                Spacer(minLength: 0)
            }
        }
        .padding(16).dashboardCard(radius: 16)
    }

    // MARK: - Leave history

    private func leaveCard(_ leave: LearnerLeave) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(leave.type).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(leave.appliedOn).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer()
                StatusBadge(text: leave.status == .pending ? String(localized: "Waiting for approval") : leave.status.title,
                            tone: leave.status == .approved ? .green : (leave.status == .rejected ? .red : .amber), weight: .heavy)
            }
            HStack(spacing: 8) {
                leaveBox("From", leave.fromText)
                leaveBox("To", leave.toText)
                leaveBox("Days", "\(leave.days)", emphasized: true)
            }
            Text(leave.reason).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
                .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
            if let note = leave.note {
                Text(note).font(AppFont.jakarta(12, .semibold))
                    .foregroundStyle(leave.status == .rejected ? Theme.Colors.red700 : Theme.Colors.ink500)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(leave.status == .rejected ? 10 : 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(leave.status == .rejected ? Theme.Colors.errorBackground : .clear,
                                in: .rect(cornerRadius: 10))
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func leaveBox(_ title: LocalizedStringKey, _ value: String, emphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            Text(value).font(AppFont.jakarta(15, .heavy)).foregroundStyle(emphasized ? Theme.Colors.blue700 : Theme.Colors.ink900)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.vertical, 8)
        .background(emphasized ? Theme.Colors.blue50 : Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))
    }
}

// MARK: - Day colours

private enum DayColors {
    static func of(_ status: LearnerDayStatus) -> (fg: Color, bg: Color) {
        switch status {
        case .present: (Theme.Colors.green700, Theme.Colors.green50)
        case .absent: (Theme.Colors.red700, Theme.Colors.errorBackground)
        case .partlyPresent: (Theme.Colors.amber800, Theme.Colors.warningBackground)
        case .onLeave: (Theme.Colors.blue700, Theme.Colors.blue50)
        case .holiday: (Theme.Colors.ink500, Theme.Colors.surfaceMuted)
        case .none: (Theme.Colors.ink900, Color.clear)
        }
    }
}

// MARK: - Day periods sheet (p40)

private struct DayPeriodsSheet: View {
    let day: Int
    let month: String
    let periods: [LearnerDayPeriod]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(dayPrefix) \(day) \(monthShort) 2026")
                            .font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        StatusBadge(text: "\(periods.filter(\.present).count) of \(periods.count) periods present", tone: .amber, weight: .heavy)
                    }
                    Spacer()
                }
                VStack(spacing: 0) {
                    ForEach(Array(periods.enumerated()), id: \.element.id) { index, period in
                        if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                        HStack(spacing: 12) {
                            Text(period.id).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.blue700)
                                .frame(width: 40, height: 40).background(Theme.Colors.blue50, in: .rect(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(period.subject).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                                Text(period.time).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                            }
                            Spacer(minLength: 0)
                            StatusBadge(text: period.present ? String(localized: "Present") : String(localized: "Absent"),
                                        tone: period.present ? .green : .red, weight: .heavy)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.ink700).frame(width: 40, height: 40).dashboardCard(radius: 20) }
                .buttonStyle(.plain).padding(16)
        }
    }

    private var dayPrefix: String { "Mon," }
    private var monthShort: String { "Oct" }
}

// MARK: - Apply leave sheet (p43)

private struct ApplyLeaveSheet: View {
    let student: LearnerAttendance
    @Environment(\.dismiss) private var dismiss
    @State private var leaveType = "Casual leave"
    @State private var from = Date.now
    @State private var to = Date.now
    @State private var reason = ""

    private let types = ["Casual leave", "Sick leave", "On duty", "Medical leave"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        InitialsAvatar(initials: DashboardGreeting.initials(student.studentName), size: 40)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(student.studentName).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                            Text(student.classLabel).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        }
                        Spacer()
                        Text("\(student.overallPercent)%").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.green700)
                            .padding(.horizontal, 10).frame(height: 28).background(Theme.Colors.green50, in: Capsule())
                    }
                    .padding(14).dashboardCard(radius: 16)

                    field("Leave type") {
                        Menu {
                            ForEach(types, id: \.self) { t in Button(t) { leaveType = t } }
                        } label: {
                            HStack {
                                Text(leaveType).font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink900)
                                Spacer(); Image(systemName: "chevron.down").foregroundStyle(Theme.Colors.ink500)
                            }
                            .padding(.horizontal, 14).frame(height: 52).dashboardCard(radius: 12)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 10) {
                        field("From") { DatePicker("", selection: $from, displayedComponents: .date).labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).frame(height: 52).dashboardCard(radius: 12) }
                        field("To") { DatePicker("", selection: $to, in: from..., displayedComponents: .date).labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).frame(height: 52).dashboardCard(radius: 12) }
                    }

                    field("Reason") {
                        TextEditor(text: $reason).font(AppFont.jakarta(15)).scrollContentBackground(.hidden)
                            .frame(minHeight: 110).padding(10)
                            .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
                    }

                    Text("Your class advisor will review this request. You’ll get a notification when it’s approved or rejected.")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
            .background(Theme.Colors.white.ignoresSafeArea())
            .navigationTitle("Apply leave")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Submit request", isEnabled: !reason.trimmed.isEmpty) { dismiss() }
                    .padding(.horizontal, 20).padding(.vertical, 12).background(Theme.Colors.white)
            }
        }
    }

    private func field<Content: View>(_ label: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
            content()
        }
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
    return NavigationStack { LearnerAttendanceView(role: .student) }
        .environment(AppRouter())
        .environment(deps)
}
