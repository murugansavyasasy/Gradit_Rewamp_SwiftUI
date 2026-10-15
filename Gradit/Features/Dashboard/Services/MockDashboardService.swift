//
//  MockDashboardService.swift
//  Gradit
//
//  Sample content copied from the design canvas, for DEBUG builds
//  (`AppConfig.useMockServices`), SwiftUI previews and tests only.
//  Release builds use `DashboardService`.
//

import Foundation

final class MockDashboardService: DashboardServiceProtocol {
    var latency: Duration
    var failLeaveResponses = false

    init(latency: Duration = .milliseconds(500)) {
        self.latency = latency
    }

    static let students = [
        LinkedStudent(id: "s-aarav", name: "Aarav Sharma", program: "B.E. CSE", term: "Sem 5"),
        LinkedStudent(id: "s-isha", name: "Isha Sharma", program: "B.Com", term: "Sem 3"),
    ]

    private static let rainAlert = DashboardAlert(
        id: "alert-rain-8oct",
        message: "College closed on 8 Oct due to heavy rain. Online classes will run as usual."
    )

    func managementDashboard() async throws -> ManagementDashboard {
        try await wait()
        return ManagementDashboard(
            alert: Self.rainAlert,
            unreadNotifications: 3,
            attendance: CollegeAttendanceSummary(
                studentPercent: 87.3,
                studentChangePoints: 2.1,
                staffPresent: 192,
                staffTotal: 203,
                lowAttendanceCount: 4,
                lowAttendanceThreshold: 75
            ),
            freePeriods: FreePeriodSummary(absentStaff: 2, freePeriods: 6, unallocated: 3),
            mediaPrompt: EventMediaPrompt(eventId: "e-sports-day", eventName: "Sports Day"),
            needsAttention: [
                AttentionItem(id: "att-1", title: "CSE · Sem 1 C at 70.5%", subtitle: "Below 75% for 2 weeks"),
                AttentionItem(id: "att-2", title: "Rahul Kumar · CSE Sem 5 A", subtitle: "68.2% this semester"),
            ]
        )
    }

    func facultyDashboard() async throws -> FacultyDashboard {
        try await wait()
        return FacultyDashboard(
            alert: Self.rainAlert,
            unreadNotifications: 3,
            department: "Dept. of CSE",
            swapRequest: SwapRequestSummary(
                id: "swap-1",
                requesterName: "Dr. Lakshmi Sundar",
                summary: "Mon, 12 Oct · P1 ⇄ P3",
                pendingCount: 1
            ),
            coverPeriodsToday: 1,
            classesToday: [
                FacultyClass(id: "c1", startTime: "09:00", subject: "DBMS", detail: "CSE · Sem 5 A · B-204", isCover: false),
                FacultyClass(id: "c2", startTime: "11:30", subject: "DBMS Lab", detail: "CSE · Sem 5 B · Lab 3", isCover: false),
                FacultyClass(id: "c3", startTime: "14:00", subject: "Mentoring hour", detail: "CSE · Sem 5 A · B-204", isCover: false),
                FacultyClass(id: "c4", startTime: "15:05", subject: "Theory of Computation", detail: "Cover for Prof. Vignesh Prabhu · CSE · Sem 7 A · C-301", isCover: true),
            ],
            leaveRequests: [
                LeaveRequest(id: "l1", studentName: "Rahul Kumar", summary: "Sick leave · 7–8 Oct"),
                LeaveRequest(id: "l2", studentName: "Sneha Nair", summary: "Family function · 9 Oct"),
            ],
            notifications: [
                NoticeSummary(id: "n1", title: "42 submissions received", subtitle: "DBMS Assignment 3 · 1 h ago", kind: .assignment),
                NoticeSummary(id: "n2", title: "Staff meeting at 4:00 PM", subtitle: "Principal’s office · Today", kind: .meeting),
            ],
            latestChat: ChatPreview(
                id: "chat-rs",
                senderName: "Rajesh Sharma",
                senderRole: "Parent of Aarav",
                message: "Thank you, ma’am. We’ll make sure he revises.",
                sentAt: Self.today(hour: 10, minute: 40),
                unreadCount: 1
            )
        )
    }

    func linkedStudents() async throws -> [LinkedStudent] {
        try await wait()
        return Self.students
    }

    func learnerDashboard(studentID: String?) async throws -> LearnerDashboard {
        try await wait()
        let isParent = studentID != nil
        let student = Self.students.first { $0.id == studentID } ?? Self.students[0]
        let firstName = String(student.name.split(separator: " ").first ?? "")

        return LearnerDashboard(
            alert: Self.rainAlert,
            unreadNotifications: 3,
            studentFirstName: firstName,
            attendance: TodayAttendance(overallPercent: 92, status: .present, nextClass: "TOC · 11:45 AM · B-204"),
            feeDue: isParent ? FeeDue(amount: 24_500, currencyCode: "INR", dueDate: Self.day(offset: 6)) : nil,
            classesToday: [
                ClassPeriod(id: "p3", period: "P3", timeRange: "10:55 – 11:45 AM", room: "B-204", subject: "Operating Systems",
                            detail: "Swapped · Prof. Karthik Raman", timing: .now, change: .swapped),
                ClassPeriod(id: "p4", period: "P4", timeRange: "11:45 AM – 12:35 PM", room: "B-204", subject: "Theory of Computation",
                            detail: "Substitute: Dr. Kavitha M.", timing: .next, change: .changed),
            ],
            events: [
                EventSummary(id: "e1", title: "Parent–teacher meet", location: "Block B, Room 204", date: Self.day(offset: 0)),
                EventSummary(id: "e2", title: "AI in healthcare talk", location: "Seminar hall", date: Self.day(offset: 6)),
                EventSummary(id: "e3", title: "Cricket final", location: "College ground", date: Self.day(offset: 10)),
                EventSummary(id: "e4", title: "Annual Day 2026", location: "Main auditorium", date: Self.day(offset: 15)),
            ],
            assignments: [
                AssignmentSummary(id: "a1", subject: "DBMS", title: "Assignment 3 (3NF)", dueDate: Self.day(offset: 0)),
                AssignmentSummary(id: "a2", subject: "Operating Systems", title: "CPU scheduling report", dueDate: Self.day(offset: 3)),
                AssignmentSummary(id: "a3", subject: "Computer Networks", title: "Static routing lab", dueDate: Self.day(offset: 7)),
            ],
            notices: [
                NoticeSummary(id: "nb1", title: "IA 2 hall tickets from 9 Oct", subtitle: "Posted today · Exam cell", kind: .exam),
                NoticeSummary(id: "nb2", title: "Hostel fee: last date 15 Oct", subtitle: "3 Oct · Accounts office", kind: .fee),
            ],
            latestChat: ChatPreview(
                id: "chat-mi",
                senderName: "Dr. Meena Iyer",
                senderRole: "Mentor",
                message: isParent
                    ? "\(firstName) did well in IA 1, keep it up before IA 2."
                    : "Lab record submission extended to Friday.",
                sentAt: Self.today(hour: 10, minute: 24),
                unreadCount: 2
            ),
            sponsoredMessage: "Campus store — hoodies 20% off this week"
        )
    }

    func respondToLeave(id: String, decision: LeaveDecision) async throws {
        try await wait()
        if failLeaveResponses { throw APIError.httpStatus(500) }
    }

    // MARK: - Helpers

    private func wait() async throws {
        try await Task.sleep(for: latency)
    }

    private static func day(offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: .now)) ?? .now
    }

    private static func today(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }
}
