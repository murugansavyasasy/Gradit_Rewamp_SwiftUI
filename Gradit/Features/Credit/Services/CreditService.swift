//
//  CreditService.swift
//  Gradit
//

import Foundation

protocol CreditServiceProtocol {
    func children() async throws -> [FacultyChild]
    func credits(childID: String?) async throws -> CreditBundle
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class CreditService: CreditServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func children() async throws -> [FacultyChild] {
        try await client.send(Endpoint(path: "/credits/children"))
    }

    func credits(childID: String?) async throws -> CreditBundle {
        var endpoint = Endpoint(path: "/credits")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }
}
