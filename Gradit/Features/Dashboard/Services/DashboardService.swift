//
//  DashboardService.swift
//  Gradit
//

import Foundation

protocol DashboardServiceProtocol {
    func managementDashboard() async throws -> ManagementDashboard
    func facultyDashboard() async throws -> FacultyDashboard
    /// Students linked to the signed-in parent.
    func linkedStudents() async throws -> [LinkedStudent]
    /// Parent passes the selected student's ID; a student passes nil for their own dashboard.
    func learnerDashboard(studentID: String?) async throws -> LearnerDashboard
    func respondToLeave(id: String, decision: LeaveDecision) async throws
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class DashboardService: DashboardServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func managementDashboard() async throws -> ManagementDashboard {
        try await client.send(Endpoint(path: "/dashboard/management"))
    }

    func facultyDashboard() async throws -> FacultyDashboard {
        try await client.send(Endpoint(path: "/dashboard/faculty"))
    }

    func linkedStudents() async throws -> [LinkedStudent] {
        try await client.send(Endpoint(path: "/parent/students"))
    }

    func learnerDashboard(studentID: String?) async throws -> LearnerDashboard {
        var endpoint = Endpoint(path: "/dashboard/learner")
        if let studentID {
            endpoint.queryItems = [URLQueryItem(name: "student_id", value: studentID)]
        }
        return try await client.send(endpoint)
    }

    func respondToLeave(id: String, decision: LeaveDecision) async throws {
        try await client.sendRaw(.json("/leave-requests/\(id)/decision", body: ["decision": decision.rawValue]))
    }
}
