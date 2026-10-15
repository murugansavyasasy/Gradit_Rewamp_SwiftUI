//
//  FacultyAssignmentListView.swift
//  Gradit
//
//  Faculty assignment list: search, filters, status tabs and assignment cards.
//  Design: assignment.pdf p1–4.
//

import SwiftUI

struct FacultyAssignmentListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: FacultyAssignmentListViewModel?

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Assignment"),
                             subtitle: "Dr. Meena Krishnan · CSE",
                             showsBack: isPresented) { dismiss() }
            if let model {
                controls(model)
                tabs(model)
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) { createButton }
        .task {
            if model == nil { model = FacultyAssignmentListViewModel(service: dependencies.assignmentService) }
            await model?.load()
        }
    }

    // MARK: - Controls

    private func controls(_ model: FacultyAssignmentListViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                TextField(String(localized: "Search by title"), text: $model.searchText)
                    .font(AppFont.jakarta(15))
            }
            .padding(.horizontal, 14).frame(height: 46)
            .dashboardCard(radius: 12)

            HStack(spacing: 10) {
                AssignmentDropdown(label: String(localized: "Class"), value: model.classFilter,
                                   options: model.classOptions) { model.classFilter = $0 }
                AssignmentDropdown(label: String(localized: "Subject"), value: model.subjectFilter,
                                   options: model.subjectOptions) { model.subjectFilter = $0 }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                AssignmentDropdown(label: String(localized: "Status"), value: model.tab.title,
                                   options: FacultyAssignmentListViewModel.Tab.allCases.map(\.title)) { title in
                    if let tab = FacultyAssignmentListViewModel.Tab.allCases.first(where: { $0.title == title }) {
                        model.tab = tab
                    }
                }
                Button {
                    model.newestFirst.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Text(model.newestFirst ? String(localized: "Newest first") : String(localized: "Oldest first"))
                            .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
                    }
                    .padding(.horizontal, 12).frame(height: 38)
                    .background(Theme.Colors.white, in: Capsule())
                    .overlay(Capsule().strokeBorder(Theme.Colors.border))
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 10)
    }

    // MARK: - Tabs

    private func tabs(_ model: FacultyAssignmentListViewModel) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach(FacultyAssignmentListViewModel.Tab.allCases) { tab in
                    tabButton(model, tab: tab)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
        .padding(.bottom, 2)
    }

    private func tabButton(_ model: FacultyAssignmentListViewModel, tab: FacultyAssignmentListViewModel.Tab) -> some View {
        let isOn = model.tab == tab
        return Button { model.tab = tab } label: {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("\(model.count(tab))")
                        .font(AppFont.jakarta(12, .heavy))
                        .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 8).frame(height: 22)
                        .background(isOn ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted, in: Capsule())
                    Text(tab.title)
                        .font(AppFont.jakarta(15, .bold))
                        .foregroundStyle(isOn ? Theme.Colors.blue700 : Theme.Colors.ink500)
                }
                Rectangle().fill(isOn ? Theme.Colors.blue600 : .clear).frame(height: 2)
            }
            .padding(.top, 4).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ model: FacultyAssignmentListViewModel) -> some View {
        if model.isLoading, model.assignments.isEmpty {
            loadingSkeleton
        } else if let error = model.errorMessage, model.assignments.isEmpty {
            errorState(model, message: error)
        } else if model.visible.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(model.visible) { assignment in
                        Button { router.push(.assignment(.facultyDetail(assignment))) } label: {
                            card(assignment)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(16).padding(.bottom, 96)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func card(_ assignment: FacultyAssignment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text(assignment.title)
                    .font(AppFont.jakarta(17, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                StatusBadge(text: assignment.status.title, tone: assignment.status.tone,
                            systemImage: assignment.status.systemImage, weight: .heavy)
            }

            HStack(spacing: 8) {
                SubjectChip(subject: assignment.subject)
                Text(assignment.classLabel)
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink700)
            }

            HStack(spacing: 10) {
                infoBox(label: assignment.primaryLabel, value: assignment.primaryText)
                infoBox(label: String(localized: "Due"), value: assignment.dueText)
            }

            if let submitted = assignment.submittedCount {
                HStack {
                    Text("\(submitted) / \(assignment.totalCount) submitted")
                        .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
                    Spacer()
                    Text(assignment.progressPercentText)
                        .font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink900)
                }
            } else if let note = assignment.note {
                Text(note)
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink500)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func infoBox(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            Text(value).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink900)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))
    }

    // MARK: - States

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Theme.Colors.surfaceMuted)
                                .frame(height: i == 2 ? 44 : 14)
                                .frame(maxWidth: i == 0 ? 220 : .infinity, alignment: .leading)
                        }
                    }
                    .padding(16).dashboardCard(radius: 16)
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .redacted(reason: .placeholder)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "book.closed", size: 64, radius: 20)
            Text("No assignments yet")
                .font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("Create an assignment to share work with your classes and track submissions here.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
            Button { router.push(.assignment(.create)) } label: {
                Label("Create assignment", systemImage: "plus")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 20).frame(height: 48)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .dashboardCard(radius: 18)
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func errorState(_ model: FacultyAssignmentListViewModel, message: String) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "wifi.exclamationmark", size: 64, radius: 20,
                     foreground: Theme.Colors.destructive, background: Theme.Colors.errorBackground)
            Text("Couldn't load your assignments")
                .font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("Check your internet connection and try again.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
            Button { model.reload() } label: {
                Label("Try again", systemImage: "arrow.clockwise")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 20).frame(height: 48)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .dashboardCard(radius: 18)
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var createButton: some View {
        Button { router.push(.assignment(.create)) } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.Colors.white)
                .frame(width: 56, height: 56)
                .background(Theme.Colors.blue600, in: Circle())
                .shadow(color: Theme.Colors.blue600.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(20)
        .accessibilityLabel("Create assignment")
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
        attendanceService: MockAttendanceService(latency: .zero),
        assignmentService: MockAssignmentService(latency: .zero))
    return NavigationStack { FacultyAssignmentListView() }
        .environment(AppRouter())
        .environment(deps)
}
