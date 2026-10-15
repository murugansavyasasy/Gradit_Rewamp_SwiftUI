//
//  AttendanceModels.swift
//  Gradit
//
//  Payloads for the Attendance report (management / staff view).
//  Display values the backend already formats ("87.3%", "2,184") pass through as-is.
//

import Foundation

nonisolated enum AttendanceRange: String, Codable, Sendable, CaseIterable, Identifiable {
    case today, yesterday, thisWeek, thisMonth
    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: String(localized: "Today")
        case .yesterday: String(localized: "Yesterday")
        case .thisWeek: String(localized: "This week")
        case .thisMonth: String(localized: "This month")
        }
    }
}

nonisolated enum AttendanceAudience: String, Codable, Sendable, CaseIterable, Identifiable {
    case students, staff
    var id: String { rawValue }

    var title: String {
        switch self {
        case .students: String(localized: "Students")
        case .staff: String(localized: "Staff")
        }
    }
}

/// One of the four summary cards (Overall / Present / Absent / Late or on leave).
nonisolated struct AttendanceStat: Codable, Identifiable, Hashable, Sendable {
    nonisolated enum Trend: String, Codable, Sendable { case up, down, flat }

    let id: String
    let title: String
    let value: String
    let deltaText: String
    let trend: Trend
    /// The Overall card renders its value larger and in blue.
    var emphasized: Bool = false
}

/// A single bar in the "By period · today" chart.
nonisolated struct PeriodAttendance: Codable, Identifiable, Hashable, Sendable {
    let id: String      // "P1"
    let percent: Double
}

nonisolated struct AttendanceReport: Codable, Sendable {
    let stats: [AttendanceStat]
    let byPeriod: [PeriodAttendance]
}
