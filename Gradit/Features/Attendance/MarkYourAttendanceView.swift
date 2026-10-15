//
//  MarkYourAttendanceView.swift
//  Gradit
//
//  Personal "Mark Your Attendance" self check-in used by management and teachers:
//  live clock, location verification, a big check-in button and this month's
//  history. Design: attendanceGradit.pdf (Mark Your Attendance).
//

import SwiftUI

struct MarkYourAttendanceView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: SelfCheckInViewModel?

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model, let state = model.state {
                content(model, state: state)
            } else if let model, model.errorMessage != nil {
                ErrorStateView(message: model.errorMessage ?? "") { model.reload() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = SelfCheckInViewModel(service: dependencies.attendanceService) }
            await model?.load()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            TopBarBackButton { dismiss() }
            Text("Mark Your Attendance")
                .font(AppFont.jakarta(18, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func content(_ model: SelfCheckInViewModel, state: SelfAttendanceState) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                checkInCard(model, state: state)
                statsRow(state)
                historySection(state)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable { model.reload() }
    }

    // MARK: - Check-in card

    private func checkInCard(_ model: SelfCheckInViewModel, state: SelfAttendanceState) -> some View {
        VStack(spacing: 14) {
            Text(state.dateLabel)
                .font(AppFont.jakarta(14, .bold))
                .foregroundStyle(Theme.Colors.ink700)

            clock

            locationPill(state)

            Text(state.locationNote)
                .font(AppFont.jakarta(12))
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)

            checkInButton(model)
                .padding(.vertical, 4)

            Text(state.shiftStartNote)
                .font(AppFont.jakarta(13))
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .dashboardCard(radius: 20)
    }

    /// Live wall-clock: large hour:minute with a small AM/PM suffix.
    private var clock: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let parts = Self.clockParts(context.date)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(parts.time)
                    .font(AppFont.jakarta(46, .heavy))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.ink900)
                Text(parts.suffix)
                    .font(AppFont.jakarta(18, .heavy))
                    .foregroundStyle(Theme.Colors.ink700)
            }
        }
    }

    private func locationPill(_ state: SelfAttendanceState) -> some View {
        HStack(spacing: 6) {
            Image(systemName: state.isInsideCampus ? "mappin.and.ellipse" : "mappin.slash")
                .font(.system(size: 11, weight: .bold))
            Text(state.locationLabel)
                .font(AppFont.jakarta(13, .bold))
        }
        .foregroundStyle(state.isInsideCampus ? Theme.Colors.green700 : Theme.Colors.destructive)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(state.isInsideCampus ? Theme.Colors.green50 : Theme.Colors.errorBackground, in: Capsule())
    }

    @ViewBuilder
    private func checkInButton(_ model: SelfCheckInViewModel) -> some View {
        let checkedIn = model.hasCheckedIn
        let checkedOut = model.hasCheckedOut
        let title = checkedOut ? String(localized: "Checked out")
            : (checkedIn ? String(localized: "Check out") : String(localized: "Check in"))
        let icon = checkedOut ? "checkmark" : "touchid"
        let fill = checkedOut ? Theme.Colors.ink500 : (checkedIn ? Theme.Colors.green600 : Theme.Colors.blue600)

        Button {
            if checkedIn { model.checkOut(at: .now) } else { model.checkIn(at: .now) }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .semibold))
                Text(title)
                    .font(AppFont.jakarta(16, .heavy))
            }
            .foregroundStyle(Theme.Colors.white)
            .frame(width: 150, height: 150)
            .background(fill, in: Circle())
            .shadow(color: fill.opacity(0.35), radius: 14, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(checkedOut)
    }

    // MARK: - Stats row

    private func statsRow(_ state: SelfAttendanceState) -> some View {
        HStack(spacing: 10) {
            statBox(title: "Check-in", value: state.checkInTime)
            statBox(title: "Check-out", value: state.checkOutTime)
            statBox(title: "Hours", value: state.hoursText)
        }
    }

    private func statBox(title: LocalizedStringKey, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.jakarta(12))
                .foregroundStyle(Theme.Colors.ink500)
            Text(value ?? "—")
                .font(AppFont.jakarta(15, .heavy))
                .foregroundStyle(value == nil ? Theme.Colors.ink500 : Theme.Colors.ink900)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 12)
        .dashboardCard(radius: 14)
    }

    // MARK: - History

    private func historySection(_ state: SelfAttendanceState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .font(AppFont.jakarta(16, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Text(state.monthSummary)
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
            }

            VStack(spacing: 0) {
                ForEach(Array(state.history.enumerated()), id: \.element.id) { index, day in
                    if index > 0 {
                        Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                    }
                    historyRow(day)
                }
            }
            .dashboardCard(radius: 16)
        }
    }

    private func historyRow(_ day: SelfAttendanceDay) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text("\(day.dayNumber)")
                    .font(AppFont.jakarta(16, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                Text(day.weekday)
                    .font(AppFont.jakarta(11))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(day.timeRange ?? "—")
                    .font(AppFont.jakarta(14, .bold))
                    .foregroundStyle(Theme.Colors.ink900)
                Text(day.detail)
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
            }

            Spacer(minLength: 0)

            StatusBadge(text: day.status.title, tone: tone(for: day.status), weight: .heavy)
        }
        .padding(14)
    }

    private func tone(for status: SelfAttendanceStatus) -> StatusBadge.Tone {
        switch status {
        case .present: .green
        case .halfDay: .blueSoft
        case .holiday, .weekOff: .neutral
        case .absent: .red
        case .onLeave: .amber
        }
    }

    // MARK: - Live clock formatting

    private static func clockParts(_ date: Date) -> (time: String, suffix: String) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour24 = components.hour ?? 0
        var hour = hour24 % 12
        if hour == 0 { hour = 12 }
        let minute = String(format: "%02d", components.minute ?? 0)
        return ("\(hour):\(minute)", hour24 < 12 ? "AM" : "PM")
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
    return NavigationStack { MarkYourAttendanceView() }
        .environment(AppRouter())
        .environment(deps)
}
