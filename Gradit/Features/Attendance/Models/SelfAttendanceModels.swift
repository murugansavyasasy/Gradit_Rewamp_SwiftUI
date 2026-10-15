//
//  SelfAttendanceModels.swift
//  Gradit
//
//  Payload for the personal "Mark Your Attendance" self check-in screen used by
//  management and teachers. Design: attendanceGradit.pdf (Mark Your Attendance).
//

import Foundation

nonisolated enum SelfAttendanceStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case present, halfDay, holiday, absent, onLeave, weekOff
    var id: String { rawValue }

    var title: String {
        switch self {
        case .present: String(localized: "Present")
        case .halfDay: String(localized: "Half day")
        case .holiday: String(localized: "Holiday")
        case .absent: String(localized: "Absent")
        case .onLeave: String(localized: "On leave")
        case .weekOff: String(localized: "Week off")
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SelfAttendanceStatus(rawValue: raw) ?? .present
    }
}

/// One row in the "History" list.
nonisolated struct SelfAttendanceDay: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let dayNumber: Int          // 5
    let weekday: String         // "Mon"
    let timeRange: String?      // "8:52 AM – 5:06 PM" (nil on holidays)
    let detail: String          // "8h 14m · Admin block" / "Gandhi Jayanti"
    let status: SelfAttendanceStatus
}

nonisolated struct SelfAttendanceState: Codable, Sendable {
    let dateLabel: String        // "Tuesday, 6 October 2026"
    let locationLabel: String    // "Inside campus · Admin block"
    let isInsideCampus: Bool
    let locationNote: String     // "Location verified 20 seconds ago · accuracy 12 m"
    var shiftStartNote: String   // "You haven't checked in today. Shift starts at 9:00 AM."
    var checkInTime: String?     // "09:12 AM" once punched in
    var checkOutTime: String?
    var hoursText: String?       // "2h 18m"
    let monthSummary: String     // "This month: 4 of 4 days present"
    let history: [SelfAttendanceDay]
}
