//
//  AttendanceRoleViewModels.swift
//  Gradit
//
//  View models for the faculty (mark + leave) attendance screens.
//

import Foundation
import Observation
internal import os

@Observable
final class FacultyAttendanceViewModel {
    enum Tab: String, CaseIterable, Identifiable { case classes, leaveRequests; var id: String { rawValue } }

    var tab: Tab = .classes
    var leaveFilter: LeaveStatus = .pending
    private(set) var classes: [FacultyClassSession] = []
    private(set) var leaves: [StudentLeaveRequest] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: AttendanceServiceProtocol

    init(service: AttendanceServiceProtocol) {
        self.service = service
    }

    var pendingClassCount: Int { classes.filter { !$0.isTaken }.count }
    func leaveCount(_ status: LeaveStatus) -> Int { leaves.filter { $0.status == status }.count }
    var pendingLeaveCount: Int { leaveCount(.pending) }
    var visibleLeaves: [StudentLeaveRequest] { leaves.filter { $0.status == leaveFilter } }

    func load() async {
        guard classes.isEmpty, leaves.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let classes = service.facultyClasses()
            async let leaves = service.leaveRequests()
            self.classes = try await classes
            self.leaves = try await leaves
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Faculty attendance load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { classes = []; leaves = []; Task { await load() } }

    /// Optimistic approve/reject.
    func respond(to leave: StudentLeaveRequest, decision: LeaveStatus) {
        guard let index = leaves.firstIndex(where: { $0.id == leave.id }) else { return }
        leaves[index].status = decision
    }

    /// Reflect a class that was just marked from the Mark screen.
    func markTaken(sessionID: String, present: Int) {
        guard let index = classes.firstIndex(where: { $0.id == sessionID }) else { return }
        classes[index].takenCount = present
    }
}

@Observable
final class MarkAttendanceViewModel {
    enum Mode: String, CaseIterable, Identifiable { case general, theory, practical; var id: String { rawValue }
        var title: String {
            switch self {
            case .general: String(localized: "General")
            case .theory: String(localized: "Theory")
            case .practical: String(localized: "Practical")
            }
        }
    }

    let session: FacultyClassSession
    var mode: Mode = .practical
    var topic = ""
    var searchText = ""
    var statusFilter: MarkStatus?
    private(set) var roster: [RosterStudent] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: AttendanceServiceProtocol

    init(session: FacultyClassSession, service: AttendanceServiceProtocol) {
        self.session = session
        self.service = service
    }

    var periodLabel: String { String(localized: "Period \(session.period.replacingOccurrences(of: "P", with: "")) · \(session.time)") }

    func count(_ status: MarkStatus) -> Int { roster.filter { $0.status == status }.count }
    var presentCount: Int { count(.present) }

    var visible: [RosterStudent] {
        let q = searchText.trimmed.lowercased()
        return roster.filter { student in
            (statusFilter == nil || student.status == statusFilter)
                && (q.isEmpty || student.name.lowercased().contains(q)
                    || student.registerNo.contains(q) || student.admissionNo.lowercased().contains(q))
        }
    }

    var absentNames: [String] { roster.filter { $0.status == .absent }.map(\.name) }

    func load() async {
        guard roster.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            roster = try await service.classRoster(sessionID: session.id)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Tapping the circle toggles Present ⇄ Absent.
    func toggle(_ student: RosterStudent) {
        guard let index = roster.firstIndex(where: { $0.id == student.id }) else { return }
        roster[index].status = roster[index].status == .present ? .absent : .present
    }

    func set(_ status: MarkStatus, for student: RosterStudent) {
        guard let index = roster.firstIndex(where: { $0.id == student.id }) else { return }
        // Toggling a specific status off returns the student to Present.
        roster[index].status = (roster[index].status == status) ? .present : status
    }

    func markAllPresent() {
        for index in roster.indices { roster[index].status = .present }
    }
}

@Observable
final class LearnerAttendanceViewModel {
    enum PrimaryTab: String, CaseIterable, Identifiable { case attendance, leaveHistory; var id: String { rawValue } }
    enum SecondaryTab: String, CaseIterable, Identifiable { case calendar, subjectWise; var id: String { rawValue } }

    let role: UserRole
    var primaryTab: PrimaryTab = .attendance
    var secondaryTab: SecondaryTab = .calendar
    private(set) var data: LearnerAttendance?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: AttendanceServiceProtocol

    init(role: UserRole, service: AttendanceServiceProtocol) {
        self.role = role
        self.service = service
    }

    func status(forDay day: Int) -> LearnerDayStatus {
        data?.days.first { $0.id == day }?.status ?? .none
    }

    func isToday(_ day: Int) -> Bool {
        data?.days.first { $0.id == day }?.isToday ?? false
    }

    func load() async {
        guard data == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            data = try await service.learnerAttendance(studentID: role == .parent ? "s1" : nil)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Learner attendance load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { data = nil; Task { await load() } }
}

@Observable
final class SelfCheckInViewModel {
    private(set) var state: SelfAttendanceState?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: AttendanceServiceProtocol
    /// Kept in memory to compute worked hours on check-out.
    private var checkInDate: Date?

    init(service: AttendanceServiceProtocol) {
        self.service = service
    }

    var hasCheckedIn: Bool { state?.checkInTime != nil }
    var hasCheckedOut: Bool { state?.checkOutTime != nil }

    func load() async {
        guard state == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            state = try await service.selfAttendance()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Self attendance load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { state = nil; checkInDate = nil; Task { await load() } }

    /// Punch in now (optimistic — the backend call would confirm).
    func checkIn(at date: Date) {
        guard state != nil, !hasCheckedIn else { return }
        checkInDate = date
        state?.checkInTime = Self.timeFormatter.string(from: date)
        state?.shiftStartNote = String(localized: "Checked in at \(Self.timeFormatter.string(from: date)). Have a good day!")
    }

    /// Punch out now and fill the worked-hours summary.
    func checkOut(at date: Date) {
        guard state != nil, hasCheckedIn, !hasCheckedOut else { return }
        state?.checkOutTime = Self.timeFormatter.string(from: date)
        if let start = checkInDate {
            let minutes = max(0, Int(date.timeIntervalSince(start) / 60))
            let hours = String(format: "%dh %02dm", minutes / 60, minutes % 60)
            state?.hoursText = hours
            state?.shiftStartNote = String(localized: "Checked out at \(Self.timeFormatter.string(from: date)) · total \(hours).")
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()
}
