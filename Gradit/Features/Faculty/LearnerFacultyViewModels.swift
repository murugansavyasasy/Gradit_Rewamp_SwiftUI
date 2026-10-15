//
//  LearnerFacultyViewModels.swift
//  Gradit
//
//  View models for the student / parent "my teachers by semester" flow.
//

import Foundation
import Observation
internal import os

@Observable
final class LearnerFacultyViewModel {
    enum SubjectFilter: String, CaseIterable, Identifiable {
        case all, theory, labsActivities
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .theory: String(localized: "Theory")
            case .labsActivities: String(localized: "Labs & activities")
            }
        }
    }

    let role: UserRole
    private(set) var children: [FacultyChild] = []
    var selectedChildID: String?
    private(set) var semesters: [SemesterOption] = []
    var selectedSemester = 5
    var subjectFilter: SubjectFilter = .all

    private(set) var data: SemesterFaculty?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: FacultyServiceProtocol
    private var semesterTask: Task<Void, Never>?

    init(role: UserRole, service: FacultyServiceProtocol) {
        self.role = role
        self.service = service
    }

    var isParent: Bool { role == .parent }

    var childName: String {
        children.first { $0.id == selectedChildID }?.name.components(separatedBy: " ").first ?? String(localized: "My")
    }

    var headerSubtitle: String {
        String(localized: "\(childName)'s teachers by semester")
    }

    func filteredTeachers() -> [LearnerTeacher] {
        guard let data else { return [] }
        return data.teachers.compactMap { teacher in
            let subjects: [LearnerTeacherSubject]
            switch subjectFilter {
            case .all: subjects = teacher.subjects
            case .theory: subjects = teacher.subjects.filter { $0.kind == .theory }
            case .labsActivities: subjects = teacher.subjects.filter { $0.kind != .theory }
            }
            guard !subjects.isEmpty else { return nil }
            return LearnerTeacher(id: teacher.id, name: teacher.name, designation: teacher.designation,
                                  role: teacher.role, subjects: subjects, awayNote: teacher.awayNote)
        }
    }

    func load() async {
        guard data == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if isParent, children.isEmpty {
                children = try await service.children()
                if selectedChildID == nil { selectedChildID = children.first?.id }
            }
            if semesters.isEmpty {
                semesters = try await service.semesters(childID: selectedChildID)
                selectedSemester = semesters.first { $0.state == .current }?.id ?? selectedSemester
            }
            data = try await service.semesterFaculty(childID: selectedChildID, semester: selectedSemester)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Learner faculty load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { data = nil; semesters = []; children = []; Task { await load() } }

    func selectChild(_ id: String) {
        guard id != selectedChildID else { return }
        selectedChildID = id
        semesters = []
        reloadSemester(resetSemester: true)
    }

    func selectSemester(_ id: Int) {
        guard id != selectedSemester else { return }
        selectedSemester = id
        reloadSemester(resetSemester: false)
    }

    private func reloadSemester(resetSemester: Bool) {
        semesterTask?.cancel()
        data = nil
        semesterTask = Task {
            isLoading = true
            defer { isLoading = false }
            do {
                if semesters.isEmpty {
                    semesters = try await service.semesters(childID: selectedChildID)
                    if resetSemester {
                        selectedSemester = semesters.first { $0.state == .current }?.id ?? selectedSemester
                    }
                }
                data = try await service.semesterFaculty(childID: selectedChildID, semester: selectedSemester)
                errorMessage = nil
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

@Observable
final class LearnerFacultyProfileViewModel {
    let teacherID: String
    let childID: String?
    private(set) var profile: LearnerFacultyProfile?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: FacultyServiceProtocol

    init(teacherID: String, childID: String?, service: FacultyServiceProtocol) {
        self.teacherID = teacherID
        self.childID = childID
        self.service = service
    }

    func load() async {
        guard profile == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await service.learnerProfile(teacherID: teacherID, childID: childID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Learner faculty profile load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { profile = nil; Task { await load() } }
}
