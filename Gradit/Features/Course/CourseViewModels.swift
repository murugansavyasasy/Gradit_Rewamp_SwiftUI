//
//  CourseViewModels.swift
//  Gradit
//
//  View models for the student / parent Course Details.
//

import Foundation
import Observation
internal import os

@Observable
final class CourseDetailsViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case overview, subjects, syllabus, faculty
        var id: String { rawValue }
        var title: String {
            switch self {
            case .overview: String(localized: "Overview")
            case .subjects: String(localized: "Subjects")
            case .syllabus: String(localized: "Syllabus")
            case .faculty: String(localized: "Faculty")
            }
        }
    }

    let role: UserRole
    var tab: Tab = .overview
    var selectedSemester = 5
    private(set) var children: [FacultyChild] = []
    var selectedChildID: String?
    private(set) var bundle: CourseBundle?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: CourseServiceProtocol
    private var childTask: Task<Void, Never>?

    init(role: UserRole, service: CourseServiceProtocol) {
        self.role = role
        self.service = service
    }

    var isParent: Bool { role == .parent }
    var overview: CourseOverview? { bundle?.overview }
    var semesters: [SemesterBlock] { bundle?.semesters ?? [] }
    var currentBlock: SemesterBlock? { semesters.first { $0.semester == selectedSemester } }

    func load() async {
        guard bundle == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if isParent, children.isEmpty {
                children = try await service.children()
                if selectedChildID == nil { selectedChildID = children.first?.id }
            }
            let data = try await service.course(childID: selectedChildID)
            bundle = data
            selectedSemester = data.semesters.first { $0.status == .current }?.semester ?? selectedSemester
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Course load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { bundle = nil; children = []; Task { await load() } }

    func selectChild(_ id: String) {
        guard id != selectedChildID else { return }
        selectedChildID = id
        bundle = nil
        tab = .overview
        childTask?.cancel()
        childTask = Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let data = try await service.course(childID: selectedChildID)
                bundle = data
                selectedSemester = data.semesters.first { $0.status == .current }?.semester ?? selectedSemester
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

@Observable
final class SubjectDetailViewModel {
    let childID: String?
    let code: String
    private(set) var detail: SubjectDetail?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: CourseServiceProtocol

    init(childID: String?, code: String, service: CourseServiceProtocol) {
        self.childID = childID
        self.code = code
        self.service = service
    }

    func load() async {
        guard detail == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await service.subjectDetail(childID: childID, code: code)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reload() { detail = nil; Task { await load() } }
}
