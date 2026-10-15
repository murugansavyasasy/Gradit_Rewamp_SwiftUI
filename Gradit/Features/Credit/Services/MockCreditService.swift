//
//  MockCreditService.swift
//  Gradit
//
//  In-memory credit data used in DEBUG, previews and tests. Mirrors semCreadits.pdf.
//

import Foundation

final class MockCreditService: CreditServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    func children() async throws -> [FacultyChild] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "aarav", name: "Aarav R.", classLabel: "B.E. CSE · Sem 5 A"),
            .init(id: "diya", name: "Diya R.", classLabel: "B.Tech IT · Sem 3 B"),
        ]
    }

    func credits(childID: String?) async throws -> CreditBundle {
        try await Task.sleep(for: latency)
        let isDiya = childID == "diya"

        let summary = CreditSummary(
            studentName: isDiya ? "Diya R." : "Aarav R.",
            programLine: isDiya ? "B.Tech IT · Sem 3 B" : "B.E. CSE · Sem 5 A",
            regulation: "Regulation 2021",
            obtained: isDiya ? 45 : 80, total: 165, percent: isDiya ? 27 : 48,
            toBeObtained: isDiya ? 120 : 85, semestersCompleted: isDiya ? 2 : 4, totalSemesters: 8,
            creditsThisSemester: 22,
            pendingNote: isDiya ? nil : "Sem 3: 8 credits pending: arrears MA3354 and CS3351 (Nov 2026 exam)")

        return CreditBundle(summary: summary, categories: Self.categories(isDiya: isDiya), semesters: Self.semesters(isDiya: isDiya))
    }

    // MARK: - Builders

    private static func categories(isDiya: Bool) -> [CreditCategoryBlock] {
        if isDiya {
            return [
                CreditCategoryBlock(code: "HS", name: "Humanities and Social Sciences", percent: 50, obtained: 6, total: 12,
                                    rows: [
                                        CreditSemesterRow(semester: 1, label: "Sem 1", obtained: 3, toBeObtained: 0, total: 3, upcoming: false),
                                        CreditSemesterRow(semester: 2, label: "Sem 2", obtained: 3, toBeObtained: 0, total: 3, upcoming: false),
                                        CreditSemesterRow(semester: 4, label: "Sem 4", obtained: 0, toBeObtained: 2, total: 2, upcoming: true),
                                    ]),
                CreditCategoryBlock(code: "BS", name: "Basic Sciences", percent: 60, obtained: 15, total: 25, rows: [
                    CreditSemesterRow(semester: 1, label: "Sem 1", obtained: 8, toBeObtained: 0, total: 8, upcoming: false),
                    CreditSemesterRow(semester: 2, label: "Sem 2", obtained: 7, toBeObtained: 0, total: 7, upcoming: false),
                    CreditSemesterRow(semester: 3, label: "Sem 3", obtained: 0, toBeObtained: 10, total: 10, upcoming: true),
                ]),
            ]
        }
        return [
            CreditCategoryBlock(code: "HS", name: "Humanities and Social Sciences", percent: 67, obtained: 8, total: 12, rows: [
                CreditSemesterRow(semester: 1, label: "Sem 1", obtained: 3, toBeObtained: 0, total: 3, upcoming: false),
                CreditSemesterRow(semester: 2, label: "Sem 2", obtained: 3, toBeObtained: 0, total: 3, upcoming: false),
                CreditSemesterRow(semester: 4, label: "Sem 4", obtained: 2, toBeObtained: 0, total: 2, upcoming: false),
                CreditSemesterRow(semester: 6, label: "Sem 6", obtained: 0, toBeObtained: 4, total: 4, upcoming: true),
            ]),
            CreditCategoryBlock(code: "BS", name: "Basic Sciences", percent: 100, obtained: 22, total: 22, rows: [
                CreditSemesterRow(semester: 1, label: "Sem 1", obtained: 12, toBeObtained: 0, total: 12, upcoming: false),
                CreditSemesterRow(semester: 2, label: "Sem 2", obtained: 10, toBeObtained: 0, total: 10, upcoming: false),
            ]),
            CreditCategoryBlock(code: "ES", name: "Engineering Sciences", percent: 83, obtained: 19, total: 23, rows: [
                CreditSemesterRow(semester: 1, label: "Sem 1", obtained: 6, toBeObtained: 0, total: 6, upcoming: false),
                CreditSemesterRow(semester: 2, label: "Sem 2", obtained: 10, toBeObtained: 0, total: 10, upcoming: false),
                CreditSemesterRow(semester: 3, label: "Sem 3", obtained: 3, toBeObtained: 4, total: 7, upcoming: false),
            ]),
            CreditCategoryBlock(code: "PC", name: "Professional Core", percent: 55, obtained: 26, total: 47, rows: [
                CreditSemesterRow(semester: 3, label: "Sem 3", obtained: 8, toBeObtained: 8, total: 16, upcoming: false),
                CreditSemesterRow(semester: 4, label: "Sem 4", obtained: 10, toBeObtained: 0, total: 10, upcoming: false),
                CreditSemesterRow(semester: 5, label: "Sem 5", obtained: 8, toBeObtained: 13, total: 21, upcoming: false),
            ]),
            CreditCategoryBlock(code: "PE", name: "Professional Electives", percent: 33, obtained: 3, total: 9, rows: [
                CreditSemesterRow(semester: 5, label: "Sem 5", obtained: 3, toBeObtained: 0, total: 3, upcoming: false),
                CreditSemesterRow(semester: 6, label: "Sem 6", obtained: 0, toBeObtained: 6, total: 6, upcoming: true),
            ]),
            CreditCategoryBlock(code: "EEC", name: "Employability Enhancement", percent: 40, obtained: 2, total: 5, rows: [
                CreditSemesterRow(semester: 4, label: "Sem 4", obtained: 2, toBeObtained: 0, total: 2, upcoming: false),
                CreditSemesterRow(semester: 7, label: "Sem 7", obtained: 0, toBeObtained: 3, total: 3, upcoming: true),
            ]),
        ]
    }

    private static func semesters(isDiya: Bool) -> [SemesterCreditBlock] {
        let current = isDiya ? 3 : 5
        let months = ["Nov 2024", "Apr 2025", "Nov 2025", "Apr 2026", "Nov 2026", "Apr 2027", "Nov 2027", "Apr 2028"]
        let totals = [22, 23, 22, 24, 22, 22, 18, 12]
        return (1...8).map { n in
            let status: SemesterCreditStatus = n < current ? .completed : (n == current ? .current : .upcoming)
            let total = totals[n - 1]
            let obtained: Int
            switch status {
            case .completed: obtained = (n == 3 && !isDiya) ? total - 8 : total   // Sem 3 has 8 pending arrears
            case .current: obtained = 0
            case .upcoming: obtained = 0
            }
            let statusText: String
            switch status {
            case .completed: statusText = "Completed · \(months[n - 1])"
            case .current: statusText = "Current · in progress"
            case .upcoming: statusText = "Upcoming · \(months[n - 1])"
            }
            return SemesterCreditBlock(semester: n, label: "Semester \(n)", statusText: statusText, status: status, obtained: obtained, total: total)
        }
    }
}
