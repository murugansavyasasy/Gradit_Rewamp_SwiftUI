//
//  NotificationsViewModel.swift
//  Gradit
//

import Foundation
import Observation
internal import os

@Observable
final class NotificationsViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case all, unread
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .unread: String(localized: "Unread")
            }
        }
    }

    struct Section: Identifiable {
        let id: String
        let title: String
        let items: [AppNotification]
    }

    let role: UserRole
    var filter: Filter = .all
    private(set) var items: [AppNotification] = []
    private(set) var isLoaded = false
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: NotificationServiceProtocol
    private let calendar = Calendar.current

    init(role: UserRole, service: NotificationServiceProtocol) {
        self.role = role
        self.service = service
    }

    var unreadCount: Int { items.filter { !$0.isRead }.count }
    var hasUnread: Bool { unreadCount > 0 }

    private var filtered: [AppNotification] {
        filter == .unread ? items.filter { !$0.isRead } : items
    }

    /// Groups the (already date-sorted) notifications into Today / Yesterday / Earlier.
    var sections: [Section] {
        let now = Date()
        var today: [AppNotification] = []
        var yesterday: [AppNotification] = []
        var earlier: [AppNotification] = []
        for item in filtered.sorted(by: { $0.date > $1.date }) {
            if calendar.isDateInToday(item.date) { today.append(item) }
            else if calendar.isDateInYesterday(item.date) { yesterday.append(item) }
            else { earlier.append(item) }
        }
        _ = now
        var result: [Section] = []
        if !today.isEmpty { result.append(Section(id: "today", title: String(localized: "Today"), items: today)) }
        if !yesterday.isEmpty { result.append(Section(id: "yesterday", title: String(localized: "Yesterday"), items: yesterday)) }
        if !earlier.isEmpty { result.append(Section(id: "earlier", title: String(localized: "Earlier"), items: earlier)) }
        return result
    }

    func load() async {
        guard !isLoaded else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await service.notifications(role: role)
            isLoaded = true
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Notifications load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { isLoaded = false; Task { await load() } }

    func markRead(_ item: AppNotification) {
        guard let index = items.firstIndex(where: { $0.id == item.id }), !items[index].isRead else { return }
        items[index].isRead = true
    }

    func markAllRead() {
        guard hasUnread else { return }
        for index in items.indices { items[index].isRead = true }
        Task { try? await service.markAllRead() }
    }
}
