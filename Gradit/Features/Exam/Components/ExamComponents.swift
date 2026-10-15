//
//  ExamComponents.swift
//  Gradit
//
//  Shared styling for the Exam Application module. Design: examAplication.pdf.
//

import SwiftUI

extension ExamType {
    var tone: StatusBadge.Tone {
        switch self {
        case .regular: .blueSoft
        case .arrear: .amber
        case .revaluation: .blueMid
        case .supplementary: .green
        }
    }
}

extension ExamAppStatus {
    var tone: StatusBadge.Tone {
        switch self {
        case .notApplied: .neutral
        case .paymentPending: .amber
        case .applied: .blueSoft
        case .approved: .green
        case .rejected: .red
        case .closed: .neutral
        case .notEligible: .red
        }
    }
    var systemImage: String {
        switch self {
        case .notApplied: "circle.dashed"
        case .paymentPending: "clock"
        case .applied: "paperplane"
        case .approved: "checkmark.circle"
        case .rejected: "xmark.circle"
        case .closed: "nosign"
        case .notEligible: "nosign"
        }
    }
}
