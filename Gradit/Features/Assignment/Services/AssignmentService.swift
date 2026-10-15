//
//  AssignmentService.swift
//  Gradit
//

import Foundation

/// Draft payload sent when a teacher publishes / saves an assignment.
nonisolated struct NewAssignmentDraft: Codable, Sendable {
    var title: String
    var description: String
    var department: String
    var yearSem: String
    var section: String
    var subject: String
    var maxMarks: Int
    var dueText: String
    var allStudents: Bool
    var pickedStudentIDs: [String]
    var attachmentNames: [String]
    var lateAllowed: Bool
    var resubmissionAllowed: Bool
    var scheduled: Bool
}

protocol AssignmentServiceProtocol {
    // Faculty
    func facultyAssignments() async throws -> [FacultyAssignment]
    func assignmentDetail(id: String) async throws -> AssignmentDetail
    func classStudents(department: String, yearSem: String, section: String) async throws -> [AssignmentSubmission]
    func saveGrade(assignmentID: String, submissionID: String, marks: Int, comment: String) async throws
    func publish(_ draft: NewAssignmentDraft) async throws

    // Learner (student / parent)
    func learnerAssignments(studentID: String?) async throws -> [LearnerAssignment]
    func learnerAssignmentDetail(id: String, studentID: String?) async throws -> LearnerAssignmentDetail
    func submit(assignmentID: String, fileNames: [String], comment: String) async throws
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class AssignmentService: AssignmentServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func facultyAssignments() async throws -> [FacultyAssignment] {
        try await client.send(Endpoint(path: "/assignments/faculty"))
    }

    func assignmentDetail(id: String) async throws -> AssignmentDetail {
        try await client.send(Endpoint(path: "/assignments/\(id)"))
    }

    func classStudents(department: String, yearSem: String, section: String) async throws -> [AssignmentSubmission] {
        var endpoint = Endpoint(path: "/assignments/class-students")
        endpoint.queryItems = [
            URLQueryItem(name: "department", value: department),
            URLQueryItem(name: "year_sem", value: yearSem),
            URLQueryItem(name: "section", value: section),
        ]
        return try await client.send(endpoint)
    }

    func saveGrade(assignmentID: String, submissionID: String, marks: Int, comment: String) async throws {
        let endpoint = try Endpoint.json("/assignments/\(assignmentID)/submissions/\(submissionID)/grade",
                                         body: ["marks": "\(marks)", "comment": comment])
        try await client.sendRaw(endpoint)
    }

    func publish(_ draft: NewAssignmentDraft) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        var endpoint = Endpoint(path: "/assignments", method: .post)
        endpoint.body = try encoder.encode(draft)
        try await client.sendRaw(endpoint)
    }

    func learnerAssignments(studentID: String?) async throws -> [LearnerAssignment] {
        var endpoint = Endpoint(path: "/assignments/learner")
        if let studentID { endpoint.queryItems = [URLQueryItem(name: "student_id", value: studentID)] }
        return try await client.send(endpoint)
    }

    func learnerAssignmentDetail(id: String, studentID: String?) async throws -> LearnerAssignmentDetail {
        var endpoint = Endpoint(path: "/assignments/learner/\(id)")
        if let studentID { endpoint.queryItems = [URLQueryItem(name: "student_id", value: studentID)] }
        return try await client.send(endpoint)
    }

    func submit(assignmentID: String, fileNames: [String], comment: String) async throws {
        let endpoint = try Endpoint.json("/assignments/learner/\(assignmentID)/submit",
                                         body: ["files": fileNames.joined(separator: ","), "comment": comment])
        try await client.sendRaw(endpoint)
    }
}
