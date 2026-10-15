//
//  PlacementService.swift
//  Gradit
//

import Foundation

protocol PlacementServiceProtocol {
    func children() async throws -> [FacultyChild]
    func items(kind: PlacementKind, tab: String, childID: String?) async throws -> PlacementBundle
    func detail(kind: PlacementKind, id: String, childID: String?) async throws -> PlacementDetail
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class PlacementService: PlacementServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    private func base(_ kind: PlacementKind) -> String {
        kind == .events ? "/placement/events" : "/placement/training"
    }

    func children() async throws -> [FacultyChild] {
        try await client.send(Endpoint(path: "/placement/children"))
    }

    func items(kind: PlacementKind, tab: String, childID: String?) async throws -> PlacementBundle {
        var endpoint = Endpoint(path: base(kind))
        var items = [URLQueryItem(name: "tab", value: tab)]
        if let childID { items.append(URLQueryItem(name: "child_id", value: childID)) }
        endpoint.queryItems = items
        return try await client.send(endpoint)
    }

    func detail(kind: PlacementKind, id: String, childID: String?) async throws -> PlacementDetail {
        var endpoint = Endpoint(path: "\(base(kind))/\(id)")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }
}
