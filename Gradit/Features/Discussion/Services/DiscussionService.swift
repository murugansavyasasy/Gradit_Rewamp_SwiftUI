//
//  DiscussionService.swift
//  Gradit
//

import Foundation

protocol DiscussionServiceProtocol {
    /// All threads the signed-in user can see (filtered client-side by category).
    func threads() async throws -> [DiscussionThread]
    func thread(id: String) async throws -> DiscussionThreadDetail
    func createThread(title: String, body: String, category: DiscussionCategory) async throws -> DiscussionThread
    func addReply(threadID: String, body: String) async throws -> DiscussionReply
    func setLiked(threadID: String, liked: Bool) async throws
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class DiscussionService: DiscussionServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func threads() async throws -> [DiscussionThread] {
        try await client.send(Endpoint(path: "/discussions"))
    }

    func thread(id: String) async throws -> DiscussionThreadDetail {
        try await client.send(Endpoint(path: "/discussions/\(id)"))
    }

    func createThread(title: String, body: String, category: DiscussionCategory) async throws -> DiscussionThread {
        try await client.send(.json("/discussions", body: [
            "title": title,
            "body": body,
            "category": category.rawValue,
        ]))
    }

    func addReply(threadID: String, body: String) async throws -> DiscussionReply {
        try await client.send(.json("/discussions/\(threadID)/replies", body: ["body": body]))
    }

    func setLiked(threadID: String, liked: Bool) async throws {
        try await client.sendRaw(Endpoint(path: "/discussions/\(threadID)/like", method: liked ? .post : .delete))
    }
}
