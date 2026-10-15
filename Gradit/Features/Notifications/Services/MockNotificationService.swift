//
//  MockNotificationService.swift
//  Gradit
//
//  In-memory notifications used in DEBUG, previews and tests.
//

import Foundation

final class MockNotificationService: NotificationServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    func notifications(role: UserRole) async throws -> [AppNotification] {
        try await Task.sleep(for: latency)
        let now = Date()
        func ago(_ seconds: TimeInterval) -> Date { now.addingTimeInterval(-seconds) }

        switch role {
        case .student, .parent:
            return [
                AppNotification(id: "n1", title: "Assignment due tomorrow",
                                message: "DBMS · Normalization worksheet is due by 11:59 PM.",
                                kind: .assignment, date: ago(60 * 25), isRead: false),
                AppNotification(id: "n2", title: "Fee due in 2 days",
                                message: "Hostel & mess ₹22,000 is due on 15 Oct.",
                                kind: .fee, date: ago(60 * 90), isRead: false),
                AppNotification(id: "n3", title: "New notice posted",
                                message: "Diwali holidays announced from 20–24 Oct.",
                                kind: .notice, date: ago(60 * 60 * 5), isRead: false),
                AppNotification(id: "n4", title: "Attendance marked",
                                message: "You were marked present for all 6 periods today.",
                                kind: .attendance, date: ago(60 * 60 * 8), isRead: true),
                AppNotification(id: "n5", title: "Internal results published",
                                message: "Internal Assessment 2 marks are now available.",
                                kind: .result, date: ago(60 * 60 * 26), isRead: true),
                AppNotification(id: "n6", title: "Placement drive",
                                message: "Freshworks virtual drive on 16 Oct. Check eligibility.",
                                kind: .event, date: ago(60 * 60 * 50), isRead: true),
            ]
        case .faculty, .management:
            return [
                AppNotification(id: "n1", title: "2 leave requests pending",
                                message: "Review and approve pending student leave requests.",
                                kind: .general, date: ago(60 * 20), isRead: false),
                AppNotification(id: "n2", title: "Submissions to grade",
                                message: "18 submissions for OS · Lab Record are awaiting grading.",
                                kind: .assignment, date: ago(60 * 75), isRead: false),
                AppNotification(id: "n3", title: "New notice posted",
                                message: "Faculty meeting scheduled for 15 Oct, 4 PM.",
                                kind: .notice, date: ago(60 * 60 * 4), isRead: false),
                AppNotification(id: "n4", title: "Timetable updated",
                                message: "Your Thursday 2 PM slot moved to Lab 3.",
                                kind: .event, date: ago(60 * 60 * 9), isRead: true),
                AppNotification(id: "n5", title: "Low attendance alert",
                                message: "4 students in CSE-A dropped below 75% this week.",
                                kind: .attendance, date: ago(60 * 60 * 28), isRead: true),
            ]
        }
    }

    func markAllRead() async throws {
        try await Task.sleep(for: latency)
    }
}
