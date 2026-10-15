//
//  FacultyViewModels.swift
//  Gradit
//
//  View models for the staff-facing Faculty directory, profile and free periods.
//

import Foundation
import Observation
internal import os

// MARK: - Directory

@Observable
final class FacultyDirectoryViewModel {
    enum Segment: String, CaseIterable, Identifiable {
        case byDepartment, byDivision, allFaculty
        var id: String { rawValue }
        var title: String {
            switch self {
            case .byDepartment: String(localized: "By department")
            case .byDivision: String(localized: "By division")
            case .allFaculty: String(localized: "All faculty")
            }
        }
    }

    var searchText = ""
    /// nil == All streams.
    var stream: String?
    var departments: [String] = []
    var yearSem = String(localized: "All")
    var division = String(localized: "All")
    var segment: Segment = .byDepartment

    private(set) var directory: FacultyDirectory?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: FacultyServiceProtocol
    private var loadTask: Task<Void, Never>?

    init(service: FacultyServiceProtocol) {
        self.service = service
    }

    var streamName: String { stream ?? String(localized: "All streams") }
    var hasActiveFilters: Bool { stream != nil || !departments.isEmpty }

    private func matches(_ member: FacultyMember) -> Bool {
        let q = searchText.trimmed.lowercased()
        return q.isEmpty || member.name.lowercased().contains(q)
            || member.subjects.lowercased().contains(q) || member.department.lowercased().contains(q)
    }

    var visibleDepartmentGroups: [FacultyDeptGroup] {
        (directory?.departmentGroups ?? []).compactMap { group in
            let members = group.members.filter(matches)
            return members.isEmpty ? nil : FacultyDeptGroup(department: group.department, presentToday: group.presentToday, members: members)
        }
    }

    var visibleDivisionGroups: [FacultyDivisionGroup] {
        (directory?.divisionGroups ?? []).compactMap { group in
            let members = group.members.filter(matches)
            return members.isEmpty ? nil : FacultyDivisionGroup(id: group.id, divisionLabel: group.divisionLabel, classTeacher: group.classTeacher, members: members)
        }
    }

    var visibleAllFaculty: [FacultyMember] { (directory?.allFaculty ?? []).filter(matches) }

    var isEmpty: Bool {
        switch segment {
        case .byDepartment: visibleDepartmentGroups.isEmpty
        case .byDivision: visibleDivisionGroups.isEmpty
        case .allFaculty: visibleAllFaculty.isEmpty
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            directory = try await service.directory(stream: stream, departments: departments, yearSem: yearSem, division: division)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Faculty directory load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() {
        loadTask?.cancel()
        loadTask = Task { await load() }
    }

    func apply(stream: String?) {
        self.stream = (stream == "All streams") ? nil : stream
        departments = []
        reload()
    }

    func apply(departments: [String]) {
        self.departments = departments.filter { $0 != String(localized: "All departments") }
        reload()
    }

    func resetAll() {
        stream = nil
        departments = []
        reload()
    }
}

// MARK: - Profile

@Observable
final class FacultyProfileViewModel {
    let facultyID: String
    private(set) var profile: FacultyProfile?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: FacultyServiceProtocol

    init(facultyID: String, service: FacultyServiceProtocol) {
        self.facultyID = facultyID
        self.service = service
    }

    func load() async {
        guard profile == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await service.profile(id: facultyID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Faculty profile load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { profile = nil; Task { await load() } }
}

// MARK: - Free periods

@Observable
final class FreePeriodsViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case all, unallocated, allocated
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .unallocated: String(localized: "Unallocated")
            case .allocated: String(localized: "Allocated")
            }
        }
    }

    var tab: Tab = .all
    private(set) var day: FreePeriodsDay?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: FacultyServiceProtocol

    init(service: FacultyServiceProtocol) {
        self.service = service
    }

    func count(_ tab: Tab) -> Int {
        guard let day else { return 0 }
        switch tab {
        case .all: return day.periods.count
        case .unallocated: return day.periods.filter { $0.allocation == .unallocated }.count
        case .allocated: return day.periods.filter { $0.allocation == .allocated }.count
        }
    }

    var visiblePeriods: [FreePeriod] {
        guard let day else { return [] }
        switch tab {
        case .all: return day.periods
        case .unallocated: return day.periods.filter { $0.allocation == .unallocated }
        case .allocated: return day.periods.filter { $0.allocation == .allocated }
        }
    }

    func allocate(_ period: FreePeriod, to teacher: String) {
        guard let index = day?.periods.firstIndex(where: { $0.id == period.id }) else { return }
        day?.periods[index].allocation = .allocated
        day?.periods[index].allocatedTo = teacher
    }

    func load() async {
        guard day == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            day = try await service.freePeriods()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Free periods load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { day = nil; Task { await load() } }
}
