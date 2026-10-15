//
//  CourseService.swift
//  Gradit
//

import Foundation

protocol CourseServiceProtocol {
    func children() async throws -> [FacultyChild]
    func course(childID: String?) async throws -> CourseBundle
    func subjectDetail(childID: String?, code: String) async throws -> SubjectDetail
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class CourseService: CourseServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func children() async throws -> [FacultyChild] {
        try await client.send(Endpoint(path: "/course/children"))
    }

    func course(childID: String?) async throws -> CourseBundle {
        var endpoint = Endpoint(path: "/course")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }

    func subjectDetail(childID: String?, code: String) async throws -> SubjectDetail {
        var endpoint = Endpoint(path: "/course/subject/\(code)")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }
}
