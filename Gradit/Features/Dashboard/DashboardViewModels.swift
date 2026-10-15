//
//  DashboardViewModels.swift
//  Gradit
//

import Foundation
import Observation
internal import os

/// Loads one dashboard payload. Keeps the last good payload visible if a refresh fails.
@Observable
final class DashboardViewModel<Dashboard> {
    private(set) var dashboard: Dashboard?
    private(set) var isLoading = false
    var errorMessage: String?

    private let fetch: () async throws -> Dashboard

    init(fetch: @escaping () async throws -> Dashboard) {
        self.fetch = fetch
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            dashboard = try await fetch()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Dashboard load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}

/// Faculty home: dashboard + approve / reject leave requests.
@Observable
final class FacultyDashboardViewModel {
    let content: DashboardViewModel<FacultyDashboard>
    private(set) var decisions: [LeaveRequest.ID: LeaveDecision] = [:]
    private(set) var submittingIDs: Set<LeaveRequest.ID> = []
    var actionErrorMessage: String?

    private let service: DashboardServiceProtocol

    init(service: DashboardServiceProtocol) {
        self.service = service
        self.content = DashboardViewModel { try await service.facultyDashboard() }
    }

    var pendingLeaveCount: Int {
        (content.dashboard?.leaveRequests ?? []).filter { decisions[$0.id] == nil }.count
    }

    /// Optimistic: shows the result immediately, rolls back if the request fails.
    func respond(to request: LeaveRequest, with decision: LeaveDecision) async {
        guard decisions[request.id] == nil, !submittingIDs.contains(request.id) else { return }
        decisions[request.id] = decision
        submittingIDs.insert(request.id)
        defer { submittingIDs.remove(request.id) }

        do {
            try await service.respondToLeave(id: request.id, decision: decision)
        } catch {
            decisions[request.id] = nil
            actionErrorMessage = error.localizedDescription
        }
    }
}

/// Parent and Student home. Parents can switch between linked students.
@Observable
final class LearnerDashboardViewModel {
    let role: UserRole
    private(set) var dashboard: LearnerDashboard?
    private(set) var students: [LinkedStudent] = []
    private(set) var selectedStudentID: LinkedStudent.ID?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: DashboardServiceProtocol

    init(role: UserRole, service: DashboardServiceProtocol) {
        self.role = role
        self.service = service
    }

    var isParent: Bool { role == .parent }

    var selectedStudent: LinkedStudent? {
        students.first { $0.id == selectedStudentID }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if isParent {
                if students.isEmpty {
                    students = try await service.linkedStudents()
                }
                if selectedStudentID == nil {
                    selectedStudentID = students.first?.id
                }
            }
            dashboard = try await service.learnerDashboard(studentID: isParent ? selectedStudentID : nil)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Learner dashboard load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func select(_ student: LinkedStudent) async {
        guard student.id != selectedStudentID else { return }
        selectedStudentID = student.id
        dashboard = nil
        await load()
    }
}
