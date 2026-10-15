//
//  LearnerFacultyView.swift
//  Gradit
//
//  Student / parent "my teachers by semester": child switcher (parent), semester
//  chips, class teacher + teacher list. Design: facultyModul.pdf p20–28.
//

import SwiftUI

struct LearnerFacultyView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: LearnerFacultyViewModel?

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model {
                if model.isParent, !model.children.isEmpty { childSwitcher(model) }
                if !model.semesters.isEmpty { semesterChips(model) }
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = LearnerFacultyViewModel(role: role, service: dependencies.facultyService) }
            await model?.load()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Faculty").font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(model?.headerSubtitle ?? String(localized: "My teachers by semester"))
                    .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func childSwitcher(_ model: LearnerFacultyViewModel) -> some View {
        HStack(spacing: 10) {
            ForEach(model.children) { child in
                let isOn = model.selectedChildID == child.id
                Button { model.selectChild(child.id) } label: {
                    HStack(spacing: 10) {
                        InitialsAvatar(initials: DashboardGreeting.initials(child.name), size: 38,
                                       foreground: isOn ? Theme.Colors.white : Theme.Colors.blue700,
                                       background: isOn ? Theme.Colors.blue600 : Theme.Colors.blue100)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(child.name).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                            Text(child.classLabel).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .dashboardCard(radius: 14, border: isOn ? Theme.Colors.blue600 : Theme.Colors.line, borderWidth: isOn ? 1.5 : 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    private func semesterChips(_ model: LearnerFacultyViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Semester").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .padding(.horizontal, 16)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(model.semesters) { semester in
                        let isOn = model.selectedSemester == semester.id
                        Button { model.selectSemester(semester.id) } label: {
                            VStack(spacing: 2) {
                                Text(semester.label).font(AppFont.jakarta(14, .heavy))
                                Text(semester.state.title).font(AppFont.jakarta(10, .bold))
                            }
                            .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                            .padding(.horizontal, 14).frame(height: 52)
                            .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: .rect(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(isOn ? .clear : Theme.Colors.line))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func content(_ model: LearnerFacultyViewModel) -> some View {
        if model.isLoading, model.data == nil {
            loadingSkeleton
        } else if let error = model.errorMessage, model.data == nil {
            errorState(model, message: error)
        } else if let data = model.data {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if data.assigned {
                        classCard(data)
                        summaryLine(data)
                        subjectFilter(model)
                        ForEach(model.filteredTeachers()) { teacher in
                            Button {
                                router.push(.faculty(.learnerProfile(teacherID: teacher.id, childID: model.selectedChildID)))
                            } label: {
                                LearnerTeacherRow(teacher: teacher, onMessage: {})
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        upcomingCard(data)
                        notAssignedState(model)
                    }
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func classCard(_ data: SemesterFaculty) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.classLabel).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(data.termText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer()
                StatusBadge(text: data.state.title, tone: data.state == .current ? .blueSoft : .neutral, weight: .heavy)
            }
            if let teacher = data.classTeacher {
                HStack(spacing: 10) {
                    InitialsAvatar(initials: DashboardGreeting.initials(teacher.name), size: 40,
                                   foreground: Theme.Colors.green700, background: Theme.Colors.green50)
                    VStack(alignment: .leading, spacing: 2) {
                        FacultyRoleChip(role: .classTeacher)
                        Text(teacher.name).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text("\(teacher.designation) · \(data.classTeacherHours ?? "")")
                            .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "bubble.left").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.Colors.green700)
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.green50, in: .rect(cornerRadius: 12))
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func summaryLine(_ data: SemesterFaculty) -> some View {
        Text("\(data.teacherCount) teachers · \(data.subjectCount) subjects · \(data.periodsPerWeek) periods a week")
            .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
    }

    private func subjectFilter(_ model: LearnerFacultyViewModel) -> some View {
        HStack(spacing: 4) {
            ForEach(LearnerFacultyViewModel.SubjectFilter.allCases) { filter in
                let isOn = model.subjectFilter == filter
                Button(filter.title) { model.subjectFilter = filter }
                    .font(AppFont.jakarta(13, isOn ? .bold : .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.ink900 : Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                    .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
                    .buttonStyle(.plain)
            }
        }
        .padding(4).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.line))
    }

    private func upcomingCard(_ data: SemesterFaculty) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.classLabel).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(data.termText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer()
                StatusBadge(text: "Upcoming", tone: .amber, weight: .heavy)
            }
            Text("No teachers assigned yet").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink500)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func notAssignedState(_ model: LearnerFacultyViewModel) -> some View {
        VStack(spacing: 12) {
            IconTile(systemImage: "person.2", size: 56, radius: 18)
            Text("Faculty not assigned yet").font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("Teachers for this semester will be listed once the timetable is published, usually by the end of November.")
                .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            Button {
                if let current = model.semesters.first(where: { $0.state == .current }) { model.selectSemester(current.id) }
            } label: {
                Text("See current semester").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 20).frame(height: 48)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
            PoweredByFooter()
        }
        .padding(24).frame(maxWidth: .infinity).dashboardCard(radius: 18)
    }

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 120)
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Colors.line))
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .redacted(reason: .placeholder)
    }

    private func errorState(_ model: LearnerFacultyViewModel, message: String) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "wifi.exclamationmark", size: 64, radius: 20,
                     foreground: Theme.Colors.destructive, background: Theme.Colors.errorBackground)
            Text("Couldn't load the faculty list").font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("Check your internet connection and try again.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            Button { model.reload() } label: {
                Label("Try again", systemImage: "arrow.clockwise")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 20).frame(height: 48)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18)
        .padding(16).frame(maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    NavigationStack { LearnerFacultyView(role: .parent) }
        .environment(AppRouter())
        .environment(AppDependencies(
            apiClient: APIClient(baseURL: AppConfig.baseURL),
            userService: MockUserService(), authService: MockAuthService(latency: .zero),
            dashboardService: MockDashboardService(latency: .zero), profileService: MockProfileService(latency: .zero),
            discussionService: MockDiscussionService(latency: .zero), messagingService: MockMessagingService(latency: .zero),
            attendanceService: MockAttendanceService(latency: .zero), assignmentService: MockAssignmentService(latency: .zero),
            facultyService: MockFacultyService(latency: .zero)))
}
