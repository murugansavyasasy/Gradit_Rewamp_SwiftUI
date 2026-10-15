//
//  LearnerTimetableViewModels.swift
//  Gradit
//
//  View model for the student / parent class timetable.
//

import Foundation
import Observation
internal import os

@Observable
final class ClassTimetableViewModel {
    enum ViewMode: String, CaseIterable, Identifiable {
        case day, week
        var id: String { rawValue }
        var title: String { self == .day ? String(localized: "Day") : String(localized: "Week") }
    }

    let role: UserRole
    var viewMode: ViewMode = .day
    var selectedDay = "7"
    private(set) var children: [TimetableChild] = []
    var selectedChildID: String?
    private(set) var data: ClassTimetable?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: TimetableServiceProtocol
    private var childTask: Task<Void, Never>?

    init(role: UserRole, service: TimetableServiceProtocol) {
        self.role = role
        self.service = service
    }

    var isParent: Bool { role == .parent }
    var periods: [LearnerPeriodItem] { data?.periodsByDay[selectedDay] ?? [] }

    func load() async {
        guard data == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if isParent, children.isEmpty {
                children = try await service.children()
                if selectedChildID == nil { selectedChildID = children.first?.id }
            }
            data = try await service.classTimetable(childID: selectedChildID)
            if let today = data?.days.first(where: { $0.isToday }) { selectedDay = today.date }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Class timetable load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { data = nil; children = []; Task { await load() } }

    func selectChild(_ id: String) {
        guard id != selectedChildID else { return }
        selectedChildID = id
        data = nil
        childTask?.cancel()
        childTask = Task {
            isLoading = true
            defer { isLoading = false }
            do {
                data = try await service.classTimetable(childID: selectedChildID)
                if let today = data?.days.first(where: { $0.isToday }) { selectedDay = today.date }
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
