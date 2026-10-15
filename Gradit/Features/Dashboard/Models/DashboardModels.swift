//
//  DashboardModels.swift
//  Gradit
//
//  API payloads for the role dashboards. Display strings that the backend
//  already formats (e.g. "Sick leave · 7–8 Oct") are passed through as-is.
//

import Foundation

// MARK: - Shared

nonisolated struct DashboardAlert: Codable, Hashable, Sendable {
    let id: String
    let message: String
}

nonisolated enum NoticeKind: String, Codable, Sendable {
    case notice, exam, fee, assignment, meeting, event

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = NoticeKind(rawValue: raw) ?? .notice
    }
}

nonisolated struct NoticeSummary: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    var kind: NoticeKind?
}

nonisolated struct ChatPreview: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let senderName: String
    var senderRole: String?
    let message: String
    let sentAt: Date
    var unreadCount: Int
}

// MARK: - Management

nonisolated struct ManagementDashboard: Codable, Sendable {
    var alert: DashboardAlert?
    var unreadNotifications: Int
    var attendance: CollegeAttendanceSummary
    var freePeriods: FreePeriodSummary?
    var mediaPrompt: EventMediaPrompt?
    var needsAttention: [AttentionItem]
}

nonisolated struct CollegeAttendanceSummary: Codable, Sendable {
    let studentPercent: Double
    /// Change vs. yesterday, in percentage points.
    let studentChangePoints: Double
    let staffPresent: Int
    let staffTotal: Int
    let lowAttendanceCount: Int
    let lowAttendanceThreshold: Int

    var staffPercent: Double {
        staffTotal > 0 ? Double(staffPresent) / Double(staffTotal) * 100 : 0
    }
}

nonisolated struct FreePeriodSummary: Codable, Sendable {
    let absentStaff: Int
    let freePeriods: Int
    let unallocated: Int
}

nonisolated struct EventMediaPrompt: Codable, Sendable {
    let eventId: String
    let eventName: String
}

nonisolated struct AttentionItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
}

// MARK: - Faculty

nonisolated struct FacultyDashboard: Codable, Sendable {
    var alert: DashboardAlert?
    var unreadNotifications: Int
    var department: String?
    var swapRequest: SwapRequestSummary?
    var coverPeriodsToday: Int
    var classesToday: [FacultyClass]
    var leaveRequests: [LeaveRequest]
    var notifications: [NoticeSummary]
    var latestChat: ChatPreview?
}

nonisolated struct SwapRequestSummary: Codable, Sendable {
    let id: String
    let requesterName: String
    /// e.g. "Mon, 12 Oct · P1 ⇄ P3"
    let summary: String
    let pendingCount: Int
}

nonisolated struct FacultyClass: Codable, Identifiable, Hashable, Sendable {
    let id: String
    /// "09:00"
    let startTime: String
    let subject: String
    let detail: String
    var isCover: Bool
}

nonisolated struct LeaveRequest: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let studentName: String
    /// e.g. "Sick leave · 7–8 Oct"
    let summary: String
}

nonisolated enum LeaveDecision: String, Codable, Sendable {
    case approved, rejected
}

// MARK: - Parent / Student

nonisolated struct LinkedStudent: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// e.g. "B.E. CSE"
    let program: String
    /// e.g. "Sem 5"
    let term: String
}

nonisolated struct LearnerDashboard: Codable, Sendable {
    var alert: DashboardAlert?
    var unreadNotifications: Int
    var studentFirstName: String
    var attendance: TodayAttendance
    var feeDue: FeeDue?
    var classesToday: [ClassPeriod]
    var events: [EventSummary]
    var assignments: [AssignmentSummary]
    var notices: [NoticeSummary]
    var latestChat: ChatPreview?
    var sponsoredMessage: String?
}

nonisolated enum AttendanceStatus: String, Codable, Sendable {
    case present, absent, late, notMarked
}

nonisolated struct TodayAttendance: Codable, Sendable {
    let overallPercent: Double
    let status: AttendanceStatus
    /// e.g. "TOC · 11:45 AM · B-204"
    var nextClass: String?
}

nonisolated struct FeeDue: Codable, Sendable {
    let amount: Decimal
    let currencyCode: String
    let dueDate: Date
}

nonisolated struct ClassPeriod: Codable, Identifiable, Hashable, Sendable {
    nonisolated enum Timing: String, Codable, Sendable { case now, next, later, done }
    nonisolated enum Change: String, Codable, Sendable { case none, swapped, changed }

    let id: String
    /// "P3"
    let period: String
    /// "10:55 – 11:45 AM"
    let timeRange: String
    let room: String
    let subject: String
    /// e.g. "Swapped · Prof. Karthik Raman"
    var detail: String?
    var timing: Timing
    var change: Change
}

nonisolated struct EventSummary: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let location: String
    let date: Date
}

nonisolated struct AssignmentSummary: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let subject: String
    let title: String
    let dueDate: Date
}
