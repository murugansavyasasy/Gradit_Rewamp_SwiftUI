//
//  MockDiscussionService.swift
//  Gradit
//
//  In-memory discussion board used in DEBUG, previews and tests.
//

import Foundation

final class MockDiscussionService: DiscussionServiceProtocol {
    private let latency: Duration
    private var threadsStore: [DiscussionThread]
    private var repliesStore: [String: [DiscussionReply]]
    private var nextID = 100

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency

        let now = Date.now
        func ago(_ hours: Double) -> Date { now.addingTimeInterval(-hours * 3600) }

        threadsStore = [
            DiscussionThread(
                id: "1",
                authorName: "Dr. Suresh Kumar",
                authorRole: "Principal",
                category: .announcements,
                title: "Mid-sem exams start 21 Oct",
                body: "The odd-semester examinations begin on 21 October. Hall tickets will be available in the app from 15 October. Please clear any pending fees before then.",
                createdAt: ago(3),
                replyCount: 2,
                likeCount: 24,
                isPinned: true,
                isLiked: false
            ),
            DiscussionThread(
                id: "2",
                authorName: "Prof. Karthik Raman",
                authorRole: "Faculty",
                category: .academics,
                title: "Extra DSA doubt-clearing session Saturday",
                body: "Holding an optional Data Structures session this Saturday at 10 AM in B-204 before the exams. Bring your questions on trees and graphs.",
                createdAt: ago(8),
                replyCount: 3,
                likeCount: 16,
                isPinned: false,
                isLiked: true
            ),
            DiscussionThread(
                id: "3",
                authorName: "Aarav R.",
                authorRole: "Student",
                category: .events,
                title: "Techfest ’26 — who's forming teams?",
                body: "Looking for two more people for the smart-attendance kiosk project demo. CSE or ECE, ping me here.",
                createdAt: ago(26),
                replyCount: 1,
                likeCount: 9,
                isPinned: false,
                isLiked: false
            ),
            DiscussionThread(
                id: "4",
                authorName: "Meena Iyer",
                authorRole: "Parent",
                category: .general,
                title: "Bus route 7 timing change?",
                body: "Has the morning pickup for route 7 moved to 7:15? My daughter's stop seems earlier this week.",
                createdAt: ago(50),
                replyCount: 0,
                likeCount: 2,
                isPinned: false,
                isLiked: false
            ),
        ]

        repliesStore = [
            "1": [
                DiscussionReply(id: "r1", authorName: "Meena Iyer", authorRole: "Parent", body: "Thank you for the early notice.", createdAt: ago(2)),
                DiscussionReply(id: "r2", authorName: "Aarav R.", authorRole: "Student", body: "Will the timetable be on the app too?", createdAt: ago(1)),
            ],
            "2": [
                DiscussionReply(id: "r3", authorName: "Aarav R.", authorRole: "Student", body: "Count me in, thank you sir.", createdAt: ago(6)),
                DiscussionReply(id: "r4", authorName: "Divya S.", authorRole: "Student", body: "Can we cover AVL trees as well?", createdAt: ago(5)),
                DiscussionReply(id: "r5", authorName: "Prof. Karthik Raman", authorRole: "Faculty", body: "Yes, we'll do balancing and traversals.", createdAt: ago(4)),
            ],
            "3": [
                DiscussionReply(id: "r6", authorName: "Divya S.", authorRole: "Student", body: "Interested — I'm in ECE, is that fine?", createdAt: ago(20)),
            ],
            "4": [],
        ]
    }

    func threads() async throws -> [DiscussionThread] {
        try await Task.sleep(for: latency)
        return threadsStore
    }

    func thread(id: String) async throws -> DiscussionThreadDetail {
        try await Task.sleep(for: latency)
        guard let thread = threadsStore.first(where: { $0.id == id }) else {
            throw APIError.httpStatus(404)
        }
        return DiscussionThreadDetail(thread: thread, replies: repliesStore[id] ?? [])
    }

    func createThread(title: String, body: String, category: DiscussionCategory) async throws -> DiscussionThread {
        try await Task.sleep(for: latency)
        nextID += 1
        let thread = DiscussionThread(
            id: "\(nextID)",
            authorName: "You",
            authorRole: nil,
            category: category,
            title: title,
            body: body,
            createdAt: .now,
            replyCount: 0,
            likeCount: 0,
            isPinned: false,
            isLiked: false
        )
        threadsStore.insert(thread, at: 0)
        repliesStore[thread.id] = []
        return thread
    }

    func addReply(threadID: String, body: String) async throws -> DiscussionReply {
        try await Task.sleep(for: latency)
        nextID += 1
        let reply = DiscussionReply(id: "\(nextID)", authorName: "You", authorRole: nil, body: body, createdAt: .now)
        repliesStore[threadID, default: []].append(reply)
        if let index = threadsStore.firstIndex(where: { $0.id == threadID }) {
            threadsStore[index].replyCount += 1
        }
        return reply
    }

    func setLiked(threadID: String, liked: Bool) async throws {
        try await Task.sleep(for: latency)
        guard let index = threadsStore.firstIndex(where: { $0.id == threadID }) else { return }
        if threadsStore[index].isLiked != liked {
            threadsStore[index].isLiked = liked
            threadsStore[index].likeCount += liked ? 1 : -1
        }
    }
}
