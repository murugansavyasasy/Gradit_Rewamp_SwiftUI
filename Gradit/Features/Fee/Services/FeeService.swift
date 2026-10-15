//
//  FeeService.swift
//  Gradit
//

import Foundation

protocol FeeServiceProtocol {
    func children() async throws -> [FacultyChild]
    func feeDetails(childID: String?) async throws -> FeeDetails
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class FeeService: FeeServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func children() async throws -> [FacultyChild] {
        try await client.send(Endpoint(path: "/fees/children"))
    }

    func feeDetails(childID: String?) async throws -> FeeDetails {
        var endpoint = Endpoint(path: "/fees")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }
}
