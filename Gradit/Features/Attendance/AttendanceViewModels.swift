//
//  AttendanceViewModels.swift
//  Gradit
//

import Foundation
import Observation
internal import os

/// Management / staff Attendance report: range + audience + department/sem filters.
@Observable
final class AttendanceReportViewModel {
    var range: AttendanceRange = .today
    var audience: AttendanceAudience = .students
    var department: String
    var yearSem: String
    var showTable = false

    private(set) var report: AttendanceReport?
    private(set) var isLoading = false
    var errorMessage: String?

    /// Filter options. "All" clears that filter.
    let departments = ["All", "CSE", "ECE", "MECH", "CIVIL", "EEE"]
    let yearSems = ["All", "III · Sem 6", "III · Sem 5", "II · Sem 4", "II · Sem 3", "I · Sem 2", "I · Sem 1"]

    private let service: AttendanceServiceProtocol
    private var loadTask: Task<Void, Never>?

    init(service: AttendanceServiceProtocol) {
        self.service = service
        self.department = "CSE"
        self.yearSem = "III · Sem 6"
    }

    /// "Tue, 4 Oct 2026"
    var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy"
        return formatter.string(from: .now)
    }

    var hasActiveFilters: Bool { department != "All" || yearSem != "All" }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            report = try await service.report(range: range, audience: audience, department: department, yearSem: yearSem)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Attendance report load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    /// Reload after a filter change, cancelling any in-flight request.
    func reload() {
        loadTask?.cancel()
        loadTask = Task { await load() }
    }

    func select(range: AttendanceRange) { self.range = range; reload() }
    func select(audience: AttendanceAudience) { self.audience = audience; reload() }
    func select(department: String) { self.department = department; reload() }
    func select(yearSem: String) { self.yearSem = yearSem; reload() }

    func clearFilters() {
        department = "All"
        yearSem = "All"
        reload()
    }
}

/// Management "Attendance" tab: Today staff punch-in + monthly Staff-wise report.
@Observable
final class StaffAttendanceViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case today, staffWise, report, classes
        var id: String { rawValue }
    }

    var tab: Tab = .today
    var searchText = ""
    var statusFilter: StaffStatus?        // Today: set by tapping a stat card
    var belowThresholdOnly = false        // Staff-wise: set by tapping "below 75%"
    var department = "All"
    var year = 2026
    var month: Int? = 10                  // nil == All months

    private(set) var today: StaffAttendanceToday?
    private(set) var monthly: StaffAttendanceMonthly?
    private(set) var isLoading = false
    var errorMessage: String?

    let departments = ["All", "CSE", "IT", "Mechanical", "Civil", "Mathematics", "Physics", "Computer Science"]
    let years = [2026, 2025, 2024]

    /// Statuses in the order the design groups them (Absent first).
    static let groupOrder: [StaffStatus] = [.absent, .late, .onLeave, .notPunchedIn, .present]

    private let service: AttendanceServiceProtocol
    private var loadTask: Task<Void, Never>?

    init(service: AttendanceServiceProtocol) {
        self.service = service
    }

    var monthLabel: String {
        guard let month else { return String(localized: "All months \(String(year))") }
        let symbols = DateFormatter().standaloneMonthSymbols ?? []
        let name = symbols.indices.contains(month - 1) ? symbols[month - 1] : "\(month)"
        return "\(name) \(year)"
    }

    // MARK: Today filtering

    private func matchesSearch(_ name: String, _ dept: String) -> Bool {
        let q = searchText.trimmed.lowercased()
        return q.isEmpty || name.lowercased().contains(q) || dept.lowercased().contains(q)
    }

    private func matchesDepartment(_ dept: String) -> Bool {
        department == "All" || dept.lowercased().contains(department.lowercased())
    }

    var todaySections: [(status: StaffStatus, staff: [StaffMember])] {
        guard let today else { return [] }
        let statuses = statusFilter.map { [$0] } ?? Self.groupOrder
        return statuses.compactMap { status in
            let members = today.staff.filter {
                $0.status == status && matchesSearch($0.name, $0.department) && matchesDepartment($0.department)
            }
            return members.isEmpty ? nil : (status, members)
        }
    }

    var todayVisibleCount: Int { todaySections.reduce(0) { $0 + $1.staff.count } }

    // MARK: Staff-wise filtering

    var monthlyVisible: [StaffMonthlyRow] {
        guard let monthly else { return [] }
        return monthly.staff.filter {
            matchesSearch($0.name, $0.department)
                && matchesDepartment($0.department)
                && (!belowThresholdOnly || $0.percent < 75)
        }
    }

    // MARK: Loading

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            switch tab {
            case .today:
                if today == nil { today = try await service.staffToday() }
            case .staffWise:
                monthly = try await service.staffMonthly(year: year, month: month)
            case .report, .classes:
                // Reuse self-contained child screens that load their own data.
                break
            }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Staff attendance load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() {
        loadTask?.cancel()
        loadTask = Task { await load() }
    }

    func select(tab: Tab) {
        guard tab != self.tab else { return }
        self.tab = tab
        statusFilter = nil
        searchText = ""
        reload()
    }

    func toggleStatusFilter(_ status: StaffStatus) {
        statusFilter = (statusFilter == status) ? nil : status
    }

    func clearTodayFilter() { statusFilter = nil; searchText = "" }
}
