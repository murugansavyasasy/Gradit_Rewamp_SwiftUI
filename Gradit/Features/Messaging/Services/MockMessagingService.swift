//
//  MockMessagingService.swift
//  Gradit
//
//  In-memory inbox used in DEBUG, previews and tests. Content mirrors the design.
//

import Foundation

final class MockMessagingService: MessagingServiceProtocol {
    private let latency: Duration
    private var store: [Message]

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency

        let now = Date.now
        func ago(hours: Double = 0, days: Double = 0) -> Date {
            now.addingTimeInterval(-(hours * 3600 + days * 86400))
        }

        store = [
            Message(id: "1", kind: .voice, senderName: "Dr. K. Suresh", senderRole: "Principal",
                    title: "Holiday announcement",
                    body: "College will remain closed on 2 October for the public holiday. Classes resume on 3 October as usual. Please check the notice board for the revised timetable.",
                    durationSeconds: 12, sentAt: ago(hours: 1), isUnread: true),
            Message(id: "2", kind: .text, senderName: "Controller of Exams", senderRole: "Exam Cell",
                    title: "Mid-semester exam timetable",
                    body: "UG exams run from 12 to 17 Oct. Download the full timetable from the Exams section and check your hall-ticket details.",
                    durationSeconds: nil, sentAt: ago(hours: 3), isUnread: true),
            Message(id: "3", kind: .text, senderName: "Accounts Office", senderRole: "Office",
                    title: "Fee due date extended",
                    body: "The last date for the Term 1 hostel fee is now 20 October. Pay online under Fees to avoid a late charge.",
                    durationSeconds: nil, sentAt: ago(days: 1), isUnread: false),
            Message(id: "4", kind: .voice, senderName: "Mr. Ravi", senderRole: "Class teacher",
                    title: "Lab record reminder",
                    body: "Please remind your ward to submit the completed physics lab record before Friday's practical session.",
                    durationSeconds: 24, sentAt: ago(hours: 2, days: 1), isUnread: false),
            Message(id: "5", kind: .text, senderName: "Mr. Ravi", senderRole: "Class teacher",
                    title: "Parent-teacher meeting on Saturday",
                    body: "Meeting on Sat, 10 Oct at 10 AM in Block B, Room 204. Please confirm your attendance in the app.",
                    durationSeconds: nil, sentAt: ago(days: 4), isUnread: false),
        ]
    }

    func messages(studentID: String?) async throws -> [Message] {
        try await Task.sleep(for: latency)
        return store
    }

    func linkedStudents() async throws -> [LinkedStudent] {
        try await Task.sleep(for: latency)
        return [
            LinkedStudent(id: "s1", name: "Aarav", program: "B.E. CSE", term: "Sem 5"),
            LinkedStudent(id: "s2", name: "Diya", program: "B.Com", term: "Sem 3"),
        ]
    }

    func markRead(id: String) async throws {
        try await Task.sleep(for: latency)
        if let index = store.firstIndex(where: { $0.id == id }) {
            store[index].isUnread = false
        }
    }
}
