//
//  TimetableService.swift
//  Gradit
//

import Foundation

protocol TimetableServiceProtocol {
    // Admin
    func timetables() async throws -> [TimetableSummary]
    func editor(id: String?) async throws -> TimetableEditor

    // Faculty
    func facultyTimetable() async throws -> FacultyTimetable
    func swapRequests() async throws -> [SwapRequest]
    func swapCandidates(onDate date: String) async throws -> [SwapCandidate]

    // Learner (student / parent)
    func children() async throws -> [TimetableChild]
    func classTimetable(childID: String?) async throws -> ClassTimetable
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class TimetableService: TimetableServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func timetables() async throws -> [TimetableSummary] {
        try await client.send(Endpoint(path: "/timetables"))
    }

    func editor(id: String?) async throws -> TimetableEditor {
        try await client.send(Endpoint(path: id.map { "/timetables/\($0)/editor" } ?? "/timetables/new"))
    }

    func facultyTimetable() async throws -> FacultyTimetable {
        try await client.send(Endpoint(path: "/timetables/faculty/me"))
    }

    func swapRequests() async throws -> [SwapRequest] {
        try await client.send(Endpoint(path: "/timetables/faculty/swaps"))
    }

    func swapCandidates(onDate date: String) async throws -> [SwapCandidate] {
        var endpoint = Endpoint(path: "/timetables/faculty/swap-candidates")
        endpoint.queryItems = [URLQueryItem(name: "date", value: date)]
        return try await client.send(endpoint)
    }

    func children() async throws -> [TimetableChild] {
        try await client.send(Endpoint(path: "/timetables/children"))
    }

    func classTimetable(childID: String?) async throws -> ClassTimetable {
        var endpoint = Endpoint(path: "/timetables/class")
        if let childID { endpoint.queryItems = [URLQueryItem(name: "child_id", value: childID)] }
        return try await client.send(endpoint)
    }
}
