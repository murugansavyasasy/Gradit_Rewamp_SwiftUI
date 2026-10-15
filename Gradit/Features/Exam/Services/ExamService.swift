//
//  ExamService.swift
//  Gradit
//

import Foundation

protocol ExamServiceProtocol {
    func children() async throws -> [FacultyChild]
    func examApplications(childID: String?) async throws -> ExamBundle
    func examApplicationDetail(childID: String?, id: String) async throws -> ExamApplicationDetail
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class ExamService: ExamServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func children() async throws -> [FacultyChild] {
        try await client.send(Endpoint(path: "/exam-applications/children"))
    }

    func examApplications(childID: String?) async throws -> ExamBundle {
        var endpoint = Endpoint(path: "/exam-applications")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }

    func examApplicationDetail(childID: String?, id: String) async throws -> ExamApplicationDetail {
        var endpoint = Endpoint(path: "/exam-applications/\(id)")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }
}
