//
//  FacultyProfileView.swift
//  Gradit
//
//  Staff faculty profile: identity, today's punch-in / leave, divisions & subjects,
//  and management actions (assign class teacher, make HoD).
//  Design: facultyModul.pdf p12–15.
//

import SwiftUI

struct FacultyProfileView: View {
    let facultyID: String

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var model: FacultyProfileViewModel?
    @State private var isAssigning = false
    @State private var isConfirmingHoD = false

    var body: some View {
        VStack(spacing: 0) {
            if let model, let profile = model.profile {
                AssignmentTopBar(title: String(localized: "Faculty profile"),
                                 subtitle: "\(profile.department) · \(profile.stream)", showsBack: true) { dismiss() }
                content(profile)
            } else {
                AssignmentTopBar(title: String(localized: "Faculty profile"), showsBack: true) { dismiss() }
                if model?.errorMessage != nil, let model {
                    ErrorStateView(message: model.errorMessage ?? "") { model.reload() }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = FacultyProfileViewModel(facultyID: facultyID, service: dependencies.facultyService) }
            await model?.load()
        }
        .sheet(isPresented: $isAssigning) {
            if let profile = model?.profile {
                AssignClassTeacherSheet(name: profile.name, options: profile.divisionOptions)
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("Make \(model?.profile?.name ?? "") head of department?", isPresented: $isConfirmingHoD) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm") {}
        } message: {
            if let profile = model?.profile {
                Text("\(profile.name) will become head of \(profile.department). The current head stays in the department as Professor. Both will be notified and the change shows in the faculty list straight away.")
            }
        }
    }

    private func content(_ profile: FacultyProfile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                identityCard(profile)
                todayCard(profile)
                subjectsCard(profile)
                actions(profile)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Identity

    private func identityCard(_ profile: FacultyProfile) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                InitialsAvatar(initials: DashboardGreeting.initials(profile.name), size: 60,
                               foreground: Theme.Colors.green700, background: Theme.Colors.green50)
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name).font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(profile.designation).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                    if profile.role != .none { FacultyRoleChip(role: profile.role) }
                }
                Spacer(minLength: 0)
            }
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            infoRow("Employee ID", profile.employeeID)
            infoRow("Department", profile.department)
            infoRow("Stream", profile.stream)
            infoRow("Qualification", profile.qualification)
            infoRow("Experience", profile.experience)
            infoRow("Phone", profile.phone)
        }
        .padding(16).dashboardCard(radius: 16)
    }

    private func infoRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                .frame(width: 104, alignment: .leading)
            Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Today

    private func todayCard(_ profile: FacultyProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today · \(profile.todayDateText)").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                StatusBadge(text: profile.presence == .present ? "Present · \(profile.presenceDetail.replacingOccurrences(of: "Punched in at ", with: "").components(separatedBy: " ·").first ?? "")" : "On leave",
                            tone: profile.presence.tone, weight: .heavy)
            }
            HStack(spacing: 8) {
                Image(systemName: profile.presence == .present ? "touchid" : "calendar.badge.exclamationmark")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                Text(profile.presenceDetail).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
            }

            if !profile.absenceFreePeriods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(profile.absenceFreePeriods.count) free periods created by this absence")
                        .font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.amber800)
                    ForEach(profile.absenceFreePeriods) { period in
                        HStack(spacing: 8) {
                            Text(period.period).font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.amber800)
                                .frame(width: 28, alignment: .leading)
                            Text(period.classLabel).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink700)
                            Spacer(minLength: 0)
                            Text(period.allocation).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink900)
                        }
                    }
                    Button { router.push(.faculty(.freePeriods)) } label: {
                        HStack(spacing: 4) {
                            Text("Open Free periods today").font(AppFont.jakarta(13, .heavy))
                            Image(systemName: "chevron.right").font(.system(size: 10, weight: .heavy))
                        }
                        .foregroundStyle(Theme.Colors.amber800).underline()
                    }
                    .buttonStyle(.plain)
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 12))
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    // MARK: - Subjects

    private func subjectsCard(_ profile: FacultyProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Divisions and subjects").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Text("\(profile.periodsPerWeek) periods / week").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue700)
            }
            ForEach(Array(profile.subjects.enumerated()), id: \.element.id) { index, subject in
                if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(Theme.Colors.blue100).frame(width: 10, height: 10).padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subject.subject).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text(subject.classLabel).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        if subject.isClassTeacher { FacultyRoleChip(role: .classTeacher) }
                    }
                    Spacer(minLength: 0)
                    Text("\(subject.perWeek)/wk").font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink700)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    // MARK: - Actions

    @ViewBuilder
    private func actions(_ profile: FacultyProfile) -> some View {
        if !profile.divisionOptions.isEmpty {
            VStack(spacing: 10) {
                Button { isAssigning = true } label: {
                    Label("Assign as class teacher", systemImage: "star")
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Theme.Colors.blue50, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())
                Button { isConfirmingHoD = true } label: {
                    Label("Make head of department", systemImage: "person.badge.shield.checkmark")
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Assign class teacher sheet

private struct AssignClassTeacherSheet: View {
    let name: String
    let options: [ClassTeacherOption]

    @Environment(\.dismiss) private var dismiss
    @State private var selected: String?

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Assign as class teacher").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("Choose the division \(name) will look after. The current class teacher will be replaced and both will be notified.")
                    .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(options) { option in row(option) }
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                Button { dismiss() } label: {
                    Text("Assign").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(selected == nil)
                .opacity(selected == nil ? 0.5 : 1)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .onAppear { selected = options.first { !$0.isCurrent }?.id }
    }

    private func row(_ option: ClassTeacherOption) -> some View {
        let isOn = selected == option.id
        return Button { if !option.isCurrent { selected = option.id } } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.blue600 : Theme.Colors.ink300)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.divisionLabel).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(option.currentTeacher).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                if option.isCurrent {
                    Text("Current").font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.green700)
                } else if isOn {
                    Text("Selected").font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.blue600)
                }
            }
            .padding(14)
            .dashboardCard(radius: 14, border: isOn ? Theme.Colors.blue600 : Theme.Colors.line, borderWidth: isOn ? 1.5 : 1)
            .opacity(option.isCurrent ? 0.6 : 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { FacultyProfileView(facultyID: "anitha") }
        .environment(AppRouter())
        .environment(AppDependencies(
            apiClient: APIClient(baseURL: AppConfig.baseURL),
            userService: MockUserService(), authService: MockAuthService(latency: .zero),
            dashboardService: MockDashboardService(latency: .zero), profileService: MockProfileService(latency: .zero),
            discussionService: MockDiscussionService(latency: .zero), messagingService: MockMessagingService(latency: .zero),
            attendanceService: MockAttendanceService(latency: .zero), assignmentService: MockAssignmentService(latency: .zero),
            facultyService: MockFacultyService(latency: .zero)))
}
