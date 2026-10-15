//
//  MessagingService.swift
//  Gradit
//

import Foundation

protocol MessagingServiceProtocol {
    /// Inbox for a student (parent passes the selected student's ID; a student passes nil).
    func messages(studentID: String?) async throws -> [Message]
    /// Students linked to the signed-in parent (for the switcher).
    func linkedStudents() async throws -> [LinkedStudent]
    func markRead(id: String) async throws
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class MessagingService: MessagingServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func messages(studentID: String?) async throws -> [Message] {
        var endpoint = Endpoint(path: "/messages")
        if let studentID {
            endpoint.queryItems = [URLQueryItem(name: "student_id", value: studentID)]
        }
        return try await client.send(endpoint)
    }

    func linkedStudents() async throws -> [LinkedStudent] {
        try await client.send(Endpoint(path: "/parent/students"))
    }

    func markRead(id: String) async throws {
        try await client.sendRaw(Endpoint(path: "/messages/\(id)/read", method: .post))
    }
}
