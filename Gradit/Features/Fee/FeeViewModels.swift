//
//  FeeViewModels.swift
//  Gradit
//
//  View model for the student / parent Fee Details.
//

import Foundation
import Observation
internal import os

@Observable
final class FeeDetailsViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case due, structure, payments
        var id: String { rawValue }
        var title: String {
            switch self {
            case .due: String(localized: "Due")
            case .structure: String(localized: "Fee structure")
            case .payments: String(localized: "Payments")
            }
        }
    }

    let role: UserRole
    var tab: Tab = .due
    private(set) var children: [FacultyChild] = []
    var selectedChildID: String?
    private(set) var data: FeeDetails?
    var selectedDueIDs: Set<String> = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: FeeServiceProtocol
    private var childTask: Task<Void, Never>?

    init(role: UserRole, service: FeeServiceProtocol) {
        self.role = role
        self.service = service
    }

    var isParent: Bool { role == .parent }

    var payableTotal: Int {
        (data?.dueItems ?? []).filter { $0.selectable && selectedDueIDs.contains($0.id) }.reduce(0) { $0 + $1.amount }
    }
    var canPay: Bool { payableTotal > 0 }

    func isSelected(_ item: FeeDueItem) -> Bool { selectedDueIDs.contains(item.id) }

    func toggle(_ item: FeeDueItem) {
        guard item.selectable else { return }
        if selectedDueIDs.contains(item.id) { selectedDueIDs.remove(item.id) } else { selectedDueIDs.insert(item.id) }
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
            let details = try await service.feeDetails(childID: selectedChildID)
            data = details
            selectDefaults(details)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Fee details load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { data = nil; children = []; Task { await load() } }

    func selectChild(_ id: String) {
        guard id != selectedChildID else { return }
        selectedChildID = id
        data = nil
        tab = .due
        childTask?.cancel()
        childTask = Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let details = try await service.feeDetails(childID: selectedChildID)
                data = details
                selectDefaults(details)
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func selectDefaults(_ details: FeeDetails) {
        selectedDueIDs = Set(details.dueItems.filter(\.selectable).map(\.id))
    }
}
