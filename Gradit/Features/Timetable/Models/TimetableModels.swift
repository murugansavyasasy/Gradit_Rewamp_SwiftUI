//
//  TimetableModels.swift
//  Gradit
//
//  Payloads for the Timetable module: admin list/grid editor, faculty "my
//  timetable" + swaps, and the student/parent class timetable.
//  Design: timetableModule.pdf.
//

import SwiftUI

// MARK: - Status

nonisolated enum TimetableStatus: String, Codable, Sendable {
    case draft, published
    var title: String {
        switch self {
        case .draft: String(localized: "Draft")
        case .published: String(localized: "Published")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TimetableStatus(rawValue: raw) ?? .draft
    }
}

/// State of one grid cell / period.
nonisolated enum CellState: String, Codable, Sendable {
    case normal, clash, edited, swapped, substitute, free, empty, now, cover, done, next
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = CellState(rawValue: raw) ?? .normal
    }
}

// MARK: - Grid building blocks

nonisolated struct TimetablePeriod: Codable, Identifiable, Hashable, Sendable {
    let id: String                  // "P1"
    let time: String                // "09:00 – 09:50 AM"
    let shortStart: String          // "09:00"
    /// Break/lunch label shown after this period, if any.
    let breakAfter: String?
}

nonisolated struct TimetableCell: Codable, Identifiable, Hashable, Sendable {
    var id: String { "\(day)-\(period)" }
    let day: String                 // "Mon"
    let period: String              // "P1"
    var subjectCode: String?        // "DBMS" — nil means free / no class
    var subjectName: String?
    var teacher: String?
    var teacherInitials: String?
    var room: String?
    var state: CellState
    var clashReason: String?
}

nonisolated struct TimetableGrid: Codable, Sendable {
    let periods: [TimetablePeriod]
    let days: [String]              // ["Mon", … "Sat"]
    var cells: [TimetableCell]

    func cell(day: String, period: String) -> TimetableCell? {
        cells.first { $0.day == day && $0.period == period }
    }
}

// MARK: - Admin list

nonisolated struct TimetableSummary: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let classLabel: String          // "B.E. CSE · Sem 5 · A"
    let term: String                // "Odd semester 2026–27 · Jul – Nov"
    let periodsPerWeek: Int
    let updatedText: String         // "Updated today, 11:05 AM"
    let status: TimetableStatus
    let issuesText: String?         // "2 clashes · 2 empty periods to fix"
}

// MARK: - Grid editor detail

nonisolated struct TimetableClash: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String               // "Faculty clash · Wed P3"
    let detail: String              // "Dr. Lakshmi Sundar is already teaching …"
    let primaryAction: String       // "Swap with Wed P4 (TOC)" / "Move to Lab 2 (free)"
}

nonisolated struct TimetableEditor: Codable, Sendable {
    let id: String
    let classLabel: String          // "B.E. CSE · Sem 5 · A · from Mon, 12 Oct"
    var status: TimetableStatus
    var grid: TimetableGrid
    var clashes: [TimetableClash]
    let emptyPeriods: [String]      // ["Tue P6", "Fri P7"]
    /// Subjects available in the cell editor.
    let subjectPalette: [PaletteSubject]
    let faculties: [String]         // option labels, "Dr. Lakshmi Sundar — busy"
    let rooms: [String]

    var canPublish: Bool { clashes.isEmpty && emptyPeriods.isEmpty }
}

nonisolated struct PaletteSubject: Codable, Identifiable, Hashable, Sendable {
    let code: String                // "DBMS"
    let name: String                // "Database"
    var id: String { code }
}

// MARK: - Faculty "my timetable"

nonisolated struct FacultyTimetableDay: Codable, Identifiable, Hashable, Sendable {
    var id: String { date }
    let date: String                // "12"
    let weekday: String             // "Mon"
    let isToday: Bool
}

nonisolated struct FacultyPeriodItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let period: String              // "P1"
    let time: String                // "09:00 – 09:50"
    let subjectName: String
    let classLabel: String          // "B.E. CSE · Sem 5 A · B-204"
    let state: CellState            // done / next / normal / swapped / cover
    let note: String?               // "Swapped with Dr. Lakshmi Sundar · was P1 09:00 AM" / cover note
}

nonisolated struct FacultyTimetable: Codable, Sendable {
    let teacher: String             // "Dr. Meena Krishnan · CSE"
    let swapBanner: SwapBanner?
    let days: [FacultyTimetableDay]
    /// Keyed by day date → periods.
    let periodsByDay: [String: [FacultyPeriodItem]]
}

nonisolated struct SwapBanner: Codable, Hashable, Sendable {
    let requester: String           // "Dr. Lakshmi Sundar"
    let detail: String              // "Mon, 12 Oct · your P1 ⇄ her P3 · reply before Monday"
}

// MARK: - Swaps

nonisolated enum SwapStatus: String, Codable, Sendable {
    case pending, needsReply, accepted, declined, expired
    var title: String {
        switch self {
        case .pending: String(localized: "Pending")
        case .needsReply: String(localized: "Needs your reply")
        case .accepted: String(localized: "Accepted")
        case .declined: String(localized: "Declined")
        case .expired: String(localized: "Expired")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SwapStatus(rawValue: raw) ?? .pending
    }
}

nonisolated struct SwapSide: Codable, Hashable, Sendable {
    let period: String              // "P3 · 10:55 – 11:45 AM"
    let now: String                 // "Your DBMS class" / "Computer Networks · Dr. Lakshmi Sundar"
    let classLabel: String          // "B.E. CSE · Sem 5 A · B-204"
    let afterSwap: String           // "Operating Systems · Prof. Karthik Raman"
}

nonisolated struct SwapRequest: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let isSent: Bool                // sent vs received
    var status: SwapStatus
    let dateText: String            // "Fri, 09 Oct"
    let counterpart: String         // "Prof. Karthik Raman"
    let giveSummary: String         // "P3 · 10:55 AM · DBMS · You"
    let takeSummary: String         // "P4 · 11:45 AM · Operating Systems · Prof. Karthik Raman"
    let classLabel: String
    let metaText: String            // "Sent today, 09:40 AM · B.E. CSE Sem 5 A"
}

/// Candidate period when choosing a swap (step 1).
nonisolated struct SwapCandidate: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let period: String              // "P1"
    let time: String                // "09:00 AM – 09:50 AM"
    let subject: String
    let teacher: String
    let eligibility: String         // "Teacher absent" / "Not possible" / "Both free: …"
    let selectable: Bool
    let reason: String?             // red explanation when not selectable
}

// MARK: - Learner class timetable

nonisolated struct TimetableChild: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let classLabel: String
}

nonisolated struct LearnerPeriodItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let period: String              // "P1"
    let time: String                // "09:00 – 09:50 AM"
    let subjectName: String
    let teacher: String
    let room: String
    let state: CellState            // normal / swapped / now / cover / substitute / free
    let changeNote: String?         // "Changed · Substitute: Dr. Kavitha M. for Prof. Vignesh Prabhu"
}

nonisolated struct ClassDay: Codable, Identifiable, Hashable, Sendable {
    var id: String { date }
    let date: String                // "7"
    let weekday: String             // "Wed"
    let isToday: Bool
}

nonisolated struct ClassTimetable: Codable, Sendable {
    let classLabel: String          // "B.E. CSE · Sem 5 A"
    let updatedText: String         // "Updated 05 Oct 2026 by the Principal's office"
    let changesNote: String?        // "3 changes today …"
    let closedNote: String?         // "No classes on Thursday, 8 Oct …" when a day is closed
    let published: Bool
    let days: [ClassDay]
    let periodsByDay: [String: [LearnerPeriodItem]]
    let weekGrid: TimetableGrid
}
