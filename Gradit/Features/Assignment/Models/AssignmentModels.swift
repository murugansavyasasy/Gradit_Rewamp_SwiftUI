//
//  AssignmentModels.swift
//  Gradit
//
//  Payloads for the Assignment module (faculty create/track/grade and the
//  student/parent view/submit flows). Design: assignment.pdf.
//

import SwiftUI

// MARK: - Status

/// Faculty-facing lifecycle of an assignment the teacher owns.
nonisolated enum FacultyAssignmentStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case active, pastDue, draft, scheduled
    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: String(localized: "Active")
        case .pastDue: String(localized: "Past due")
        case .draft: String(localized: "Draft")
        case .scheduled: String(localized: "Scheduled")
        }
    }

    var systemImage: String? {
        switch self {
        case .active: "checkmark.circle"
        case .pastDue: nil
        case .draft: "pencil"
        case .scheduled: "calendar"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FacultyAssignmentStatus(rawValue: raw) ?? .active
    }
}

/// Learner-facing status of an assignment.
nonisolated enum LearnerAssignmentStatus: String, Codable, Sendable, CaseIterable, Identifiable {
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

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = LearnerAssignmentStatus(rawValue: raw) ?? .pending
    }
}

// MARK: - Attachments

nonisolated enum AttachmentKind: String, Codable, Sendable {
    case pdf, image, document, voice

    var systemImage: String {
        switch self {
        case .pdf: "doc.fill"
        case .image: "photo.fill"
        case .document: "doc.text.fill"
        case .voice: "mic.fill"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AttachmentKind(rawValue: raw) ?? .document
    }
}

nonisolated struct AssignmentAttachment: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let kind: AttachmentKind
    /// "PDF · 1.2 MB" / "Image · 640 KB" / "Voice note · 0:48".
    let detail: String
}

// MARK: - Faculty list

nonisolated struct FacultyAssignment: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subject: String
    let classLabel: String
    let status: FacultyAssignmentStatus
    /// "Posted" / "Draft" / "Scheduled".
    let primaryLabel: String
    /// "Today, 10:20 AM" / "Edited 06 Oct" / "Sends 14 Oct, 08:00 AM".
    let primaryText: String
    let dueText: String              // "Fri, 16 Oct · 11:59 PM"
    let submittedCount: Int?         // nil for drafts / scheduled
    let totalCount: Int
    let note: String?                // "Not visible to students yet"

    var progress: Double {
        guard let submittedCount, totalCount > 0 else { return 0 }
        return Double(submittedCount) / Double(totalCount)
    }

    var progressPercentText: String { "\(Int((progress * 100).rounded()))%" }
}

// MARK: - Faculty detail

nonisolated enum SubmissionState: String, Codable, Sendable {
    case toGrade, graded, notSubmitted, late

    var title: String {
        switch self {
        case .toGrade: String(localized: "To grade")
        case .graded: String(localized: "Graded")
        case .notSubmitted: String(localized: "Not submitted")
        case .late: String(localized: "Late")
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SubmissionState(rawValue: raw) ?? .notSubmitted
    }
}

/// A student's row in the faculty roster + the grading payload.
nonisolated struct AssignmentSubmission: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let studentName: String
    let registerNo: String
    let classLabel: String
    var state: SubmissionState
    /// "Submitted on time · 04 Oct, 09:42 PM" / "Submitted late · …".
    let submittedText: String?
    let files: [AssignmentAttachment]
    let comment: String?
    var marks: Int?
    let maxMarks: Int
}

nonisolated struct AssignmentDetail: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subject: String
    let status: FacultyAssignmentStatus
    let dueText: String              // "Mon, 05 Oct 2026 · 11:59 PM"
    let dueNote: String?             // "2 days ago · late submissions open" / "in 9 days"
    let recipientsText: String       // "All 42 students · B.E. CSE · Sem 5 B"
    let maxMarks: Int
    let postedText: String           // "posted 28 Sep 2026" / "posted today, 10:20 AM"
    let description: String
    let attachments: [AssignmentAttachment]
    let submittedCount: Int
    let notSubmittedCount: Int
    let lateCount: Int
    let gradedCount: Int
    let students: [AssignmentSubmission]
}

// MARK: - Learner list

nonisolated struct LearnerAssignment: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subject: String
    let teacher: String
    let status: LearnerAssignmentStatus
    let dueText: String              // "Thu, 08 Oct · 11:59 PM"
    let dueChip: String              // "Due tomorrow" / "Due in 5 days" / "2 days overdue"
    let dueChipIsUrgent: Bool        // amber chip when true
    let attachmentCount: Int
}

// MARK: - Learner detail

nonisolated struct LearnerAssignmentDetail: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subject: String
    let status: LearnerAssignmentStatus
    let teacherName: String
    let teacherRole: String          // "Class advisor · DBMS" / "Operating Systems"
    let postedText: String           // "01 Oct 2026"
    let maxMarks: Int
    let dueText: String              // "Thu, 08 Oct 2026 · 11:59 PM"
    let lateAllowed: Bool
    let resubmissionAllowed: Bool
    let instructions: String
    let attachments: [AssignmentAttachment]
    /// Amber/red/green status banner. nil when none.
    let bannerText: String?
    // Submission (when submitted/graded)
    let submittedText: String?       // "04 Oct 2026, 06:20 PM · waiting for grade"
    let submissionFiles: [AssignmentAttachment]
    // Grade (when graded)
    let marks: Int?
    let gradePercent: Int?
    let gradedByText: String?        // "by Prof. Karthik Raman on 01 Oct 2026"
    let feedback: String?

    var flagChips: [String] {
        var chips: [String] = []
        chips.append(lateAllowed ? String(localized: "Late submission allowed") : String(localized: "No late submission"))
        chips.append(resubmissionAllowed ? String(localized: "Resubmission allowed") : String(localized: "One submission only"))
        return chips
    }
}
