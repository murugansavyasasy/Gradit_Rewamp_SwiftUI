//
//  AttendanceService.swift
//  Gradit
//

import Foundation

protocol AttendanceServiceProtocol {
    func report(range: AttendanceRange,
                audience: AttendanceAudience,
                department: String,
                yearSem: String) async throws -> AttendanceReport
    /// Management "Attendance" tab — today's staff punch-in.
    func staffToday() async throws -> StaffAttendanceToday
    /// Management "Attendance" tab — monthly staff-wise report (month nil == all months).
    func staffMonthly(year: Int, month: Int?) async throws -> StaffAttendanceMonthly

    // Faculty
    func facultyClasses() async throws -> [FacultyClassSession]
    func leaveRequests() async throws -> [StudentLeaveRequest]
    func classRoster(sessionID: String) async throws -> [RosterStudent]

    // Learner (student / parent)
    func learnerAttendance(studentID: String?) async throws -> LearnerAttendance

    // Self check-in (management / teachers)
    func selfAttendance() async throws -> SelfAttendanceState
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class AttendanceService: AttendanceServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func report(range: AttendanceRange,
                audience: AttendanceAudience,
                department: String,
                yearSem: String) async throws -> AttendanceReport {
        var endpoint = Endpoint(path: "/attendance/report")
        endpoint.queryItems = [
            URLQueryItem(name: "range", value: range.rawValue),
            URLQueryItem(name: "audience", value: audience.rawValue),
            URLQueryItem(name: "department", value: department),
            URLQueryItem(name: "year_sem", value: yearSem),
        ]
        return try await client.send(endpoint)
    }

    func staffToday() async throws -> StaffAttendanceToday {
        try await client.send(Endpoint(path: "/attendance/staff/today"))
    }

    func staffMonthly(year: Int, month: Int?) async throws -> StaffAttendanceMonthly {
        var endpoint = Endpoint(path: "/attendance/staff/monthly")
        var items = [URLQueryItem(name: "year", value: "\(year)")]
        if let month { items.append(URLQueryItem(name: "month", value: "\(month)")) }
        endpoint.queryItems = items
        return try await client.send(endpoint)
    }

    func facultyClasses() async throws -> [FacultyClassSession] {
        try await client.send(Endpoint(path: "/attendance/faculty/classes"))
    }

    func leaveRequests() async throws -> [StudentLeaveRequest] {
        try await client.send(Endpoint(path: "/attendance/faculty/leave-requests"))
    }

    func classRoster(sessionID: String) async throws -> [RosterStudent] {
        try await client.send(Endpoint(path: "/attendance/faculty/classes/\(sessionID)/roster"))
    }

    func learnerAttendance(studentID: String?) async throws -> LearnerAttendance {
        var endpoint = Endpoint(path: "/attendance/learner")
        if let studentID { endpoint.queryItems = [URLQueryItem(name: "student_id", value: studentID)] }
        return try await client.send(endpoint)
    }

    func selfAttendance() async throws -> SelfAttendanceState {
        try await client.send(Endpoint(path: "/attendance/self"))
    }
}
