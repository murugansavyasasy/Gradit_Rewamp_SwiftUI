//
//  LearnerFacultyProfileView.swift
//  Gradit
//
//  Student / parent view of a teacher: identity, what they teach the child with
//  schedule, and "meet the teacher" parent hours (no phone). Design: facultyModul.pdf p24–25.
//

import SwiftUI

struct LearnerFacultyProfileView: View {
    let teacherID: String
    let childID: String?

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: LearnerFacultyProfileViewModel?

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Faculty profile"),
                             subtitle: model?.profile.map { "\($0.teachesHeading.replacingOccurrences(of: "Teaches ", with: "").replacingOccurrences(of: " in", with: " ·"))" },
                             showsBack: true) { dismiss() }
            if let model, let profile = model.profile {
                content(profile)
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
            if model == nil {
                model = LearnerFacultyProfileViewModel(teacherID: teacherID, childID: childID, service: dependencies.facultyService)
            }
            await model?.load()
        }
    }

    private func content(_ profile: LearnerFacultyProfile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                identityCard(profile)
                if let note = profile.onLeaveNote { leaveBanner(note) }
                teachesCard(profile)
                meetCard(profile)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func identityCard(_ profile: LearnerFacultyProfile) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                InitialsAvatar(initials: DashboardGreeting.initials(profile.name), size: 56,
                               foreground: Theme.Colors.blue700, background: Theme.Colors.blue100)
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name).font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(profile.designation).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                    if profile.role != .none { FacultyRoleChip(role: profile.role) }
                }
                Spacer(minLength: 0)
            }
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            infoRow("Department", profile.department)
            infoRow("Qualification", profile.qualification)
            infoRow("Experience", profile.experience)
            infoRow("Also taught", profile.alsoTaughtText)
        }
        .padding(16).dashboardCard(radius: 16)
    }

    private func infoRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                .frame(width: 110, alignment: .leading)
            Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func leaveBanner(_ note: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.amber800)
            Text(note).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.amber800)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 12))
    }

    private func teachesCard(_ profile: LearnerFacultyProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(profile.teachesHeading).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            ForEach(Array(profile.subjects.enumerated()), id: \.element.id) { index, subject in
                if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(subject.subject).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        StatusBadge(text: subject.kind.title, tone: subject.kind.tone)
                        Spacer(minLength: 0)
                        Text("\(subject.perWeek) / week").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Text("When: \(subject.when)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func meetCard(_ profile: LearnerFacultyProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meet the teacher").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            HStack(spacing: 8) {
                Image(systemName: "clock").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                Text("Parent hours:  \(profile.parentHours)").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink900)
            }
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                Text(profile.cabin).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink900)
            }
            Button {} label: {
                Label("Message teacher", systemImage: "bubble.left")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
            Text("Please message first so the teacher can confirm a time. Phone numbers aren't shared with parents.")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }
}

#Preview {
    NavigationStack { LearnerFacultyProfileView(teacherID: "meena", childID: "aarav") }
        .environment(AppRouter())
        .environment(AppDependencies(
            apiClient: APIClient(baseURL: AppConfig.baseURL),
            userService: MockUserService(), authService: MockAuthService(latency: .zero),
            dashboardService: MockDashboardService(latency: .zero), profileService: MockProfileService(latency: .zero),
            discussionService: MockDiscussionService(latency: .zero), messagingService: MockMessagingService(latency: .zero),
            attendanceService: MockAttendanceService(latency: .zero), assignmentService: MockAssignmentService(latency: .zero),
            facultyService: MockFacultyService(latency: .zero)))
}
