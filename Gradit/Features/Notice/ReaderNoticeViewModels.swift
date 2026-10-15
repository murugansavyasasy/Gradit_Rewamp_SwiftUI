//
//  ReaderNoticeViewModels.swift
//  Gradit
//
//  View model for the student / parent notice board reader.
//

import Foundation
import Observation
internal import os

@Observable
final class ReaderNoticeListViewModel {
    enum Filter: Hashable, Identifiable {
        case all, unread, pinned, category(NoticeCategory)
        var id: String {
            switch self {
            case .all: "all"
            case .unread: "unread"
            case .pinned: "pinned"
            case .category(let c): "cat-\(c.rawValue)"
            }
        }
        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .unread: String(localized: "Unread")
            case .pinned: String(localized: "Pinned")
            case .category(let c): c.title
            }
        }
    }

    let role: UserRole
    var filter: Filter = .all
    var searchText = ""
    private(set) var items: [ReaderNotice] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: NoticeServiceProtocol

    init(role: UserRole, service: NoticeServiceProtocol) {
        self.role = role
        self.service = service
    }

    var unreadCount: Int { items.filter { $0.isUnread }.count }

    /// Chips shown in the filter bar: All, Unread, Pinned, then categories present.
    var filters: [Filter] {
        var result: [Filter] = [.all, .unread, .pinned]
        var seen: [NoticeCategory] = []
        for notice in items where !seen.contains(notice.category) {
            seen.append(notice.category)
            result.append(.category(notice.category))
        }
        return result
    }

    private func matches(_ notice: ReaderNotice) -> Bool {
        let q = searchText.trimmed.lowercased()
        let matchesSearch = q.isEmpty || notice.title.lowercased().contains(q) || notice.preview.lowercased().contains(q)
        switch filter {
        case .all: return matchesSearch
        case .unread: return matchesSearch && notice.isUnread
        case .pinned: return matchesSearch && notice.pinned
        case .category(let c): return matchesSearch && notice.category == c
        }
    }

    var visible: [ReaderNotice] { items.filter(matches) }

    /// Section → notices, in display order (PINNED, TODAY, EARLIER).
    var sections: [(title: String, notices: [ReaderNotice])] {
        let order = ["PINNED", "TODAY", "EARLIER"]
        return order.compactMap { title in
            let group = visible.filter { $0.section == title }
            return group.isEmpty ? nil : (title, group)
        }
    }

    func count(_ filter: Filter) -> Int? {
        switch filter {
        case .unread: unreadCount
        default: nil
        }
    }

    func load() async {
        guard items.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await service.readerNotices(studentID: role == .parent ? "s1" : nil)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Reader notices load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { items = []; Task { await load() } }

    func markRead(_ notice: ReaderNotice) {
        guard let index = items.firstIndex(where: { $0.id == notice.id }) else { return }
        items[index].isUnread = false
    }
}
