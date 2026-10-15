//
//  DashboardTests.swift
//  GraditTests
//

import Foundation
import Testing
@testable import Gradit

@MainActor
struct DashboardTests {

    // MARK: Role → tabs

    @Test func managementAndFacultyShareStaffTabs() {
        let expected: [DashboardTab] = [.home, .attendance, .messages, .notices, .profile]
        #expect(DashboardTab.tabs(for: .management) == expected)
        #expect(DashboardTab.tabs(for: .faculty) == expected)
    }

    @Test func parentAndStudentShareLearnerTabs() {
        let expected: [DashboardTab] = [.home, .attendance, .notices, .chat, .me]
        #expect(DashboardTab.tabs(for: .parent) == expected)
        #expect(DashboardTab.tabs(for: .student) == expected)
    }

    @Test func menusMatchDesignCounts() {
        #expect(DashboardMenus.management.count == 10)
        #expect(DashboardMenus.faculty.count == 8)
        #expect(DashboardMenus.learner.count == 15)
    }

    // MARK: Formatting

    @Test func greetingUsesTimeOfDayAndShortName() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let morning = calendar.date(from: DateComponents(year: 2026, month: 10, day: 9, hour: 9))!
        let evening = calendar.date(from: DateComponents(year: 2026, month: 10, day: 9, hour: 19))!

        #expect(DashboardGreeting.text(name: "Dr. Suresh Kumar", date: morning, calendar: calendar) == "Good morning, Dr. Suresh")
        #expect(DashboardGreeting.text(name: "Rajesh Sharma", date: evening, calendar: calendar) == "Good evening, Rajesh")
    }

    @Test func initialsSkipHonorifics() {
        #expect(DashboardGreeting.initials("Dr. Meena Iyer") == "MI")
        #expect(DashboardGreeting.initials("Aarav Sharma") == "AS")
        #expect(DashboardGreeting.initials("Rahul") == "R")
    }

    @Test func percentFormatting() {
        #expect(DashboardFormat.percent(92) == "92%")
        #expect(DashboardFormat.percent(87.3) == "87.3%")
    }

    // MARK: Router

    @Test func reselectingTabPopsToRoot() {
        let router = AppRouter()
        router.push(.feature(.events))
        #expect(!router.isAtRoot(.home))
        router.select(.home)
        #expect(router.isAtRoot(.home))
    }

    // MARK: View models

    @Test func parentLoadsFirstLinkedStudent() async {
        let viewModel = LearnerDashboardViewModel(role: .parent, service: MockDashboardService(latency: .zero))
        await viewModel.load()
        #expect(viewModel.selectedStudent?.name == "Aarav Sharma")
        #expect(viewModel.dashboard?.feeDue != nil)
    }

    @Test func parentCanSwitchStudent() async throws {
        let viewModel = LearnerDashboardViewModel(role: .parent, service: MockDashboardService(latency: .zero))
        await viewModel.load()
        let isha = try #require(viewModel.students.last)
        await viewModel.select(isha)
        #expect(viewModel.dashboard?.studentFirstName == "Isha")
    }

    @Test func studentDoesNotLoadLinkedStudents() async {
        let viewModel = LearnerDashboardViewModel(role: .student, service: MockDashboardService(latency: .zero))
        await viewModel.load()
        #expect(viewModel.students.isEmpty)
        #expect(viewModel.dashboard?.feeDue == nil)
    }

    @Test func approvingLeaveUpdatesPendingCount() async throws {
        let viewModel = FacultyDashboardViewModel(service: MockDashboardService(latency: .zero))
        await viewModel.content.load()
        #expect(viewModel.pendingLeaveCount == 2)

        let request = try #require(viewModel.content.dashboard?.leaveRequests.first)
        await viewModel.respond(to: request, with: .approved)
        #expect(viewModel.decisions[request.id] == .approved)
        #expect(viewModel.pendingLeaveCount == 1)
    }

    @Test func failedLeaveResponseRollsBack() async throws {
        let service = MockDashboardService(latency: .zero)
        service.failLeaveResponses = true
        let viewModel = FacultyDashboardViewModel(service: service)
        await viewModel.content.load()

        let request = try #require(viewModel.content.dashboard?.leaveRequests.first)
        await viewModel.respond(to: request, with: .rejected)
        #expect(viewModel.decisions[request.id] == nil)
        #expect(viewModel.actionErrorMessage != nil)
    }
}
