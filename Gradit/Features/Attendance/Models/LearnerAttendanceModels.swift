//
//  LearnerAttendanceModels.swift
//  Gradit
//
//  Student / parent attendance: overall ring, month calendar, subject-wise and
//  leave history. Design: attendanceGradit.pdf p39–44.
//

import Foundation

nonisolated enum LearnerDayStatus: String, Codable, Sendable {
    case present, absent, partlyPresent, onLeave, holiday, none

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = LearnerDayStatus(rawValue: raw) ?? .none
    }
}

nonisolated struct LearnerDay: Codable, Identifiable, Hashable, Sendable {
    let id: Int          // day of month
    let status: LearnerDayStatus
    var isToday: Bool = false
}

/// One period in the tapped-day sheet.
nonisolated struct LearnerDayPeriod: Codable, Identifiable, Hashable, Sendable {
    let id: String       // "P1"
    let subject: String
    let time: String
    let present: Bool
}

nonisolated struct LearnerSubject: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let teacher: String
    let percent: Int
    let hoursAttended: Int
    let hoursAbsent: Int
    var isLow: Bool { percent < 75 }
}

nonisolated struct LearnerLeave: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let type: String          // "Sick leave"
    let status: LeaveStatus
    let appliedOn: String      // "Applied on 06 Oct 2026"
    let fromText: String
    let toText: String
    let days: Int
    let reason: String
    /// "Approved by Dr. Meena Krishnan" or a rejection reason.
    var note: String?
}

nonisolated struct LearnerAttendance: Codable, Sendable {
    let studentName: String
    let classLabel: String        // "B.E. CSE · Sem 5 A"
    let overallPercent: Int        // 86
    let rangeLabel: String         // "OVERALL · JUL – NOV 2026"
    let presentDays: Int
    let totalDays: Int
    let monthLabel: String         // "October 2026"
    /// Weekday index (0 = Sun) that day 1 of the month falls on.
    let firstWeekday: Int
    let daysInMonth: Int
    let days: [LearnerDay]         // only marked days need entries
    let subjects: [LearnerSubject]
    let periods: [LearnerDayPeriod]   // for the sample tapped day
    let leaves: [LearnerLeave]

    var meetsRequirement: Bool { overallPercent >= 75 }
}
