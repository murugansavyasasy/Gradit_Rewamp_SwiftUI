//
//  CreditViewModels.swift
//  Gradit
//
//  View model for the student / parent Sem Credit Points.
//

import Foundation
import Observation
internal import os

@Observable
final class CreditViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case byCategory, bySemester
        var id: String { rawValue }
        var title: String {
            switch self {
            case .byCategory: String(localized: "By category")
            case .bySemester: String(localized: "By semester")
            }
        }
    }

    let role: UserRole
    var tab: Tab = .byCategory
    var categoryFilter = String(localized: "All")
    var expandAll = false
    private(set) var expanded: Set<String> = []
    private(set) var children: [FacultyChild] = []
    var selectedChildID: String?
    private(set) var bundle: CreditBundle?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: CreditServiceProtocol
    private var childTask: Task<Void, Never>?

    init(role: UserRole, service: CreditServiceProtocol) {
        self.role = role
        self.service = service
    }

    var isParent: Bool { role == .parent }
    var summary: CreditSummary? { bundle?.summary }

    var categoryOptions: [String] {
        [String(localized: "All")] + (bundle?.categories.map(\.code) ?? [])
    }

    var visibleCategories: [CreditCategoryBlock] {
        let all = String(localized: "All")
        guard let categories = bundle?.categories else { return [] }
        return categoryFilter == all ? categories : categories.filter { $0.code == categoryFilter }
    }

    func isExpanded(_ key: String) -> Bool { expandAll || expanded.contains(key) }

    func toggle(_ key: String) {
        if expanded.contains(key) { expanded.remove(key) } else { expanded.insert(key) }
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
            bundle = try await service.credits(childID: selectedChildID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Credits load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { bundle = nil; children = []; Task { await load() } }

    func selectChild(_ id: String) {
        guard id != selectedChildID else { return }
        selectedChildID = id
        bundle = nil
        categoryFilter = String(localized: "All")
        expanded = []
        childTask?.cancel()
        childTask = Task {
            isLoading = true
            defer { isLoading = false }
            do {
                bundle = try await service.credits(childID: selectedChildID)
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
