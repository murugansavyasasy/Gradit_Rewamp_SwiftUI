//
//  FacultyAssignmentDetailView.swift
//  Gradit
//
//  Faculty assignment detail: meta, actions (edit/extend/remind/export/delete),
//  description + attachments, submission stats and the student roster.
//  Design: assignment.pdf p11–14, p16.
//

import SwiftUI

struct FacultyAssignmentDetailView: View {
    let assignment: FacultyAssignment

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var model: AssignmentDetailViewModel?
    @State private var isExtending = false
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Assignment"), showsBack: true) { dismiss() }
            if let model, let detail = model.detail {
                content(detail)
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
            if model == nil { model = AssignmentDetailViewModel(assignmentID: assignment.id, service: dependencies.assignmentService) }
            await model?.load()
        }
        .sheet(isPresented: $isExtending) {
            if let detail = model?.detail {
                ExtendDueDateSheet(currentDue: detail.dueText, notSubmitted: detail.notSubmittedCount)
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("Delete this assignment?", isPresented: $isConfirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dismiss() }
        } message: {
            if let detail = model?.detail {
                Text("This removes it for \(detail.notSubmittedCount + detail.submittedCount) students and deletes \(detail.submittedCount) submissions. This can't be undone.")
            }
        }
    }

    private func content(_ detail: AssignmentDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                metaCard(detail)
                actionRow(detail)
                descriptionCard(detail)
                statRow(detail)
                studentsSection(detail)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Meta

    private func metaCard(_ detail: AssignmentDetail) -> some View {
        let overdue = detail.status == .pastDue
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SubjectChip(subject: detail.subject)
                Spacer()
                StatusBadge(text: detail.status.title, tone: detail.status.tone,
                            systemImage: detail.status.systemImage, weight: .heavy)
            }
            Text(detail.title)
                .font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .fixedSize(horizontal: false, vertical: true)

            metaRow(icon: "clock", tint: overdue ? Theme.Colors.destructive : Theme.Colors.ink500) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Due").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    Text(detail.dueText + (detail.dueNote.map { " · \($0)" } ?? ""))
                        .font(AppFont.jakarta(14, .heavy))
                        .foregroundStyle(overdue ? Theme.Colors.destructive : Theme.Colors.ink900)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            metaRow(icon: "person.2", tint: Theme.Colors.ink500) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recipients").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    Text(detail.recipientsText).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                }
            }
            metaRow(icon: "rosette", tint: Theme.Colors.ink500) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Max marks · \(detail.postedText)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    Text("\(detail.maxMarks) marks").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func metaRow<Content: View>(icon: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint).frame(width: 18)
            content()
            Spacer(minLength: 0)
        }
    }

    // MARK: - Actions

    private func actionRow(_ detail: AssignmentDetail) -> some View {
        HStack(spacing: 8) {
            actionButton(icon: "pencil", label: "Edit") { router.push(.assignment(.create)) }
            actionButton(icon: "clock.arrow.circlepath", label: "Extend") { isExtending = true }
            actionButton(icon: "bell", label: "Remind") {}
            actionButton(icon: "arrow.down.to.line", label: "Export") {}
            actionButton(icon: "trash", label: "Delete", destructive: true) { isConfirmingDelete = true }
        }
    }

    private func actionButton(icon: String, label: LocalizedStringKey, destructive: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                Text(label).font(AppFont.jakarta(11, .semibold))
            }
            .foregroundStyle(destructive ? Theme.Colors.destructive : Theme.Colors.ink700)
            .frame(maxWidth: .infinity).frame(height: 60)
            .dashboardCard(radius: 14, border: destructive ? Theme.Colors.amberBorder.opacity(0) : Theme.Colors.line)
            .overlay {
                if destructive {
                    RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.destructive.opacity(0.4))
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Description

    private func descriptionCard(_ detail: AssignmentDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(detail.description)
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700)
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            ForEach(detail.attachments) { AttachmentRow(attachment: $0) }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    // MARK: - Stats

    private func statRow(_ detail: AssignmentDetail) -> some View {
        HStack(spacing: 10) {
            statBox(count: detail.submittedCount, label: "Submitted", fg: Theme.Colors.green700, bg: Theme.Colors.green50)
            statBox(count: detail.notSubmittedCount, label: "Not\nsubmitted", fg: Theme.Colors.destructive, bg: Theme.Colors.errorBackground)
            statBox(count: detail.lateCount, label: "Late", fg: Theme.Colors.amber800, bg: Theme.Colors.warningBackground)
            statBox(count: detail.gradedCount, label: "Graded", fg: Theme.Colors.blue700, bg: Theme.Colors.blue50)
        }
    }

    private func statBox(count: Int, label: String, fg: Color, bg: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)").font(AppFont.jakarta(22, .heavy)).foregroundStyle(fg)
            Text(label).font(AppFont.jakarta(11, .bold)).foregroundStyle(fg)
                .multilineTextAlignment(.center).lineLimit(2)
        }
        .frame(maxWidth: .infinity).frame(height: 72)
        .background(bg, in: .rect(cornerRadius: 14))
    }

    // MARK: - Students

    private func studentsSection(_ detail: AssignmentDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Students").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            VStack(spacing: 0) {
                ForEach(Array(detail.students.enumerated()), id: \.element.id) { index, student in
                    if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                    studentRow(detail, student: student)
                }
            }
            .dashboardCard(radius: 16)
        }
    }

    @ViewBuilder
    private func studentRow(_ detail: AssignmentDetail, student: AssignmentSubmission) -> some View {
        let gradable = student.state != .notSubmitted
        Button {
            if gradable {
                router.push(.assignment(.grade(assignmentID: detail.id, assignmentTitle: detail.title, submission: student)))
            }
        } label: {
            HStack(spacing: 12) {
                InitialsAvatar(initials: DashboardGreeting.initials(student.studentName), size: 40,
                               foreground: Theme.Colors.blue700, background: Theme.Colors.blue100)
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.studentName).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("Reg. \(student.registerNo)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                if student.state == .graded, let marks = student.marks {
                    Text("\(marks)/\(student.maxMarks)")
                        .font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.green700)
                }
                StatusBadge(text: student.state.title, tone: tone(for: student.state), weight: .heavy)
                if gradable {
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Colors.chevron)
                }
            }
            .padding(14).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!gradable)
    }

    private func tone(for state: SubmissionState) -> StatusBadge.Tone {
        switch state {
        case .toGrade: .amber
        case .graded: .green
        case .late: .blueSoft
        case .notSubmitted: .neutral
        }
    }
}

// MARK: - Extend sheet

private struct ExtendDueDateSheet: View {
    let currentDue: String
    let notSubmitted: Int

    @Environment(\.dismiss) private var dismiss
    @State private var selection = "Sat, 10 Oct"

    private let options = ["Thu, 08 Oct", "Sat, 10 Oct", "Wed, 14 Oct"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Extend due date").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current due date").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    Text(currentDue).font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink500)
                        .strikethrough()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Extend to").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
                    HStack(spacing: 8) {
                        ForEach(options, id: \.self) { option in
                            let isOn = selection == option
                            Button(option) { selection = option }
                                .font(AppFont.jakarta(13, .bold))
                                .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                                .padding(.horizontal, 14).frame(height: 40)
                                .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                                .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                                .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("New due date").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.blue700)
                    Text("\(selection) 2026 · 11:59 PM").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.blue700)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12).background(Theme.Colors.blue50, in: .rect(cornerRadius: 12))

                Text("\(notSubmitted) students who haven't submitted will be notified. Submissions after the old date won't be marked Late.")
                    .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                PrimaryButton(title: "Save new due date") { dismiss() }
                Button("Cancel") { dismiss() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
            .background(Theme.Colors.white)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        FacultyAssignmentDetailView(assignment: FacultyAssignment(
            id: "a4", title: "Normalization worksheet – 3NF and BCNF", subject: "DBMS",
            classLabel: "B.E. CSE · Sem 5 B", status: .pastDue, primaryLabel: "Posted",
            primaryText: "28 Sep 2026", dueText: "Mon, 05 Oct · 11:59 PM",
            submittedCount: 30, totalCount: 42, note: nil))
    }
    .environment(AppRouter())
    .environment(AppDependencies(
        apiClient: APIClient(baseURL: AppConfig.baseURL),
        userService: MockUserService(),
        authService: MockAuthService(latency: .zero),
        dashboardService: MockDashboardService(latency: .zero),
        profileService: MockProfileService(latency: .zero),
        discussionService: MockDiscussionService(latency: .zero),
        messagingService: MockMessagingService(latency: .zero),
        attendanceService: MockAttendanceService(latency: .zero),
        assignmentService: MockAssignmentService(latency: .zero)))
}
