//
//  GradeSubmissionView.swift
//  Gradit
//
//  Faculty grading screen for a single student's submission.
//  Design: assignment.pdf p15, p18.
//

import SwiftUI

struct GradeSubmissionView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: GradeSubmissionViewModel
    @FocusState private var marksFocused: Bool

    init(assignmentID: String, assignmentTitle: String, submission: AssignmentSubmission) {
        // The service is injected at task time; a placeholder mock keeps init pure.
        _model = State(initialValue: GradeSubmissionViewModel(
            assignmentID: assignmentID, assignmentTitle: assignmentTitle,
            submission: submission, service: MockAssignmentService(latency: .zero)))
    }

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Submission"),
                             subtitle: "\(model.assignmentTitle) · \(model.submission.classLabel)",
                             showsBack: true) { dismiss() }
            content
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { model.service = dependencies.assignmentService }
    }

    private var content: some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                studentCard
                if !model.submission.files.isEmpty { filesCard }
                if let comment = model.submission.comment { commentCard(comment) }
                gradeCard($model)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { bottomBar }
    }

    private var studentCard: some View {
        HStack(spacing: 12) {
            InitialsAvatar(initials: DashboardGreeting.initials(model.submission.studentName), size: 44,
                           foreground: Theme.Colors.green700, background: Theme.Colors.green50)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.submission.studentName)
                    .font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("Reg. \(model.submission.registerNo) · \(model.submission.classLabel)")
                    .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                if let submitted = model.submission.submittedText {
                    Text(submitted).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.green700)
                }
            }
            Spacer(minLength: 0)
            StatusBadge(text: model.submission.state.title,
                        tone: model.submission.state == .graded ? .green : .amber, weight: .heavy)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private var filesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Submitted files (\(model.submission.files.count))")
                .font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
            ForEach(model.submission.files) { AttachmentRow(attachment: $0) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func commentCard(_ comment: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Student's comment").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink500)
            Text(comment).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink900)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func gradeCard(_ model: Bindable<GradeSubmissionViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Grade").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)

            VStack(alignment: .leading, spacing: 6) {
                Text("Marks").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
                HStack(spacing: 12) {
                    TextField("0", text: model.marksText)
                        .keyboardType(.numberPad)
                        .focused($marksFocused)
                        .font(AppFont.jakarta(22, .heavy))
                        .multilineTextAlignment(.center)
                        .frame(width: 90, height: 56)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
                    Text("out of \(model.wrappedValue.maxMarks)")
                        .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.ink700)
                    Spacer(minLength: 0)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Comment for student").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
                TextEditor(text: model.comment)
                    .font(AppFont.jakarta(15)).scrollContentBackground(.hidden)
                    .frame(minHeight: 110).padding(10)
                    .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
                Text("\(model.wrappedValue.comment.count) / 400")
                    .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button("Back to list") { dismiss() }
                .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                .frame(maxWidth: .infinity, minHeight: 52)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
            Button {
                Task { if await model.save() { dismiss() } }
            } label: {
                HStack(spacing: 6) {
                    if model.isSaving { ProgressView().tint(Theme.Colors.white) }
                    else { Image(systemName: "checkmark") }
                    Text("Save grade")
                }
                .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!model.canSave)
            .opacity(model.canSave ? 1 : 0.5)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
        .background(Theme.Colors.surfaceMuted)
    }
}

#Preview {
    NavigationStack {
        GradeSubmissionView(
            assignmentID: "a4", assignmentTitle: "Normalization worksheet",
            submission: AssignmentSubmission(
                id: "sub1", studentName: "Aakash M.", registerNo: "2024503101", classLabel: "Sem 5 B",
                state: .toGrade, submittedText: "Submitted on time · 04 Oct, 09:42 PM",
                files: [
                    AssignmentAttachment(id: "f1", name: "Normalization_Aakash.pdf", kind: .pdf, detail: "PDF · 1.8 MB"),
                    AssignmentAttachment(id: "f2", name: "Bonus_4NF.jpg", kind: .image, detail: "Image · 920 KB"),
                ],
                comment: "Ma'am, I attempted the bonus question on 4NF as well.", marks: nil, maxMarks: 20))
    }
    .environment(AppDependencies.preview)
}
