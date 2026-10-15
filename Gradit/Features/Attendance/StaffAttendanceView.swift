//
//  StaffAttendanceView.swift
//  Gradit
//
//  Management / faculty "Attendance" tab: Today staff punch-in + monthly
//  Staff-wise report. Design: attendanceGradit.pdf p1–6.
//

import SwiftUI

struct StaffAttendanceView: View {
    let role: UserRole
    var initialTab: StaffAttendanceViewModel.Tab = .today

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: StaffAttendanceViewModel?

    init(role: UserRole, initialTab: StaffAttendanceViewModel.Tab = .today) {
        self.role = role
        self.initialTab = initialTab
    }

    var body: some View {
        VStack(spacing: 0) {
            header
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
            if model == nil {
                let created = StaffAttendanceViewModel(service: dependencies.attendanceService)
                created.tab = initialTab
                model = created
            }
            await model?.load()
        }
    }

    // MARK: - Header & tabs

    private var header: some View {
        HStack(spacing: 12) {
            // Pushed from a menu tile → back button; tab root → none.
            if isPresented {
                TopBarBackButton { dismiss() }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Attendance")
                    .font(AppFont.jakarta(24, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                Text("UCE Chennai · 102 teaching staff")
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func tabBar(_ model: StaffAttendanceViewModel) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 22) {
                tabButton(model, tab: .today, title: String(localized: "Today"), count: model.today?.total ?? 102)
                tabButton(model, tab: .staffWise, title: String(localized: "Staff-wise"), count: model.today?.total ?? 102)
                tabButton(model, tab: .report, title: String(localized: "Report"), count: nil)
                tabButton(model, tab: .classes, title: String(localized: "Classes"), count: nil)
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
    }

    private func tabButton(_ model: StaffAttendanceViewModel, tab: StaffAttendanceViewModel.Tab,
                           title: String, count: Int?) -> some View {
        let isOn = model.tab == tab
        return Button {
            model.select(tab: tab)
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    if let count {
                        Text("\(count)")
                            .font(AppFont.jakarta(12, .heavy))
                            .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                            .padding(.horizontal, 8)
                            .frame(height: 22)
                            .background(isOn ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted, in: Capsule())
                    }
                    Text(title)
                        .font(AppFont.jakarta(15, .bold))
                        .foregroundStyle(isOn ? Theme.Colors.blue700 : Theme.Colors.ink500)
                }
                Rectangle()
                    .fill(isOn ? Theme.Colors.blue600 : .clear)
                    .frame(height: 2)
            }
            .padding(.top, 4)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ model: StaffAttendanceViewModel) -> some View {
        switch model.tab {
        case .report:
            // Management/principal also see the aggregate attendance report.
            AttendanceReportView(role: role)
        case .classes:
            // ...and the teacher's Classes / Leave-requests screen (header suppressed).
            FacultyAttendanceView(showsHeader: false)
        case .today, .staffWise:
            staffContent(model)
        }
    }

    @ViewBuilder
    private func staffContent(_ model: StaffAttendanceViewModel) -> some View {
        let data = model.tab == .today ? (model.today != nil) : (model.monthly != nil)
        if !data {
            if model.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = model.errorMessage {
                ErrorStateView(message: error) { model.reload() }.frame(maxHeight: .infinity)
            } else {
                Spacer()
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if model.tab == .today { todayContent(model) } else { staffWiseContent(model) }
                    footerNote
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { await model.load() }
        }
    }

    // MARK: - Today

    @ViewBuilder
    private func todayContent(_ model: StaffAttendanceViewModel) -> some View {
        if let today = model.today {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(today.dateLabel)
                        .font(AppFont.jakarta(18, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text(today.lastUpdated)
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                Button { model.reload() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.blue600)
                        .frame(width: 44, height: 44)
                        .dashboardCard(radius: 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh")
            }

            todayStatGrid(model, today: today)
            searchField(model)
            filterPills(model)

            if model.statusFilter != nil {
                HStack(spacing: 8) {
                    activeChip(model.statusFilter!.groupTitle) { model.statusFilter = nil }
                    Button("Reset all") { model.clearTodayFilter() }
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(Theme.Colors.destructive)
                        .buttonStyle(.plain)
                    Spacer(minLength: 0)
                }
            }

            countRow(title: "\(model.todayVisibleCount) staff · today",
                     fileName: "Attendance_07-Oct-2026")

            if model.todaySections.isEmpty {
                noMatchCard(model)
            } else {
                ForEach(model.todaySections, id: \.status) { section in
                    staffGroup(status: section.status, staff: section.staff)
                }
            }
        }
    }

    private func todayStatGrid(_ model: StaffAttendanceViewModel, today: StaffAttendanceToday) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            todayStatCard(model, status: nil, value: today.total, label: String(localized: "Total staff"))
            todayStatCard(model, status: .present, value: today.present, label: String(localized: "Present"))
            todayStatCard(model, status: .absent, value: today.absent, label: String(localized: "Absent"))
            todayStatCard(model, status: .onLeave, value: today.onLeave, label: String(localized: "On leave"))
            todayStatCard(model, status: .late, value: today.late, label: String(localized: "Late"))
            todayStatCard(model, status: .notPunchedIn, value: today.notPunchedIn, label: String(localized: "Not punched in yet"))
        }
    }

    private func todayStatCard(_ model: StaffAttendanceViewModel, status: StaffStatus?, value: Int, label: String) -> some View {
        let palette = status.map { StatusColors.of($0) }
        let isOn = model.statusFilter == status
        let background = palette?.soft ?? Theme.Colors.white
        let valueColor = palette?.strong ?? Theme.Colors.ink900
        return Button {
            if let status { model.toggleStatusFilter(status) } else { model.statusFilter = nil }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(value)")
                    .font(AppFont.jakarta(22, .heavy))
                    .foregroundStyle(valueColor)
                Text(label)
                    .font(AppFont.jakarta(12, .bold))
                    .foregroundStyle(Theme.Colors.ink700)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
            .padding(12)
            .background(background, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isOn ? Theme.Colors.blue600 : Theme.Colors.line, lineWidth: isOn ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private func staffGroup(status: StaffStatus, staff: [StaffMember]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(StatusColors.of(status).strong).frame(width: 10, height: 10)
                Text("\(status.groupTitle) · \(staff.count)")
                    .font(AppFont.jakarta(14, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)

            ForEach(Array(staff.enumerated()), id: \.element.id) { index, member in
                if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1).padding(.horizontal, 14) }
                staffRow(member)
            }
        }
        .dashboardCard(radius: 16)
    }

    private func staffRow(_ member: StaffMember) -> some View {
        let colors = StatusColors.of(member.status)
        return HStack(alignment: .top, spacing: 12) {
            InitialsAvatar(initials: DashboardGreeting.initials(member.name), size: 44,
                           foreground: colors.strong, background: colors.soft)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(member.name)
                        .font(AppFont.jakarta(15, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Spacer(minLength: 0)
                    StatusBadge(text: member.status.groupTitle, tone: colors.tone,
                                systemImage: member.status == .late ? "clock" : (member.status == .absent ? "xmark" : nil))
                }
                Text("\(member.department) · \(member.designation)")
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
                    .fixedSize(horizontal: false, vertical: true)
                Text(member.detail)
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
                if let note = member.freePeriodsNote {
                    HStack(spacing: 6) {
                        Image(systemName: "clock").font(.system(size: 11, weight: .bold))
                        Text(note).font(AppFont.jakarta(12, .bold))
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Theme.Colors.amber800)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 10))
                    .padding(.top, 2)
                }
            }
        }
        .padding(14)
        .contentShape(.rect)
    }

    // MARK: - Staff-wise

    @ViewBuilder
    private func staffWiseContent(_ model: StaffAttendanceViewModel) -> some View {
        if let monthly = model.monthly {
            HStack(spacing: 10) {
                menuPill(label: "Year", value: "\(model.year)") {
                    ForEach(model.years, id: \.self) { y in
                        Button("\(y)") { model.year = y; model.reload() }
                    }
                }
                menuPill(label: "Month", value: model.monthLabel) {
                    Button("All months") { model.month = nil; model.reload() }
                    ForEach(1...12, id: \.self) { m in
                        Button(monthName(m)) { model.month = m; model.reload() }
                    }
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                monthlyStatCard(value: "\(monthly.averagePercent)%", label: String(localized: "Average attendance"),
                                background: Theme.Colors.white, valueColor: Theme.Colors.ink900, selectable: false, isOn: false) {}
                monthlyStatCard(value: "\(monthly.belowThreshold)", label: String(localized: "Staff below 75%"),
                                background: Theme.Colors.errorBackground, valueColor: Theme.Colors.red700,
                                selectable: true, isOn: model.belowThresholdOnly) { model.belowThresholdOnly.toggle() }
                monthlyStatCard(value: "\(monthly.workingDays)", label: String(localized: "Working days"),
                                background: Theme.Colors.white, valueColor: Theme.Colors.ink900, selectable: false, isOn: false) {}
                monthlyStatCard(value: "\(monthly.leaveDays)", label: String(localized: "Leave days"),
                                background: Theme.Colors.warningBackground, valueColor: Theme.Colors.amber800, selectable: false, isOn: false) {}
            }

            searchField(model)
            filterPills(model)

            if model.belowThresholdOnly {
                HStack(spacing: 8) {
                    activeChip(String(localized: "Below 75%")) { model.belowThresholdOnly = false }
                    Button("Reset all") { model.belowThresholdOnly = false; model.searchText = "" }
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(Theme.Colors.destructive)
                        .buttonStyle(.plain)
                    Spacer(minLength: 0)
                }
            }

            countRow(title: "\(model.monthlyVisible.count) staff · \(model.monthLabel)",
                     fileName: "Attendance_\(model.monthLabel.replacingOccurrences(of: " ", with: "-"))")

            if model.monthlyVisible.isEmpty {
                noMatchCard(model)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.monthlyVisible.enumerated()), id: \.element.id) { index, row in
                        if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                        monthlyRow(row)
                    }
                }
                .dashboardCard(radius: 16)
            }
        }
    }

    private func monthlyStatCard(value: String, label: String, background: Color, valueColor: Color,
                                 selectable: Bool, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(AppFont.jakarta(22, .heavy)).foregroundStyle(valueColor)
                Text(label).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink700).lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
            .padding(12)
            .background(background, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14).strokeBorder(isOn ? Theme.Colors.blue600 : Theme.Colors.line, lineWidth: isOn ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
    }

    private func monthlyRow(_ row: StaffMonthlyRow) -> some View {
        let tone: Color = row.percent >= 85 ? Theme.Colors.green700 : (row.percent >= 75 ? Theme.Colors.amber800 : Theme.Colors.red700)
        return HStack(spacing: 12) {
            InitialsAvatar(initials: DashboardGreeting.initials(row.name), size: 44,
                           foreground: Theme.Colors.green700, background: Theme.Colors.green50)
            VStack(alignment: .leading, spacing: 4) {
                Text(row.name).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("\(row.department) · \(row.designation)")
                    .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                HStack(spacing: 8) {
                    GeometryReader { proxy in
                        Capsule().fill(Theme.Colors.line)
                            .overlay(alignment: .leading) {
                                Capsule().fill(tone).frame(width: proxy.size.width * CGFloat(row.percent) / 100)
                            }
                    }
                    .frame(height: 6)
                    Text("\(row.percent)%").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                }
                HStack(spacing: 14) {
                    statLabel("P", row.present, Theme.Colors.green700)
                    statLabel("A", row.absent, Theme.Colors.red700)
                    statLabel("L", row.leave, Theme.Colors.amber800)
                    statLabel("Late", row.late, Theme.Colors.ink700)
                    Spacer(minLength: 0)
                }
            }
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.chevron)
        }
        .padding(14)
        .contentShape(.rect)
    }

    private func statLabel(_ key: String, _ value: Int, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(key).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            Text("\(value)").font(AppFont.jakarta(12, .heavy)).foregroundStyle(color)
        }
    }

    // MARK: - Shared pieces

    private func searchField(_ model: StaffAttendanceViewModel) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.Colors.ink500)
            TextField("Search name or employee ID", text: Binding(
                get: { model.searchText }, set: { model.searchText = $0 }
            ))
            .font(AppFont.jakarta(15))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .dashboardCard(radius: 14)
    }

    private func filterPills(_ model: StaffAttendanceViewModel) -> some View {
        HStack(spacing: 10) {
            menuPill(label: "Stream", value: "All") { Button("All") {} }
            menuPill(label: "Department", value: model.department) {
                ForEach(model.departments, id: \.self) { dept in
                    Button(dept) { model.department = dept }
                }
            }
        }
    }

    private func menuPill<Content: View>(label: LocalizedStringKey, value: String,
                                         @ViewBuilder menuItems: () -> Content) -> some View {
        Menu {
            menuItems()
        } label: {
            HStack(spacing: 6) {
                Text(label).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                Text(value).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900).lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .dashboardCard(radius: 14)
        }
        .buttonStyle(.plain)
    }

    private func activeChip(_ text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(text).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue700)
            Button(action: onRemove) {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.Colors.blue700)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 12).padding(.trailing, 10)
        .frame(height: 32)
        .background(Theme.Colors.blue50, in: Capsule())
    }

    private func countRow(title: String, fileName: String) -> some View {
        HStack {
            Text(title).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Spacer()
            ShareLink(item: "\(fileName).pdf") {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Export")
                }
                .font(AppFont.jakarta(14, .bold))
                .foregroundStyle(Theme.Colors.blue600)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .dashboardCard(radius: 12)
            }
        }
    }

    private func noMatchCard(_ model: StaffAttendanceViewModel) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "person.crop.circle.badge.questionmark", size: 56, radius: 18)
            Text("No staff match").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("Try another search or filter.").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            Button("Reset filters") {
                model.clearTodayFilter(); model.belowThresholdOnly = false; model.department = "All"
            }
            .font(AppFont.jakarta(14, .bold))
            .foregroundStyle(Theme.Colors.blue600)
            .padding(.horizontal, 16).frame(height: 44)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .dashboardCard(radius: 18)
    }

    private var footerNote: some View {
        VStack(spacing: 12) {
            Text("Sundays and holidays aren’t counted as absent. Late = punch-in after 09:00 AM. Attendance % = present days ÷ working days.")
                .font(AppFont.jakarta(12))
                .foregroundStyle(Theme.Colors.ink500)
                .fixedSize(horizontal: false, vertical: true)
            PoweredByFooter()
        }
        .padding(.top, 8)
    }

    private func monthName(_ month: Int) -> String {
        let symbols = DateFormatter().standaloneMonthSymbols ?? []
        return symbols.indices.contains(month - 1) ? symbols[month - 1] : "\(month)"
    }
}

// MARK: - Status colours

private enum StatusColors {
    static func of(_ status: StaffStatus) -> (strong: Color, soft: Color, tone: StatusBadge.Tone) {
        switch status {
        case .present: (Theme.Colors.green700, Theme.Colors.green50, .green)
        case .absent: (Theme.Colors.red700, Theme.Colors.errorBackground, .red)
        case .onLeave: (Theme.Colors.amber800, Theme.Colors.warningBackground, .amber)
        case .late: (Theme.Colors.amber800, Theme.Colors.warningBackground, .amber)
        case .notPunchedIn: (Theme.Colors.ink700, Theme.Colors.surfaceMuted, .neutral)
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
    return NavigationStack { StaffAttendanceView(role: .management) }
        .environment(AppRouter())
        .environment(deps)
}

#Preview("Staff-wise") {
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
    return NavigationStack { StaffAttendanceView(role: .management, initialTab: .staffWise) }
        .environment(AppRouter())
        .environment(deps)
}

#Preview("Report") {
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
    return NavigationStack { StaffAttendanceView(role: .management, initialTab: .report) }
        .environment(AppRouter())
        .environment(deps)
}

#Preview("Classes") {
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
    return NavigationStack { StaffAttendanceView(role: .management, initialTab: .classes) }
        .environment(AppRouter())
        .environment(deps)
}
