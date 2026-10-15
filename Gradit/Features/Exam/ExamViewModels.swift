//
//  ExamViewModels.swift
//  Gradit
//
//  View models for the student / parent Exam Application Details.
//

import Foundation
import Observation
internal import os

@Observable
final class ExamListViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case open, applied, closed
        var id: String { rawValue }
        var title: String {
            switch self {
            case .open: String(localized: "Open")
            case .applied: String(localized: "Applied")
            case .closed: String(localized: "Closed")
            }
        }
        func matches(_ status: ExamAppStatus) -> Bool {
            switch self {
            case .open: status == .notApplied || status == .notEligible
            case .applied: status == .applied || status == .approved || status == .rejected || status == .paymentPending
            case .closed: status == .closed
            }
        }
    }

    let role: UserRole
    var tab: Tab = .open
    var searchText = ""
    var semester = String(localized: "All")
    var examType = String(localized: "All")

    private(set) var children: [FacultyChild] = []
    var selectedChildID: String?
    private(set) var bundle: ExamBundle?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: ExamServiceProtocol
    private var childTask: Task<Void, Never>?

    init(role: UserRole, service: ExamServiceProtocol) {
        self.role = role
        self.service = service
    }

    var isParent: Bool { role == .parent }
    var alert: ExamAlert? { bundle?.alert }

    private var items: [ExamApplicationItem] { bundle?.items ?? [] }

    func count(_ tab: Tab) -> Int { items.filter { tab.matches($0.status) }.count }

    var examTypeOptions: [String] {
        [String(localized: "All")] + Array(Set(items.map { $0.type.title })).sorted()
    }

    var visible: [ExamApplicationItem] {
        let all = String(localized: "All")
        let q = searchText.trimmed.lowercased()
        return items.filter { item in
            tab.matches(item.status)
                && (q.isEmpty || item.title.lowercased().contains(q))
                && (examType == all || item.type.title == examType)
        }
    }

    func load() async {
        guard bundle == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if isParent, children.isEmpty {
                children = try await service.children()
                if selectedChildID == nil { selectedChildID = children.first?.id }
            }
            bundle = try await service.examApplications(childID: selectedChildID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Exam applications load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { bundle = nil; children = []; Task { await load() } }

    func selectChild(_ id: String) {
        guard id != selectedChildID else { return }
        selectedChildID = id
        bundle = nil
        tab = .open
        childTask?.cancel()
        childTask = Task {
            isLoading = true
            defer { isLoading = false }
            do {
                bundle = try await service.examApplications(childID: selectedChildID)
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

@Observable
final class ExamDetailViewModel {
    let childID: String?
    let examID: String
    private(set) var detail: ExamApplicationDetail?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: ExamServiceProtocol

    init(childID: String?, examID: String, service: ExamServiceProtocol) {
        self.childID = childID
        self.examID = examID
        self.service = service
    }

    func load() async {
        guard detail == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await service.examApplicationDetail(childID: childID, id: examID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reload() { detail = nil; Task { await load() } }
}
