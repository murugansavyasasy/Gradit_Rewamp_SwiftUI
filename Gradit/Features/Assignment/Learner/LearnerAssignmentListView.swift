//
//  LearnerAssignmentListView.swift
//  Gradit
//
//  Student / parent assignment list: Pending / Submitted / Graded / Overdue tabs,
//  subject filter + sort, assignment cards. Design: assignment.pdf p21–25.
//

import SwiftUI

struct LearnerAssignmentListView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: LearnerAssignmentListViewModel?

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Assignment"),
                             subtitle: "Aarav R. · B.E. CSE · Sem 5 A",
                             showsBack: isPresented) { dismiss() }
            if let model {
                tabs(model)
                filters(model)
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = LearnerAssignmentListViewModel(role: role, service: dependencies.assignmentService) }
            await model?.load()
        }
    }

    // MARK: - Tabs

    private func tabs(_ model: LearnerAssignmentListViewModel) -> some View {
        HStack(spacing: 0) {
            ForEach(LearnerAssignmentListViewModel.Tab.allCases) { tab in
                tabButton(model, tab: tab)
            }
        }
        .padding(.horizontal, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
    }

    private func tabButton(_ model: LearnerAssignmentListViewModel, tab: LearnerAssignmentListViewModel.Tab) -> some View {
        let isOn = model.tab == tab
        let isOverdue = tab == .overdue
        return Button { model.tab = tab } label: {
            VStack(spacing: 6) {
                HStack(spacing: 5) {
                    Text("\(model.count(tab))")
                        .font(AppFont.jakarta(11, .heavy))
                        .foregroundStyle(isOn ? Theme.Colors.white : (isOverdue ? Theme.Colors.white : Theme.Colors.ink700))
                        .padding(.horizontal, 6).frame(minHeight: 20)
                        .background(isOn ? Theme.Colors.blue600 : (isOverdue ? Theme.Colors.destructive : Theme.Colors.surfaceMuted), in: Capsule())
                    Text(tab.title)
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(isOn ? Theme.Colors.blue700 : Theme.Colors.ink500)
                }
                Rectangle().fill(isOn ? Theme.Colors.blue600 : .clear).frame(height: 2)
            }
            .frame(maxWidth: .infinity).padding(.top, 6).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    // MARK: - Filters

    private func filters(_ model: LearnerAssignmentListViewModel) -> some View {
        HStack(spacing: 10) {
            AssignmentDropdown(value: model.subjectFilter, options: model.subjectOptions) { model.subjectFilter = $0 }
            Spacer(minLength: 0)
            Button { model.dueSoonest.toggle() } label: {
                HStack(spacing: 6) {
                    Text(model.dueSoonest ? String(localized: "Due soonest") : String(localized: "Due latest"))
                        .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
                }
                .padding(.horizontal, 12).frame(height: 38)
                .background(Theme.Colors.white, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.Colors.border))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ model: LearnerAssignmentListViewModel) -> some View {
        if model.isLoading, model.assignments.isEmpty {
            loadingSkeleton
        } else if let error = model.errorMessage, model.assignments.isEmpty {
            errorState(model, message: error)
        } else if model.visible.isEmpty {
            emptyState(model)
        } else {
            ScrollView {
                VStack(spacing: 14) {
                    if model.tab == .overdue {
                        overdueBanner
                    }
                    ForEach(model.visible) { assignment in
                        Button { router.push(.assignment(.learnerDetail(assignment))) } label: {
                            card(assignment)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private var overdueBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.destructive)
            Text("Overdue · late submission allowed")
                .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.destructive)
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.errorBackground, in: .rect(cornerRadius: 12))
    }

    private func card(_ assignment: LearnerAssignment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SubjectChip(subject: assignment.subject)
                Spacer()
                StatusBadge(text: assignment.status.title, tone: assignment.status.tone, weight: .heavy)
            }
            Text(assignment.title)
                .font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
            Text(assignment.teacher)
                .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)

            VStack(alignment: .leading, spacing: 2) {
                Text("Due").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                Text(assignment.dueText).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
            }

            HStack(spacing: 8) {
                Text(assignment.dueChip)
                    .font(AppFont.jakarta(12, .bold))
                    .foregroundStyle(assignment.dueChipIsUrgent ? Theme.Colors.amber800 : Theme.Colors.ink700)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(assignment.dueChipIsUrgent ? Theme.Colors.warningBackground : Theme.Colors.surfaceMuted, in: Capsule())
                Spacer(minLength: 0)
                if assignment.attachmentCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "paperclip").font(.system(size: 11, weight: .bold))
                        Text("\(assignment.attachmentCount)").font(AppFont.jakarta(12, .bold))
                    }
                    .foregroundStyle(Theme.Colors.ink500)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    // MARK: - States

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 6).fill(Theme.Colors.surfaceMuted)
                                .frame(height: i == 2 ? 40 : 14)
                                .frame(maxWidth: i == 0 ? 200 : .infinity, alignment: .leading)
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

    private func emptyState(_ model: LearnerAssignmentListViewModel) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "book.closed", size: 64, radius: 20)
            Text("No \(model.tab.title.lowercased()) assignments")
                .font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("You're all caught up. New work from your teachers will show here.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18)
        .padding(16).frame(maxHeight: .infinity, alignment: .top)
    }

    private func errorState(_ model: LearnerAssignmentListViewModel, message: String) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "wifi.exclamationmark", size: 64, radius: 20,
                     foreground: Theme.Colors.destructive, background: Theme.Colors.errorBackground)
            Text("Couldn't load assignments")
                .font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
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
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18)
        .padding(16).frame(maxHeight: .infinity, alignment: .top)
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
    return NavigationStack { LearnerAssignmentListView(role: .student) }
        .environment(AppRouter())
        .environment(deps)
}
