//
//  PlacementViewModels.swift
//  Gradit
//
//  View models for the student / parent Placement Events & Training.
//

import Foundation
import Observation
internal import os

@Observable
final class PlacementListViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case upcoming, historical
        var id: String { rawValue }
        var title: String { self == .upcoming ? String(localized: "Upcoming") : String(localized: "Historical") }
    }

    let kind: PlacementKind
    let role: UserRole
    var tab: Tab = .upcoming
    var searchText = ""
    var mode = String(localized: "All")
    var eligibility = String(localized: "All")

    private(set) var children: [FacultyChild] = []
    var selectedChildID: String?
    private(set) var bundles: [Tab: PlacementBundle] = [:]
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: PlacementServiceProtocol

    init(kind: PlacementKind, role: UserRole, service: PlacementServiceProtocol) {
        self.kind = kind
        self.role = role
        self.service = service
    }

    var isParent: Bool { role == .parent }
    var alert: PlacementAlert? { bundles[.upcoming]?.alert }
    private var items: [PlacementItem] { bundles[tab]?.items ?? [] }

    func count(_ tab: Tab) -> Int { bundles[tab]?.items.count ?? 0 }

    var eligibilityOptions: [String] {
        let all = (bundles.values.flatMap { $0.items }).flatMap(\.chips)
        return [String(localized: "All")] + Array(Set(all)).sorted()
    }

    private func matches(_ item: PlacementItem) -> Bool {
        let all = String(localized: "All")
        let q = searchText.trimmed.lowercased()
        return (q.isEmpty || item.title.lowercased().contains(q) || (item.company ?? item.trainer ?? "").lowercased().contains(q))
            && (mode == all || item.mode.title == mode)
            && (eligibility == all || item.chips.contains(eligibility))
    }

    /// Sections in display order.
    var sections: [(title: String, items: [PlacementItem])] {
        let order = ["THIS WEEK", "LATER", "ENDED"]
        let visible = items.filter(matches)
        return order.compactMap { title in
            let group = visible.filter { $0.section == title }
            return group.isEmpty ? nil : (title, group)
        }
    }

    var isEmpty: Bool { sections.isEmpty }

    func load() async {
        guard bundles.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if isParent, children.isEmpty {
                children = try await service.children()
                if selectedChildID == nil { selectedChildID = children.first?.id }
            }
            bundles[.upcoming] = try await service.items(kind: kind, tab: "upcoming", childID: selectedChildID)
            bundles[.historical] = try await service.items(kind: kind, tab: "historical", childID: selectedChildID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Placement load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { bundles = [:]; children = []; Task { await load() } }
}

@Observable
final class PlacementDetailViewModel {
    let kind: PlacementKind
    let id: String
    let childID: String?
    private(set) var detail: PlacementDetail?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: PlacementServiceProtocol

    init(kind: PlacementKind, id: String, childID: String?, service: PlacementServiceProtocol) {
        self.kind = kind
        self.id = id
        self.childID = childID
        self.service = service
    }

    func load() async {
        guard detail == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await service.detail(kind: kind, id: id, childID: childID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reload() { detail = nil; Task { await load() } }
}
