//
//  ExamModels.swift
//  Gradit
//
//  Payloads for the student/parent Exam Application Details module (read-only;
//  applications happen on the web portal). Design: examAplication.pdf.
//

import Foundation

// MARK: - Enums

nonisolated enum ExamType: String, Codable, Sendable {
    case regular, arrear, revaluation, supplementary
    var title: String {
        switch self {
        case .regular: String(localized: "Regular")
        case .arrear: String(localized: "Arrear")
        case .revaluation: String(localized: "Revaluation")
        case .supplementary: String(localized: "Supplementary")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ExamType(rawValue: raw) ?? .regular
    }
}

nonisolated enum ExamAppStatus: String, Codable, Sendable {
    case notApplied, paymentPending, applied, approved, rejected, closed, notEligible
    var title: String {
        switch self {
        case .notApplied: String(localized: "Not applied")
        case .paymentPending: String(localized: "Payment pending")
        case .applied: String(localized: "Applied")
        case .approved: String(localized: "Approved")
        case .rejected: String(localized: "Rejected")
        case .closed: String(localized: "Closed")
        case .notEligible: String(localized: "Not eligible")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ExamAppStatus(rawValue: raw) ?? .notApplied
    }
}

// MARK: - List

nonisolated struct ExamApplicationItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let type: ExamType
    let semesterLine: String           // "Sem 3 · Academic year 2026–27"
    let datesLine: String              // "Opens 03 Oct · Last date 12 Oct"
    let daysLeftText: String?          // "5 days left" (blue pill) — nil for closed
    let closed: Bool                   // shows a "Closed" lock pill instead of days-left
    let status: ExamAppStatus
    let amountText: String             // "₹650" / "₹750 / paper"
}

nonisolated struct ExamAlert: Codable, Hashable, Sendable {
    let title: String                  // "End Semester Examination: 2 days left"
    let message: String                // "Fee not paid yet. Pay on the web portal by Fri 09 Oct."
    let examID: String?                // tap target
}

nonisolated struct ExamBundle: Codable, Sendable {
    let alert: ExamAlert?
    let items: [ExamApplicationItem]
}

// MARK: - Detail

nonisolated enum ExamKeyDateState: String, Codable, Sendable {
    case done, current, future
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ExamKeyDateState(rawValue: raw) ?? .future
    }
}

nonisolated struct ExamKeyDate: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let label: String                  // "Application opens" / "Last date" / "Exam starts"
    let value: String                  // "Sat 03 Oct"
    let note: String?                  // "Done" / "5 days left" / "Closed" / "You have already applied"
    let state: ExamKeyDateState
}

nonisolated struct ExamFeeLine: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let label: String                  // "Exam application fee" / "Per-paper fee · 2 papers × ₹200"
    let amount: String                 // "₹250"
}

nonisolated struct ExamPaper: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let code: String                   // "MA3354"
    let name: String                   // "Discrete Mathematics"
}

/// Conditional status banner on the detail screen.
nonisolated enum ExamBannerKind: String, Codable, Sendable {
    case paymentPending, approved, rejected, closed, notEligible
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ExamBannerKind(rawValue: raw) ?? .closed
    }
}

nonisolated struct ExamStatusBanner: Codable, Hashable, Sendable {
    let kind: ExamBannerKind
    let title: String                  // "Payment pending · ₹1,150" / "Approved · next steps" …
    let message: String
    let bullets: [String]              // approved next-steps bullets
    let actionTitle: String?           // "Go to Exams and hall ticket" / "Call exam cell · 044 2235 7140"
    let contactText: String?           // exam cell contact block (rejected)
}

nonisolated struct ExamApplicationDetail: Codable, Sendable {
    let id: String
    let title: String
    let type: ExamType
    let semesterLine: String
    let status: ExamAppStatus
    let appliedOnText: String?         // "Applied on the web on Mon 05 Oct, 07:42 PM"
    let banner: ExamStatusBanner?
    let keyDates: [ExamKeyDate]
    let feeLines: [ExamFeeLine]
    let feeTotal: String               // "₹650"
    let paymentNote: String            // "Not paid yet · Pay on the web portal …" / "Paid on …"
    let paymentPaid: Bool
    let papersHeading: String          // "Papers in this application" / "Papers you can apply for"
    let papers: [ExamPaper]
}
