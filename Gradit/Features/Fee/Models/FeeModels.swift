//
//  FeeModels.swift
//  Gradit
//
//  Payloads for the student/parent Fee Details module. Design: Fee Details.png.
//

import Foundation

/// Indian-grouped rupee formatting, e.g. 122500 -> "₹1,22,500".
enum FeeFormat {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "INR"
        f.currencySymbol = "₹"
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "en_IN")
        return f
    }()

    static func rupees(_ amount: Int) -> String {
        formatter.string(from: NSNumber(value: amount)) ?? "₹\(amount)"
    }
}

// MARK: - Summary

nonisolated struct FeeSummary: Codable, Sendable {
    let studentName: String
    let programLine: String            // "B.E. CSE · Sem 5 · 2026–27"
    let amountDue: Int
    let dueText: String                // "Due in 2 days · 15 Oct"
    let paidPercent: Int
    let total: Int
    let paid: Int
    let inReview: Int
}

// MARK: - Due tab

nonisolated struct FeeDueItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let subtitle: String               // "Term 1 · due 15 Oct"
    let amount: Int
    let reviewNote: String?            // "Proof under review · UTR … · usually 2 working days"
    let selectable: Bool               // false when under review
}

// MARK: - Fee structure tab

nonisolated enum FeeItemStatus: String, Codable, Sendable {
    case paid, due, partial
    var title: String {
        switch self {
        case .paid: String(localized: "Paid")
        case .due: String(localized: "Due")
        case .partial: String(localized: "Partial")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FeeItemStatus(rawValue: raw) ?? .due
    }
}

nonisolated struct FeeStructureItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let subtitle: String               // "Annual · 2026–27" / "Term 1 of 2" / "Bus 12 · annual"
    let status: FeeItemStatus
    let paid: Int
    let total: Int

    var progress: Double { total > 0 ? Double(paid) / Double(total) : 0 }
}

// MARK: - Payments tab

nonisolated enum FeePaymentStatus: String, Codable, Sendable {
    case underVerification, successful
    var title: String {
        switch self {
        case .underVerification: String(localized: "Under verification")
        case .successful: String(localized: "Successful")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FeePaymentStatus(rawValue: raw) ?? .successful
    }
}

nonisolated struct FeePayment: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let amount: Int
    let detail: String                 // "Hostel & mess · 5 Oct · UPI" / "Tuition · 12 Jul · UPI · Receipt R-2026-04418"
    let status: FeePaymentStatus
    let hasReceipt: Bool
}

// MARK: - Bundle

nonisolated struct FeeDetails: Codable, Sendable {
    let summary: FeeSummary
    let dueItems: [FeeDueItem]
    let paidNote: String?              // "Tuition ₹85,000 and Transport ₹13,000 are paid for this year."
    let structure: [FeeStructureItem]
    let payments: [FeePayment]
}
