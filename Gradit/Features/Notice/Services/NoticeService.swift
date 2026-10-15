//
//  NoticeService.swift
//  Gradit
//

import Foundation

protocol NoticeServiceProtocol {
    // Admin / faculty
    func notices() async throws -> [NoticeItem]
    func notice(id: String) async throws -> NoticeDetail
    func publish(_ draft: NoticeDraft) async throws

    // Reader (student / parent)
    func readerNotices(studentID: String?) async throws -> [ReaderNotice]
    func readerNotice(id: String, studentID: String?) async throws -> NoticeDetail
    func markRead(id: String, read: Bool) async throws
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class NoticeService: NoticeServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func notices() async throws -> [NoticeItem] {
        try await client.send(Endpoint(path: "/notices"))
    }

    func notice(id: String) async throws -> NoticeDetail {
        try await client.send(Endpoint(path: "/notices/\(id)"))
    }

    func publish(_ draft: NoticeDraft) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        var endpoint = Endpoint(path: "/notices", method: .post)
        endpoint.body = try encoder.encode(draft)
        try await client.sendRaw(endpoint)
    }

    func readerNotices(studentID: String?) async throws -> [ReaderNotice] {
        var endpoint = Endpoint(path: "/notices/reader")
        if let studentID { endpoint.queryItems = [URLQueryItem(name: "student_id", value: studentID)] }
        return try await client.send(endpoint)
    }

    func readerNotice(id: String, studentID: String?) async throws -> NoticeDetail {
        var endpoint = Endpoint(path: "/notices/reader/\(id)")
        if let studentID { endpoint.queryItems = [URLQueryItem(name: "student_id", value: studentID)] }
        return try await client.send(endpoint)
    }

    func markRead(id: String, read: Bool) async throws {
        let endpoint = try Endpoint.json("/notices/\(id)/read", body: ["read": read ? "1" : "0"])
        try await client.sendRaw(endpoint)
    }
}
