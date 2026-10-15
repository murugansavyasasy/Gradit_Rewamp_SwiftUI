//
//  User.swift
//  Gradit
//

import Foundation

nonisolated struct User: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var email: String
}

extension User {
    static let samples: [User] = [
        User(id: "1", name: "Asha Kumar", email: "asha@example.com"),
        User(id: "2", name: "Ravi Shankar", email: "ravi@example.com"),
        User(id: "3", name: "Meena Iyer", email: "meena@example.com"),
    ]
}
