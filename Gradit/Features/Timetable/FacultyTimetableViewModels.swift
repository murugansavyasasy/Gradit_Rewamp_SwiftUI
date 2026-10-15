//
//  FacultyTimetableViewModels.swift
//  Gradit
//
//  View models for the faculty "my timetable" and swap requests.
//

import Foundation
import Observation
internal import os

// MARK: - My timetable

@Observable
final class MyTimetableViewModel {
    var selectedDay = "7"
    private(set) var data: FacultyTimetable?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: TimetableServiceProtocol

    init(service: TimetableServiceProtocol) {
        self.service = service
    }

    var periods: [FacultyPeriodItem] { data?.periodsByDay[selectedDay] ?? [] }

    func load() async {
        guard data == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            data = try await service.facultyTimetable()
            if let today = data?.days.first(where: { $0.isToday }) { selectedDay = today.date }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("My timetable load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { data = nil; Task { await load() } }
}

// MARK: - Swap requests

@Observable
final class SwapRequestsViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case all, pending, accepted, declined, expired
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .pending: String(localized: "Pending")
            case .accepted: String(localized: "Accepted")
            case .declined: String(localized: "Declined")
            case .expired: String(localized: "Expired")
            }
        }
    }

    var tab: Tab = .all
    private(set) var requests: [SwapRequest] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: TimetableServiceProtocol

    init(service: TimetableServiceProtocol) {
        self.service = service
    }

    func count(_ tab: Tab) -> Int {
        tab == .all ? requests.count : requests.filter { matches($0, tab) }.count
    }

    private func matches(_ request: SwapRequest, _ tab: Tab) -> Bool {
        switch tab {
        case .all: true
        case .pending: request.status == .pending || request.status == .needsReply
        case .accepted: request.status == .accepted
        case .declined: request.status == .declined
        case .expired: request.status == .expired
        }
    }

    var visible: [SwapRequest] { requests.filter { matches($0, tab) } }

    func load() async {
        guard requests.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            requests = try await service.swapRequests()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Swap requests load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { requests = []; Task { await load() } }

    func respond(to request: SwapRequest, accept: Bool) {
        guard let index = requests.firstIndex(where: { $0.id == request.id }) else { return }
        requests[index].status = accept ? .accepted : .declined
    }

    func cancel(_ request: SwapRequest) {
        requests.removeAll { $0.id == request.id }
    }
}
