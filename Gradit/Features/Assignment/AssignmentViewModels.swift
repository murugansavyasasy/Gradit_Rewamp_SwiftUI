//
//  AssignmentViewModels.swift
//  Gradit
//
//  View models for the faculty assignment flows (list, create, detail, grade).
//

import Foundation
import Observation
internal import os

// MARK: - List

@Observable
final class FacultyAssignmentListViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case all, active, pastDue, drafts, scheduled
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .active: String(localized: "Active")
            case .pastDue: String(localized: "Past due")
            case .drafts: String(localized: "Drafts")
            case .scheduled: String(localized: "Scheduled")
            }
        }
        func matches(_ status: FacultyAssignmentStatus) -> Bool {
            switch self {
            case .all: true
            case .active: status == .active
            case .pastDue: status == .pastDue
            case .drafts: status == .draft
            case .scheduled: status == .scheduled
            }
        }
    }

    var tab: Tab = .all
    var searchText = ""
    var classFilter = String(localized: "All")
    var subjectFilter = String(localized: "All")
    var newestFirst = true

    private(set) var assignments: [FacultyAssignment] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: AssignmentServiceProtocol

    init(service: AssignmentServiceProtocol) {
        self.service = service
    }

    var classOptions: [String] {
        [String(localized: "All")] + Array(Set(assignments.map(\.classLabel))).sorted()
    }

    var subjectOptions: [String] {
        [String(localized: "All")] + Array(Set(assignments.map(\.subject))).sorted()
    }

    func count(_ tab: Tab) -> Int {
        assignments.filter { tab.matches($0.status) }.count
    }

    var visible: [FacultyAssignment] {
        let all = String(localized: "All")
        let query = searchText.trimmed.lowercased()
        let filtered = assignments.filter { assignment in
            tab.matches(assignment.status)
                && (query.isEmpty || assignment.title.lowercased().contains(query))
                && (classFilter == all || assignment.classLabel == classFilter)
                && (subjectFilter == all || assignment.subject == subjectFilter)
        }
        return newestFirst ? filtered : filtered.reversed()
    }

    func load() async {
        guard assignments.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            assignments = try await service.facultyAssignments()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Faculty assignments load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { assignments = []; Task { await load() } }
}

// MARK: - Detail

@Observable
final class AssignmentDetailViewModel {
    let assignmentID: String
    private(set) var detail: AssignmentDetail?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: AssignmentServiceProtocol

    init(assignmentID: String, service: AssignmentServiceProtocol) {
        self.assignmentID = assignmentID
        self.service = service
    }

    func load() async {
        guard detail == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await service.assignmentDetail(id: assignmentID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Assignment detail load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { detail = nil; Task { await load() } }
}

// MARK: - Grade

@Observable
final class GradeSubmissionViewModel {
    let assignmentID: String
    let assignmentTitle: String
    var submission: AssignmentSubmission
    var marksText: String
    var comment: String
    private(set) var isSaving = false
    var errorMessage: String?

    /// Set from the environment in `.task` (the VM is created in `init` to hold the submission).
    var service: AssignmentServiceProtocol

    init(assignmentID: String, assignmentTitle: String, submission: AssignmentSubmission,
         service: AssignmentServiceProtocol) {
        self.assignmentID = assignmentID
        self.assignmentTitle = assignmentTitle
        self.submission = submission
        self.marksText = submission.marks.map(String.init) ?? ""
        self.comment = submission.comment ?? ""
        self.service = service
    }

    var maxMarks: Int { submission.maxMarks }

    var marks: Int? {
        guard let value = Int(marksText.trimmed), value >= 0, value <= maxMarks else { return nil }
        return value
    }

    var canSave: Bool { marks != nil && !isSaving }

    func save() async -> Bool {
        guard let marks else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await service.saveGrade(assignmentID: assignmentID, submissionID: submission.id,
                                        marks: marks, comment: comment.trimmed)
            return true
        } catch {
            AppLogger.app.error("Save grade failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return false
        }
    }
}

// MARK: - Create

@Observable
final class CreateAssignmentViewModel {
    var title = ""
    var details = ""
    var department = "B.E. CSE"
    var yearSem = "Year 3 · Sem 5"
    var section = "Section A"
    var subject = "DBMS"
    var allStudents = true
    var pickedStudentIDs: Set<String> = []
    var attachments: [AssignmentAttachment] = []
    var maxMarksText = "20"
    var dueDate: Date?
    var lateAllowed = true
    var resubmissionAllowed = true

    var showErrors = false
    private(set) var isWorking = false
    private(set) var students: [AssignmentSubmission] = []
    var errorMessage: String?

    let departments = ["B.E. CSE", "B.E. ECE", "B.E. MECH", "B.E. CIVIL", "B.E. EEE"]
    let yearSems = ["Year 1 · Sem 1", "Year 1 · Sem 2", "Year 2 · Sem 3", "Year 2 · Sem 4", "Year 3 · Sem 5", "Year 3 · Sem 6"]
    let sections = ["Section A", "Section B", "Section C"]
    let subjects = ["DBMS", "DBMS Lab", "Operating Systems", "Computer Networks", "Theory of Computation"]

    private let service: AssignmentServiceProtocol

    init(service: AssignmentServiceProtocol) {
        self.service = service
    }

    // Validation
    var titleMissing: Bool { title.trimmed.isEmpty }
    var recipientsMissing: Bool { !allStudents && pickedStudentIDs.isEmpty }
    var dueInPast: Bool {
        guard let dueDate else { return true }
        return dueDate < .now
    }

    var problems: [String] {
        var items: [String] = []
        if titleMissing { items.append(String(localized: "Title is missing")) }
        if recipientsMissing { items.append(String(localized: "No recipients selected")) }
        if dueInPast { items.append(String(localized: "Due date is in the past")) }
        return items
    }

    var isValid: Bool { problems.isEmpty }
    var maxMarks: Int { Int(maxMarksText.trimmed) ?? 0 }

    var dueText: String {
        guard let dueDate else { return String(localized: "Set due date") }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy · hh:mm a"
        return formatter.string(from: dueDate)
    }

    var recipientsSummary: String {
        if allStudents {
            return String(localized: "All students · \(department) · \(section)")
        }
        return String(localized: "\(pickedStudentIDs.count) students · \(department) · \(section)")
    }

    func loadStudents() async {
        guard students.isEmpty else { return }
        do {
            students = try await service.classStudents(department: department, yearSem: yearSem, section: section)
        } catch {
            AppLogger.app.error("Load class students failed: \(error.localizedDescription)")
        }
    }

    /// Adds a file chosen from the system file picker (reads its name, size and kind).
    func addAttachment(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let name = url.lastPathComponent
        guard !attachments.contains(where: { $0.name == name }) else { return }

        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let kind = Self.kind(for: url.pathExtension.lowercased())
        let size = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
        attachments.append(AssignmentAttachment(id: url.absoluteString, name: name, kind: kind,
                                                detail: "\(Self.kindLabel(kind)) · \(size)"))
    }

    func removeAttachment(_ attachment: AssignmentAttachment) {
        attachments.removeAll { $0.id == attachment.id }
    }

    private static func kind(for ext: String) -> AttachmentKind {
        switch ext {
        case "pdf": .pdf
        case "jpg", "jpeg", "png", "heic", "gif", "webp", "tiff": .image
        case "m4a", "mp3", "wav", "aac", "caf": .voice
        default: .document
        }
    }

    private static func kindLabel(_ kind: AttachmentKind) -> String {
        switch kind {
        case .pdf: String(localized: "PDF")
        case .image: String(localized: "Image")
        case .voice: String(localized: "Voice note")
        case .document: String(localized: "Document")
        }
    }

    private func draft(scheduled: Bool) -> NewAssignmentDraft {
        NewAssignmentDraft(
            title: title.trimmed, description: details.trimmed, department: department,
            yearSem: yearSem, section: section, subject: subject, maxMarks: maxMarks,
            dueText: dueText, allStudents: allStudents, pickedStudentIDs: Array(pickedStudentIDs),
            attachmentNames: attachments.map(\.name),
            lateAllowed: lateAllowed, resubmissionAllowed: resubmissionAllowed, scheduled: scheduled)
    }

    /// Returns true when the assignment was published.
    func publish() async -> Bool {
        guard isValid else { showErrors = true; return false }
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.publish(draft(scheduled: false))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func saveDraft() async -> Bool {
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.publish(draft(scheduled: false))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
