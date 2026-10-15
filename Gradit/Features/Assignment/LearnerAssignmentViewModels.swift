//
//  LearnerAssignmentViewModels.swift
//  Gradit
//
//  View models for the student / parent assignment flows (list, detail, submit).
//

import Foundation
import Observation
internal import os

// MARK: - List

@Observable
final class LearnerAssignmentListViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case pending, submitted, graded, overdue
        var id: String { rawValue }
        var title: String {
            switch self {
            case .pending: String(localized: "Pending")
            case .submitted: String(localized: "Submitted")
            case .graded: String(localized: "Graded")
            case .overdue: String(localized: "Overdue")
            }
        }
        var status: LearnerAssignmentStatus {
            switch self {
            case .pending: .pending
            case .submitted: .submitted
            case .graded: .graded
            case .overdue: .overdue
            }
        }
    }

    let role: UserRole
    var tab: Tab = .pending
    var subjectFilter = String(localized: "All subjects")
    var dueSoonest = true

    private(set) var assignments: [LearnerAssignment] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: AssignmentServiceProtocol

    init(role: UserRole, service: AssignmentServiceProtocol) {
        self.role = role
        self.service = service
    }

    var subjectOptions: [String] {
        [String(localized: "All subjects")] + Array(Set(assignments.map(\.subject))).sorted()
    }

    func count(_ tab: Tab) -> Int {
        assignments.filter { $0.status == tab.status }.count
    }

    var visible: [LearnerAssignment] {
        let all = String(localized: "All subjects")
        let filtered = assignments.filter {
            $0.status == tab.status && (subjectFilter == all || $0.subject == subjectFilter)
        }
        return dueSoonest ? filtered : filtered.reversed()
    }

    func load() async {
        guard assignments.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            assignments = try await service.learnerAssignments(studentID: role == .parent ? "s1" : nil)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Learner assignments load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { assignments = []; Task { await load() } }
}

// MARK: - Detail

@Observable
final class LearnerAssignmentDetailViewModel {
    let assignmentID: String
    let role: UserRole
    private(set) var detail: LearnerAssignmentDetail?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: AssignmentServiceProtocol

    init(assignmentID: String, role: UserRole, service: AssignmentServiceProtocol) {
        self.assignmentID = assignmentID
        self.role = role
        self.service = service
    }

    /// Parents view their child's assignments read-only.
    var canSubmit: Bool { role == .student }

    func load() async {
        guard detail == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await service.learnerAssignmentDetail(id: assignmentID,
                                                               studentID: role == .parent ? "s1" : nil)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Learner assignment detail load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { detail = nil; Task { await load() } }
}

// MARK: - Submit

@Observable
final class SubmitAssignmentViewModel {
    struct LocalFile: Identifiable, Hashable {
        let id = UUID().uuidString
        let name: String
        let detail: String
        let kind: AttachmentKind
    }

    let assignmentID: String
    let assignmentTitle: String
    let subject: String
    let dueText: String
    let isLate: Bool
    let resubmissionAllowed: Bool

    var files: [LocalFile]
    var comment = ""
    private(set) var isSubmitting = false
    var errorMessage: String?

    /// Set from the environment in `.task` (the VM is created in `init` to hold the detail).
    var service: AssignmentServiceProtocol

    init(detail: LearnerAssignmentDetail, service: AssignmentServiceProtocol) {
        self.assignmentID = detail.id
        self.assignmentTitle = detail.title
        self.subject = detail.subject
        self.dueText = detail.dueText
        self.isLate = detail.status == .overdue
        self.resubmissionAllowed = detail.resubmissionAllowed
        self.service = service
        // Seed with the student's existing picks (design shows 2 files).
        self.files = [
            LocalFile(name: "Normalization_Aarav.pdf", detail: "PDF · 2.1 MB", kind: .pdf),
            LocalFile(name: "Page_3_working.jpg", detail: "Image · 1.4 MB", kind: .image),
        ]
    }

    var canSubmit: Bool { !files.isEmpty && !isSubmitting }
    var totalLabel: String { String(localized: "\(files.count) files") }

    /// Mock file picking — appends a representative file for the chosen source.
    func addFile(_ kind: AttachmentKind) {
        let next = files.count + 1
        let file: LocalFile
        switch kind {
        case .image: file = LocalFile(name: "Photo_\(next).jpg", detail: "Image · 1.2 MB", kind: .image)
        case .pdf: file = LocalFile(name: "Document_\(next).pdf", detail: "PDF · 900 KB", kind: .pdf)
        default: file = LocalFile(name: "File_\(next)", detail: "Document · 400 KB", kind: .document)
        }
        files.append(file)
    }

    func remove(_ file: LocalFile) {
        files.removeAll { $0.id == file.id }
    }

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await service.submit(assignmentID: assignmentID, fileNames: files.map(\.name), comment: comment.trimmed)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
