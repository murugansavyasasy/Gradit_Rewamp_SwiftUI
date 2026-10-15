//
//  ResumeService.swift
//  Gradit
//

import Foundation

protocol ResumeServiceProtocol {
    func children() async throws -> [FacultyChild]
    func resume(childID: String?) async throws -> Resume
    func save(_ resume: Resume, childID: String?) async throws
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class ResumeService: ResumeServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func children() async throws -> [FacultyChild] {
        try await client.send(Endpoint(path: "/resume/children"))
    }

    func resume(childID: String?) async throws -> Resume {
        var endpoint = Endpoint(path: "/resume")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }

    func save(_ resume: Resume, childID: String?) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        var endpoint = Endpoint(path: "/resume", method: .post, body: try encoder.encode(resume))
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        _ = try await client.sendRaw(endpoint)
    }
}
