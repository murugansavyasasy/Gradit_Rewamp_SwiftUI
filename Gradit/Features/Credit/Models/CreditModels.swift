//
//  CreditModels.swift
//  Gradit
//
//  Payloads for the student/parent Sem Credit Points module. Design: semCreadits.pdf.
//

import Foundation

// MARK: - Summary

nonisolated struct CreditSummary: Codable, Sendable {
    let studentName: String
    let programLine: String            // "B.E. CSE · Sem 5 A"
    let regulation: String             // "Regulation 2021"
    let obtained: Int
    let total: Int
    let percent: Int
    let toBeObtained: Int
    let semestersCompleted: Int
    let totalSemesters: Int
    let creditsThisSemester: Int
    let pendingNote: String?           // "Sem 3: 8 credits pending: arrears MA3354 and CS3351 (Nov 2026 exam)"
}

// MARK: - By category

nonisolated struct CreditSemesterRow: Codable, Identifiable, Hashable, Sendable {
    let semester: Int
    var id: Int { semester }
    let label: String                  // "Sem 1"
    let obtained: Int
    let toBeObtained: Int
    let total: Int
    let upcoming: Bool                 // "Upcoming" sub-label + amber to-be-obtained
}

nonisolated struct CreditCategoryBlock: Codable, Identifiable, Hashable, Sendable {
    let code: String                   // "HS" / "ES"
    var id: String { code }
    let name: String                   // "Humanities and Social Sciences"
    let percent: Int
    let obtained: Int
    let total: Int
    let rows: [CreditSemesterRow]

    var toBeObtained: Int { max(0, total - obtained) }
    var progress: Double { total > 0 ? Double(obtained) / Double(total) : 0 }
}

// MARK: - By semester

nonisolated enum SemesterCreditStatus: String, Codable, Sendable {
    case completed, current, upcoming
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SemesterCreditStatus(rawValue: raw) ?? .upcoming
    }
}

nonisolated struct SemesterCreditBlock: Codable, Identifiable, Hashable, Sendable {
    let semester: Int
    var id: Int { semester }
    let label: String                  // "Semester 1"
    let statusText: String             // "Completed · Nov 2024" / "Current · Jul – Nov 2026"
    let status: SemesterCreditStatus
    let obtained: Int
    let total: Int

    var toBeObtained: Int { max(0, total - obtained) }
    var progress: Double { total > 0 ? Double(obtained) / Double(total) : 0 }
}

// MARK: - Bundle

nonisolated struct CreditBundle: Codable, Sendable {
    let summary: CreditSummary
    let categories: [CreditCategoryBlock]
    let semesters: [SemesterCreditBlock]
}
