//
//  MockFeeService.swift
//  Gradit
//
//  In-memory fee data used in DEBUG, previews and tests. Mirrors Fee Details.png.
//

import Foundation

final class MockFeeService: FeeServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    func children() async throws -> [FacultyChild] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "aarav", name: "Aarav Sharma", classLabel: "B.E. CSE · Sem 5"),
            .init(id: "diya", name: "Diya Sharma", classLabel: "B.Tech IT · Sem 3"),
        ]
    }

    func feeDetails(childID: String?) async throws -> FeeDetails {
        try await Task.sleep(for: latency)
        let isDiya = childID == "diya"
        return FeeDetails(
            summary: FeeSummary(
                studentName: isDiya ? "Diya Sharma" : "Aarav Sharma",
                programLine: isDiya ? "B.Tech IT · Sem 3 · 2026–27" : "B.E. CSE · Sem 5 · 2026–27",
                amountDue: 24_500, dueText: "Due in 2 days · 15 Oct",
                paidPercent: 80, total: 1_22_500, paid: 98_000, inReview: 22_000),
            dueItems: [
                FeeDueItem(id: "d1", name: "Hostel & mess", subtitle: "Term 1 · due 15 Oct", amount: 22_000,
                           reviewNote: "Proof under review · UTR 4271 9930 1185 · usually 2 working days", selectable: false),
                FeeDueItem(id: "d2", name: "Semester exam fee", subtitle: "Nov 2026 exams · due 15 Oct", amount: 2_500,
                           reviewNote: nil, selectable: true),
            ],
            paidNote: "Tuition ₹85,000 and Transport ₹13,000 are paid for this year.",
            structure: [
                FeeStructureItem(id: "s1", name: "Tuition fee", subtitle: "Annual · 2026–27", status: .paid, paid: 85_000, total: 85_000),
                FeeStructureItem(id: "s2", name: "Hostel & mess", subtitle: "Term 1 of 2", status: .due, paid: 0, total: 22_000),
                FeeStructureItem(id: "s3", name: "Transport", subtitle: "Bus 12 · annual", status: .paid, paid: 13_000, total: 13_000),
                FeeStructureItem(id: "s4", name: "Semester exam fee", subtitle: "Nov 2026 exams", status: .due, paid: 0, total: 2_500),
            ],
            payments: [
                FeePayment(id: "p1", amount: 22_000, detail: "Hostel & mess · 5 Oct · UPI", status: .underVerification, hasReceipt: false),
                FeePayment(id: "p2", amount: 85_000, detail: "Tuition · 12 Jul · UPI · Receipt R-2026-04418", status: .successful, hasReceipt: true),
                FeePayment(id: "p3", amount: 13_000, detail: "Transport · 3 Jul · Debit card · Receipt R-2026-03961", status: .successful, hasReceipt: true),
            ])
    }
}
