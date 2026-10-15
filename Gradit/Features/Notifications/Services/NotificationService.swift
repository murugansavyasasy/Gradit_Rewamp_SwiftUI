//
//  NotificationService.swift
//  Gradit
//

import Foundation

protocol NotificationServiceProtocol {
    func notifications(role: UserRole) async throws -> [AppNotification]
    func markAllRead() async throws
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class NotificationService: NotificationServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func notifications(role: UserRole) async throws -> [AppNotification] {
        try await client.send(Endpoint(path: "/notifications"))
    }

    func markAllRead() async throws {
        let endpoint = try Endpoint.json("/notifications/read-all", body: ["read": "1"])
        _ = try await client.sendRaw(endpoint)
    }
}
