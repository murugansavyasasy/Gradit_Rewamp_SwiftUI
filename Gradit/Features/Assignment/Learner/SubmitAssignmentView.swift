//
//  SubmitAssignmentView.swift
//  Gradit
//
//  Student submit flow: add files, comment, confirm and success.
//  Design: assignment.pdf p30–32.
//

import SwiftUI

struct SubmitAssignmentView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: SubmitAssignmentViewModel
    @State private var isConfirming = false
    @State private var showSuccess = false

    init(detail: LearnerAssignmentDetail) {
        _model = State(initialValue: SubmitAssignmentViewModel(detail: detail,
                                                               service: MockAssignmentService(latency: .zero)))
    }

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Submit assignment"), showsBack: true) { dismiss() }
            content
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { model.service = dependencies.assignmentService }
        .alert("Submit assignment?", isPresented: $isConfirming) {
            Button("Cancel", role: .cancel) {}
            Button("Submit") { Task { if await model.submit() { showSuccess = true } } }
        } message: {
            let resub = model.resubmissionAllowed ? String(localized: " You can resubmit until the due date.") : ""
            Text("\(model.totalLabel) will be submitted for \"\(model.assignmentTitle)\".\(resub)")
        }
        .fullScreenCover(isPresented: $showSuccess) {
            SubmitSuccessView(model: model, onClose: { dismiss() })
        }
    }

    private var content: some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                summaryCard
                addFilesCard
                filesCard($model)
                commentCard($model)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { bottomBar }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SubjectChip(subject: model.subject)
            Text(model.assignmentTitle)
                .font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Image(systemName: "clock.fill").font(.system(size: 12, weight: .bold))
                Text(model.isLate ? String(localized: "Overdue · \(model.dueText)") : String(localized: "Due · \(model.dueText)"))
                    .font(AppFont.jakarta(13, .bold))
            }
            .foregroundStyle(model.isLate ? Theme.Colors.destructive : Theme.Colors.amber800)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private var addFilesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add files").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
            HStack(spacing: 10) {
                addTile(icon: "camera", label: "Camera") { model.addFile(.image) }
                addTile(icon: "photo.on.rectangle", label: "Gallery") { model.addFile(.image) }
                addTile(icon: "doc", label: "PDF") { model.addFile(.pdf) }
            }
            Text("PDF, JPG or PNG · up to 20 MB in total")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func addTile(icon: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 22, weight: .semibold)).foregroundStyle(Theme.Colors.blue600)
                Text(label).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
            }
            .frame(maxWidth: .infinity).frame(height: 84)
            .dashboardCard(radius: 14)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func filesCard(_ model: Bindable<SubmitAssignmentViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your files").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Text(model.wrappedValue.totalLabel).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            }
            if model.wrappedValue.files.isEmpty {
                Text("No files added yet.").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            } else {
                ForEach(model.wrappedValue.files) { file in
                    AttachmentRow(attachment: AssignmentAttachment(id: file.id, name: file.name, kind: file.kind, detail: file.detail),
                                  onRemove: { model.wrappedValue.remove(file) })
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func commentCard(_ model: Bindable<SubmitAssignmentViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Comment for teacher (optional)").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
            TextEditor(text: model.comment)
                .font(AppFont.jakarta(15)).scrollContentBackground(.hidden)
                .frame(minHeight: 100).padding(10)
                .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
            Text("\(model.wrappedValue.comment.count) / 300")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomBar: some View {
        Button { isConfirming = true } label: {
            HStack(spacing: 6) {
                if model.isSubmitting { ProgressView().tint(Theme.Colors.white) }
                else { Image(systemName: "arrow.up.doc") }
                Text("Submit")
            }
            .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!model.canSubmit)
        .opacity(model.canSubmit ? 1 : 0.5)
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
        .background(Theme.Colors.white)
    }
}

// MARK: - Success

private struct SubmitSuccessView: View {
    let model: SubmitAssignmentViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold)).foregroundStyle(Theme.Colors.green600)
                .frame(width: 96, height: 96).background(Theme.Colors.green50, in: Circle())
            Text("Submitted successfully")
                .font(AppFont.jakarta(24, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("Your teacher will be notified. You can resubmit until the due date.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center).padding(.horizontal, 24)

            VStack(spacing: 0) {
                summaryRow("Assignment", model.assignmentTitle)
                Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                summaryRow("Files", model.totalLabel)
            }
            .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
            .padding(.horizontal, 16)

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: "View submission") { onClose() }
                Button("Back to assignments") { onClose() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private func summaryRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                .frame(width: 92, alignment: .leading)
            Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
    }
}

#Preview {
    NavigationStack {
        SubmitAssignmentView(detail: LearnerAssignmentDetail(
            id: "a4", title: "Normalization worksheet – 3NF and BCNF", subject: "DBMS", status: .pending,
            teacherName: "Dr. Meena Krishnan", teacherRole: "Class advisor · DBMS", postedText: "01 Oct 2026",
            maxMarks: 20, dueText: "Thu, 08 Oct, 11:59 PM", lateAllowed: true, resubmissionAllowed: true,
            instructions: "…", attachments: [], bannerText: nil, submittedText: nil, submissionFiles: [],
            marks: nil, gradePercent: nil, gradedByText: nil, feedback: nil))
    }
    .environment(AppDependencies.preview)
}
