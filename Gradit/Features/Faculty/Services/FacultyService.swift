//
//  FacultyService.swift
//  Gradit
//

import Foundation

protocol FacultyServiceProtocol {
    // Staff directory (management / faculty)
    func directory(stream: String?, departments: [String], yearSem: String, division: String) async throws -> FacultyDirectory
    func streams() async throws -> [FacultyStream]
    func departments(stream: String) async throws -> [FacultyDepartmentOption]
    func departmentSummary(_ department: String) async throws -> FacultyDeptSummary
    func profile(id: String) async throws -> FacultyProfile
    func freePeriods() async throws -> FreePeriodsDay

    // Learner (student / parent)
    func children() async throws -> [FacultyChild]
    func semesters(childID: String?) async throws -> [SemesterOption]
    func semesterFaculty(childID: String?, semester: Int) async throws -> SemesterFaculty
    func learnerProfile(teacherID: String, childID: String?) async throws -> LearnerFacultyProfile
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class FacultyService: FacultyServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func directory(stream: String?, departments: [String], yearSem: String, division: String) async throws -> FacultyDirectory {
        var endpoint = Endpoint(path: "/faculty/directory")
        var items = [URLQueryItem(name: "year_sem", value: yearSem), URLQueryItem(name: "division", value: division)]
        if let stream { items.append(URLQueryItem(name: "stream", value: stream)) }
        if !departments.isEmpty { items.append(URLQueryItem(name: "departments", value: departments.joined(separator: ","))) }
        endpoint.queryItems = items
        return try await client.send(endpoint)
    }

    func streams() async throws -> [FacultyStream] {
        try await client.send(Endpoint(path: "/faculty/streams"))
    }

    func departments(stream: String) async throws -> [FacultyDepartmentOption] {
        var endpoint = Endpoint(path: "/faculty/departments")
        endpoint.queryItems = [URLQueryItem(name: "stream", value: stream)]
        return try await client.send(endpoint)
    }

    func departmentSummary(_ department: String) async throws -> FacultyDeptSummary {
        var endpoint = Endpoint(path: "/faculty/department-summary")
        endpoint.queryItems = [URLQueryItem(name: "department", value: department)]
        return try await client.send(endpoint)
    }

    func profile(id: String) async throws -> FacultyProfile {
        try await client.send(Endpoint(path: "/faculty/\(id)"))
    }

    func freePeriods() async throws -> FreePeriodsDay {
        try await client.send(Endpoint(path: "/faculty/free-periods"))
    }

    func children() async throws -> [FacultyChild] {
        try await client.send(Endpoint(path: "/faculty/children"))
    }

    func semesters(childID: String?) async throws -> [SemesterOption] {
        var endpoint = Endpoint(path: "/faculty/semesters")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }

    func semesterFaculty(childID: String?, semester: Int) async throws -> SemesterFaculty {
        var endpoint = Endpoint(path: "/faculty/semester/\(semester)")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }

    func learnerProfile(teacherID: String, childID: String?) async throws -> LearnerFacultyProfile {
        var endpoint = Endpoint(path: "/faculty/learner/\(teacherID)")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }
}
