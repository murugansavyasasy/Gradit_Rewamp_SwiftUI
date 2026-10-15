//
//  FacultyAttendanceModels.swift
//  Gradit
//
//  Faculty (teacher) attendance: classes to mark + student leave requests.
//  Design: attendanceGradit.pdf p33–38.
//

import Foundation

/// A class the teacher takes on a given day.
nonisolated struct FacultyClassSession: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let subject: String        // "DBMS"
    let classLabel: String     // "B.E. CSE · Sem 5 A"
    let room: String           // "Room B-204 · 58 students"
    let period: String         // "P1"
    let time: String           // "09:00 AM"
    let total: Int             // 58
    /// Present count when taken; nil while pending.
    var takenCount: Int?

    var isTaken: Bool { takenCount != nil }
}

nonisolated enum LeaveStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case pending, approved, rejected
    var id: String { rawValue }
    var title: String {
        switch self {
        case .pending: String(localized: "Pending")
        case .approved: String(localized: "Approved")
        case .rejected: String(localized: "Rejected")
        }
    }
}

/// A student leave request the teacher reviews.
nonisolated struct StudentLeaveRequest: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let studentName: String
    let classLabel: String       // "B.E. CSE · Sem 5 A · Reg. 2024503041"
    let leaveType: String        // "Sick leave"
    let appliedText: String      // "Applied today, 08:12 AM"
    let fromText: String         // "07 Oct"
    let toText: String           // "08 Oct"
    let days: Int
    let reason: String
    var status: LeaveStatus
}

nonisolated enum MarkStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case present, absent, onDuty, onLeave
    var id: String { rawValue }
    var title: String {
        switch self {
        case .present: String(localized: "Present")
        case .absent: String(localized: "Absent")
        case .onDuty: String(localized: "On duty")
        case .onLeave: String(localized: "On leave")
        }
    }
    /// Single-letter shown in the status circle.
    var letter: String {
        switch self {
        case .present: "P"
        case .absent: "A"
        case .onDuty: "OD"
        case .onLeave: "L"
        }
    }
}

/// A student on the class roster being marked.
nonisolated struct RosterStudent: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let registerNo: String
    let admissionNo: String
    var status: MarkStatus = .present
}
