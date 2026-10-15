//
//  AttendanceReportView.swift
//  Gradit
//
//  Management / staff Attendance report (the Attendance bottom-nav tab).
//  Design: 02 Management App › Attendance › Attendance report.
//

import SwiftUI

struct AttendanceReportView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @State private var model: AttendanceReportViewModel?

    init(role: UserRole) {
        self.role = role
    }

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle("Attendance report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: String(localized: "Gradit attendance report")) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share report")
            }
        }
        .task {
            if model == nil {
                model = AttendanceReportViewModel(service: dependencies.attendanceService)
            }
            if model?.report == nil { await model?.load() }
        }
    }

    private func content(_ model: AttendanceReportViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                rangeChips(model)
                dateRow(model)
                filtersRow(model)
                if model.hasActiveFilters { activeFilters(model) }
                audienceToggle(model)
                reportBody(model)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable { await model.load() }
    }

    // MARK: - Range

    private func rangeChips(_ model: AttendanceReportViewModel) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(AttendanceRange.allCases) { range in
                    let isOn = model.range == range
                    Button(range.title) { model.select(range: range) }
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(isOn ? Theme.Colors.ink900 : Theme.Colors.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isOn ? [.isSelected] : [])
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func dateRow(_ model: AttendanceReportViewModel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink500)
            Text(model.dateLabel)
                .font(AppFont.jakarta(14, .bold))
                .foregroundStyle(Theme.Colors.ink900)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 12)
    }

    // MARK: - Filters

    private func filtersRow(_ model: AttendanceReportViewModel) -> some View {
        HStack(spacing: 10) {
            filterPill(label: "Department", value: model.department, options: model.departments) {
                model.select(department: $0)
            }
            filterPill(label: "Year / Sem", value: model.yearSem, options: model.yearSems) {
                model.select(yearSem: $0)
            }
        }
    }

    private func filterPill(label: LocalizedStringKey, value: String, options: [String],
                            onSelect: @escaping (String) -> Void) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { onSelect(option) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
                Text(value)
                    .font(AppFont.jakarta(13, .bold))
                    .foregroundStyle(Theme.Colors.ink900)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .dashboardCard(radius: 12)
        }
        .buttonStyle(.plain)
    }

    private func activeFilters(_ model: AttendanceReportViewModel) -> some View {
        HStack(spacing: 8) {
            if model.department != "All" {
                filterChip(model.department) { model.select(department: "All") }
            }
            if model.yearSem != "All" {
                filterChip(model.yearSem) { model.select(yearSem: "All") }
            }
            Spacer(minLength: 0)
            Button("Clear all") { model.clearFilters() }
                .font(AppFont.jakarta(13, .bold))
                .foregroundStyle(Theme.Colors.blue600)
                .buttonStyle(.plain)
        }
    }

    private func filterChip(_ text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(AppFont.jakarta(13, .bold))
                .foregroundStyle(Theme.Colors.blue700)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.Colors.blue700)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(text)")
        }
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .frame(height: 32)
        .background(Theme.Colors.blue50, in: Capsule())
    }

    // MARK: - Audience

    private func audienceToggle(_ model: AttendanceReportViewModel) -> some View {
        HStack(spacing: 4) {
            ForEach(AttendanceAudience.allCases) { audience in
                let isOn = model.audience == audience
                Button(audience.title) { model.select(audience: audience) }
                    .font(AppFont.jakarta(15, isOn ? .bold : .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.ink900 : Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                    .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.line))
    }

    // MARK: - Body

    @ViewBuilder
    private func reportBody(_ model: AttendanceReportViewModel) -> some View {
        if let report = model.report {
            if report.stats.isEmpty {
                emptyState
            } else {
                statsGrid(report.stats)
                byPeriodCard(model, periods: report.byPeriod)
            }
        } else if model.isLoading {
            ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
        } else if let error = model.errorMessage {
            ErrorStateView(message: error) { model.reload() }
                .padding(.top, 40)
        }
    }

    private func statsGrid(_ stats: [AttendanceStat]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(stats) { AttendanceStatCard(stat: $0) }
        }
    }

    private func byPeriodCard(_ model: AttendanceReportViewModel, periods: [PeriodAttendance]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("By period · today")
                    .font(AppFont.jakarta(15, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Button(model.showTable ? "Show chart" : "Show table") {
                    withAnimation(.easeInOut(duration: 0.2)) { model.showTable.toggle() }
                }
                .font(AppFont.jakarta(13, .bold))
                .foregroundStyle(Theme.Colors.blue600)
                .buttonStyle(.plain)
            }

            if model.showTable {
                periodTable(periods)
            } else {
                PeriodBarChart(periods: periods)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 18)
    }

    private func periodTable(_ periods: [PeriodAttendance]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(periods.enumerated()), id: \.element.id) { index, period in
                HStack {
                    Text(period.id)
                        .font(AppFont.jakarta(14, .bold))
                        .foregroundStyle(Theme.Colors.ink700)
                    Spacer()
                    Text(DashboardFormat.percent(period.percent))
                        .font(AppFont.jakarta(14, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                }
                .frame(minHeight: 40)
                if index < periods.count - 1 {
                    Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "calendar.badge.exclamationmark", size: 56, radius: 18)
            Text("No attendance recorded")
                .font(AppFont.jakarta(15, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
            Text("Nothing was recorded for this day — it may be a holiday.")
                .font(AppFont.jakarta(13))
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Stat card

struct AttendanceStatCard: View {
    let stat: AttendanceStat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stat.title)
                .font(AppFont.jakarta(12, .bold))
                .foregroundStyle(Theme.Colors.ink500)
                .lineLimit(1)
            Text(stat.value)
                .font(AppFont.jakarta(stat.emphasized ? 26 : 22, .heavy))
                .foregroundStyle(stat.emphasized ? Theme.Colors.blue600 : Theme.Colors.ink900)
            HStack(spacing: 4) {
                Image(systemName: trendIcon)
                    .font(.system(size: 10, weight: .heavy))
                Text(stat.deltaText)
                    .lineLimit(1)
            }
            .font(AppFont.jakarta(11, .bold))
            .foregroundStyle(trendColor)
            Text("vs yesterday")
                .font(AppFont.jakarta(11))
                .foregroundStyle(Theme.Colors.ink500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .dashboardCard(radius: 16)
    }

    private var trendIcon: String {
        switch stat.trend {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .flat: "minus"
        }
    }

    private var trendColor: Color {
        switch stat.trend {
        case .up: Theme.Colors.green700
        case .down: Theme.Colors.red700
        case .flat: Theme.Colors.ink500
        }
    }
}

// MARK: - Bar chart

struct PeriodBarChart: View {
    let periods: [PeriodAttendance]
    private let maxBarHeight: CGFloat = 110

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(periods) { period in
                VStack(spacing: 6) {
                    Text(DashboardFormat.percent(period.percent))
                        .font(AppFont.jakarta(10, .bold))
                        .foregroundStyle(Theme.Colors.ink500)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.Colors.blue600)
                        .frame(height: max(8, maxBarHeight * period.percent / 100))
                    Text(period.id)
                        .font(AppFont.jakarta(11, .bold))
                        .foregroundStyle(Theme.Colors.ink700)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: maxBarHeight + 40, alignment: .bottom)
        .accessibilityLabel("Attendance by period")
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
    return NavigationStack {
        AttendanceReportView(role: .management)
    }
    .environment(AppRouter())
    .environment(deps)
}
