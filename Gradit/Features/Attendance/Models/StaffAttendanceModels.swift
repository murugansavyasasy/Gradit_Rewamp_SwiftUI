//
//  StaffAttendanceModels.swift
//  Gradit
//
//  Payloads for the management "Attendance" tab (Today staff punch-in and the
//  monthly Staff-wise report). Design: attendanceGradit.pdf p1–14.
//

import SwiftUI

nonisolated enum StaffStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case present, absent, onLeave, late, notPunchedIn
    var id: String { rawValue }

    var title: String {
        switch self {
        case .present: String(localized: "Present")
        case .absent: String(localized: "Absent")
        case .onLeave: String(localized: "On leave")
        case .late: String(localized: "Late")
        case .notPunchedIn: String(localized: "Not punched in yet")
        }
    }

    /// Short label for the grouped section header.
    var groupTitle: String {
        switch self {
        case .present: String(localized: "Present")
        case .absent: String(localized: "Absent")
        case .onLeave: String(localized: "On leave")
        case .late: String(localized: "Late")
        case .notPunchedIn: String(localized: "Not punched in")
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = StaffStatus(rawValue: raw) ?? .present
    }
}

nonisolated struct StaffMember: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let department: String
    let designation: String
    let status: StaffStatus
    /// "Not punched in by 09:15 AM" or "In 09:05 AM · Out not yet · 2h 05m so far".
    let detail: String
    /// e.g. "2 periods free today" — shown as an amber chip on absent staff.
    var freePeriodsNote: String?
}

nonisolated struct StaffAttendanceToday: Codable, Sendable {
    let dateLabel: String        // "Wednesday, 07 Oct 2026"
    let lastUpdated: String      // "Last updated at 11:10 AM · from Mark Your Attendance"
    let total: Int
    let present: Int
    let absent: Int
    let onLeave: Int
    let late: Int
    let notPunchedIn: Int
    let staff: [StaffMember]

    func count(for status: StaffStatus) -> Int {
        switch status {
        case .present: present
        case .absent: absent
        case .onLeave: onLeave
        case .late: late
        case .notPunchedIn: notPunchedIn
        }
    }
}

nonisolated struct StaffMonthlyRow: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let department: String
    let designation: String
    let percent: Int
    let present: Int
    let absent: Int
    let leave: Int
    let late: Int
}

nonisolated struct StaffAttendanceMonthly: Codable, Sendable {
    let averagePercent: Int
    let belowThreshold: Int
    let workingDays: Int
    let leaveDays: Int
    let staff: [StaffMonthlyRow]
}
