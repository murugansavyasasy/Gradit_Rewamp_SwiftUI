//
//  UserService.swift
//  Gradit
//

import Foundation

protocol UserServiceProtocol {
    func fetchUsers() async throws -> [User]
}

final class UserService: UserServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchUsers() async throws -> [User] {
        try await client.send(Endpoint(path: "/users"))
    }
}

/// Used by previews and tests.
final class MockUserService: UserServiceProtocol {
    var result: Result<[User], Error>

    init(result: Result<[User], Error> = .success(User.samples)) {
        self.result = result
    }

    func fetchUsers() async throws -> [User] {
        try result.get()
    }
}
