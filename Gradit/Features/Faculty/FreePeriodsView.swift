//
//  FreePeriodsView.swift
//  Gradit
//
//  Free periods created by absent staff today, with allocation. Design: facultyModul.pdf p11.
//

import SwiftUI

struct FreePeriodsView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: FreePeriodsViewModel?
    @State private var allocating: FreePeriod?
    @State private var classFilter = String(localized: "All classes")

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model, let day = model.day {
                content(model, day: day)
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
            if model == nil { model = FreePeriodsViewModel(service: dependencies.facultyService) }
            await model?.load()
        }
        .sheet(item: $allocating) { period in
            if let model {
                AllocateStaffSheet(period: period) { teacher in model.allocate(period, to: teacher) }
                    .presentationDetents([.medium])
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            TopBarBackButton { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Free periods today").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(model?.day?.dateText ?? "").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            Image(systemName: "bell.badge").font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.Colors.ink700)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func content(_ model: FreePeriodsViewModel, day: FreePeriodsDay) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                statsRow(day)
                absentCard(day)
                if let note = day.noteText { noteCard(note) }
                tabs(model)
                AssignmentDropdown(value: classFilter, options: [String(localized: "All classes"), "B.E. CSE", "B.Tech IT"]) { classFilter = $0 }
                ForEach(model.visiblePeriods) { period in periodCard(period) }
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable { model.reload() }
    }

    private func statsRow(_ day: FreePeriodsDay) -> some View {
        HStack(spacing: 10) {
            stat("\(day.staffAbsent)", "Staff absent", Theme.Colors.destructive, Theme.Colors.errorBackground)
            stat("\(day.freePeriods)", "Free periods", Theme.Colors.ink900, Theme.Colors.white)
            stat("\(day.unallocated)", "Still unallocated", Theme.Colors.amber800, Theme.Colors.warningBackground)
        }
    }

    private func stat(_ value: String, _ label: String, _ fg: Color, _ bg: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(AppFont.jakarta(22, .heavy)).foregroundStyle(fg)
            Text(label).font(AppFont.jakarta(11, .bold)).foregroundStyle(fg).multilineTextAlignment(.center).lineLimit(2)
        }
        .frame(maxWidth: .infinity).frame(height: 70)
        .background(bg, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.line))
    }

    private func absentCard(_ day: FreePeriodsDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Absent today").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "point.3.connected.trianglepath.dotted").font(.system(size: 11, weight: .bold))
                    Text("Staff punch-in").font(AppFont.jakarta(13, .bold))
                }
                .foregroundStyle(Theme.Colors.blue600)
            }
            ForEach(day.absentStaff) { staff in
                HStack(spacing: 10) {
                    InitialsAvatar(initials: DashboardGreeting.initials(staff.name), size: 38,
                                   foreground: Theme.Colors.destructive, background: Theme.Colors.errorBackground)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(staff.name).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text(staff.detail).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Spacer(minLength: 0)
                    Text(staff.periods).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink700)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func noteCard(_ note: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.green700)
            Text(note).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.green700)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.green50, in: .rect(cornerRadius: 12))
    }

    private func tabs(_ model: FreePeriodsViewModel) -> some View {
        HStack(spacing: 4) {
            ForEach(FreePeriodsViewModel.Tab.allCases) { tab in
                let isOn = model.tab == tab
                Button {
                    model.tab = tab
                } label: {
                    Text("\(tab.title) · \(model.count(tab))")
                        .font(AppFont.jakarta(13, isOn ? .bold : .semibold))
                        .foregroundStyle(isOn ? Theme.Colors.ink900 : Theme.Colors.ink500)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                        .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.line))
    }

    private func periodCard(_ period: FreePeriod) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(period.period).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.blue700)
                    .frame(width: 34, height: 34).background(Theme.Colors.blue50, in: .rect(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 1) {
                    Text(period.time).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink700)
                    Text(period.subject).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                }
                Spacer(minLength: 0)
                if period.inProgress {
                    StatusBadge(text: "In progress", tone: .green, weight: .heavy)
                }
            }
            Text(period.classLabel).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            HStack(spacing: 6) {
                Image(systemName: "person.fill.xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.destructive)
                Text("Absent: \(period.absentTeacher)").font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink700)
            }

            if period.ended {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark").font(.system(size: 11, weight: .bold))
                    Text(period.allocatedTo.map { "Allocated to \($0)" } ?? String(localized: "Was free"))
                        .font(AppFont.jakarta(12, .semibold))
                }
                .foregroundStyle(Theme.Colors.ink500)
                Text("This period has ended. Allocation can't be changed.")
                    .font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            } else if let allocatedTo = period.allocatedTo, period.allocation == .allocated {
                HStack {
                    Label("Allocated to \(allocatedTo)", systemImage: "checkmark.circle.fill")
                        .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.green700)
                    Spacer()
                    Button("Change") { allocating = period }
                        .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue600).buttonStyle(.plain)
                }
            } else {
                Button { allocating = period } label: {
                    Label("Allocate staff", systemImage: "person.badge.plus")
                        .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16, border: period.allocation == .unallocated && !period.ended ? Theme.Colors.amberBorder : Theme.Colors.line,
                       borderWidth: period.allocation == .unallocated && !period.ended ? 1.5 : 1)
    }
}

// MARK: - Allocate sheet

private struct AllocateStaffSheet: View {
    let period: FreePeriod
    let onAllocate: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private let freeStaff: [(String, String)] = [
        ("Mr. Arul Doss", "Free · CSE"), ("Dr. Kavitha Mohan", "Free · CSE"),
        ("Mrs. Deepa Raman", "Busy · P3 class"), ("Dr. Meena Krishnan", "Free · CSE"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Allocate \(period.period) · \(period.subject)").font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("\(period.classLabel) · covering \(period.absentTeacher)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(20)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(freeStaff, id: \.0) { staff in
                        let busy = staff.1.hasPrefix("Busy")
                        Button { onAllocate(staff.0); dismiss() } label: {
                            HStack(spacing: 10) {
                                InitialsAvatar(initials: DashboardGreeting.initials(staff.0), size: 38,
                                               foreground: Theme.Colors.blue700, background: Theme.Colors.blue100)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(staff.0).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                                    Text(staff.1).font(AppFont.jakarta(12, .semibold))
                                        .foregroundStyle(busy ? Theme.Colors.amber800 : Theme.Colors.green700)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.chevron)
                            }
                            .padding(12).dashboardCard(radius: 12).opacity(busy ? 0.6 : 1)
                        }
                        .buttonStyle(.plain)
                        .disabled(busy)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack { FreePeriodsView() }
        .environment(AppRouter())
        .environment(AppDependencies(
            apiClient: APIClient(baseURL: AppConfig.baseURL),
            userService: MockUserService(), authService: MockAuthService(latency: .zero),
            dashboardService: MockDashboardService(latency: .zero), profileService: MockProfileService(latency: .zero),
            discussionService: MockDiscussionService(latency: .zero), messagingService: MockMessagingService(latency: .zero),
            attendanceService: MockAttendanceService(latency: .zero), assignmentService: MockAssignmentService(latency: .zero),
            facultyService: MockFacultyService(latency: .zero)))
}
