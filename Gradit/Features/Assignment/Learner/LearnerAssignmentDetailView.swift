//
//  LearnerAssignmentDetailView.swift
//  Gradit
//
//  Student / parent assignment detail: meta, status banner, grade + feedback,
//  instructions, teacher attachments and the submit action.
//  Design: assignment.pdf p26–29.
//

import SwiftUI

struct LearnerAssignmentDetailView: View {
    let assignmentID: String
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var model: LearnerAssignmentDetailViewModel?

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Assignment"), showsBack: true) { dismiss() }
            if let model, let detail = model.detail {
                content(model, detail: detail)
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
                model = LearnerAssignmentDetailViewModel(assignmentID: assignmentID, role: role,
                                                         service: dependencies.assignmentService)
            }
            await model?.load()
        }
    }

    private func content(_ model: LearnerAssignmentDetailViewModel, detail: LearnerAssignmentDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                metaCard(detail)
                if detail.status == .graded {
                    gradeCard(detail)
                    if let feedback = detail.feedback { feedbackCard(feedback) }
                } else if let banner = detail.bannerText {
                    statusBanner(detail, text: banner)
                }
                instructionsCard(detail)
                if !detail.submissionFiles.isEmpty { submissionCard(detail) }
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) { bottomBar(model, detail: detail) }
    }

    // MARK: - Meta

    private func metaCard(_ detail: LearnerAssignmentDetail) -> some View {
        let overdue = detail.status == .overdue
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SubjectChip(subject: detail.subject)
                Spacer()
                StatusBadge(text: detail.status.title, tone: detail.status.tone, weight: .heavy)
            }
            Text(detail.title)
                .font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                InitialsAvatar(initials: DashboardGreeting.initials(detail.teacherName), size: 40,
                               foreground: Theme.Colors.green700, background: Theme.Colors.green50)
                VStack(alignment: .leading, spacing: 1) {
                    Text(detail.teacherName).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(detail.teacherRole).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                metaBox(label: "Posted", value: detail.postedText)
                metaBox(label: "Max marks", value: "\(detail.maxMarks)")
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Due date").font(AppFont.jakarta(11)).foregroundStyle(overdue ? Theme.Colors.destructive : Theme.Colors.ink500)
                Text(detail.dueText).font(AppFont.jakarta(14, .heavy)).foregroundStyle(overdue ? Theme.Colors.destructive : Theme.Colors.ink900)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(overdue ? Theme.Colors.errorBackground : Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))

            HStack(spacing: 8) {
                ForEach(detail.flagChips, id: \.self) { chip in
                    Text(chip).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink700)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.Colors.surfaceMuted, in: Capsule())
                }
                Spacer(minLength: 0)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func metaBox(label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))
    }

    // MARK: - Status banner

    private func statusBanner(_ detail: LearnerAssignmentDetail, text: String) -> some View {
        let overdue = detail.status == .overdue
        let submitted = detail.status == .submitted
        let tint = overdue ? Theme.Colors.destructive : (submitted ? Theme.Colors.green700 : Theme.Colors.amber800)
        let bg = overdue ? Theme.Colors.errorBackground : (submitted ? Theme.Colors.green50 : Theme.Colors.warningBackground)
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: overdue ? "exclamationmark.circle.fill" : (submitted ? "checkmark.circle.fill" : "clock.fill"))
                .font(.system(size: 14, weight: .bold)).foregroundStyle(tint)
            Text(text).font(AppFont.jakarta(13, .bold)).foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(bg, in: .rect(cornerRadius: 12))
    }

    // MARK: - Grade

    private func gradeCard(_ detail: LearnerAssignmentDetail) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.Colors.green50).frame(width: 64, height: 64)
                VStack(spacing: 0) {
                    Text("\(detail.marks ?? 0)").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.green700)
                    Text("of \(detail.maxMarks)").font(AppFont.jakarta(9, .bold)).foregroundStyle(Theme.Colors.green700)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(detail.gradePercent ?? 0)% · Graded")
                    .font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                if let by = detail.gradedByText {
                    Text(by).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16, border: Theme.Colors.green100)
    }

    private func feedbackCard(_ feedback: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Teacher feedback").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.blue700)
            Text(feedback).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700)
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    // MARK: - Instructions & attachments

    private func instructionsCard(_ detail: LearnerAssignmentDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(detail.instructions).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700)
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            if !detail.attachments.isEmpty {
                Text("Attachments from teacher (\(detail.attachments.count))")
                    .font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .padding(.top, 2)
                ForEach(detail.attachments) { AttachmentRow(attachment: $0) }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func submissionCard(_ detail: LearnerAssignmentDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your submission").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            if let submitted = detail.submittedText {
                Text(submitted).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.green700)
            }
            ForEach(detail.submissionFiles) { AttachmentRow(attachment: $0) }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private func bottomBar(_ model: LearnerAssignmentDetailViewModel, detail: LearnerAssignmentDetail) -> some View {
        if model.canSubmit {
            switch detail.status {
            case .pending:
                submitButton(detail, title: String(localized: "Submit assignment"), icon: "arrow.up.doc")
            case .overdue:
                submitButton(detail, title: String(localized: "Submit late"), icon: "arrow.up.doc")
            case .submitted:
                HStack(spacing: 12) {
                    Button("View submission") {}
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                    if detail.resubmissionAllowed {
                        Button { router.push(.assignment(.submit(detail))) } label: {
                            Text("Resubmit").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
                .background(Theme.Colors.surfaceMuted)
            case .graded:
                EmptyView()
            }
        }
    }

    private func submitButton(_ detail: LearnerAssignmentDetail, title: String, icon: String) -> some View {
        Button { router.push(.assignment(.submit(detail))) } label: {
            Label(title, systemImage: icon)
                .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
        .background(Theme.Colors.surfaceMuted)
    }
}

private func zeroLatencyDeps() -> AppDependencies {
    AppDependencies(
        apiClient: APIClient(baseURL: AppConfig.baseURL),
        userService: MockUserService(),
        authService: MockAuthService(latency: .zero),
        dashboardService: MockDashboardService(latency: .zero),
        profileService: MockProfileService(latency: .zero),
        discussionService: MockDiscussionService(latency: .zero),
        messagingService: MockMessagingService(latency: .zero),
        attendanceService: MockAttendanceService(latency: .zero),
        assignmentService: MockAssignmentService(latency: .zero))
}

#Preview("Pending") {
    NavigationStack { LearnerAssignmentDetailView(assignmentID: "a4", role: .student) }
        .environment(AppRouter())
        .environment(zeroLatencyDeps())
}

#Preview("Graded") {
    NavigationStack { LearnerAssignmentDetailView(assignmentID: "a12", role: .student) }
        .environment(AppRouter())
        .environment(zeroLatencyDeps())
}
