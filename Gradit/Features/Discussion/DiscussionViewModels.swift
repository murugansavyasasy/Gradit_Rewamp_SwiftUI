//
//  DiscussionViewModels.swift
//  Gradit
//

import Foundation
import Observation
internal import os

/// Discussion Board list: loads threads once, filters by category client-side.
@Observable
final class DiscussionBoardViewModel {
    private(set) var threads: [DiscussionThread] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var selectedCategory: DiscussionCategory?   // nil == All

    private let service: DiscussionServiceProtocol

    init(service: DiscussionServiceProtocol) {
        self.service = service
    }

    /// Pinned threads first, then newest, filtered by the selected category.
    var visibleThreads: [DiscussionThread] {
        threads
            .filter { selectedCategory == nil || $0.category == selectedCategory }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            threads = try await service.threads()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Discussion threads load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    /// Insert a thread created from the compose sheet without a full reload.
    func insert(_ thread: DiscussionThread) {
        threads.insert(thread, at: 0)
    }

    /// Optimistic like toggle; rolls back on failure.
    func toggleLike(_ thread: DiscussionThread) async {
        guard let index = threads.firstIndex(where: { $0.id == thread.id }) else { return }
        let liked = !threads[index].isLiked
        threads[index].isLiked = liked
        threads[index].likeCount += liked ? 1 : -1

        do {
            try await service.setLiked(threadID: thread.id, liked: liked)
        } catch {
            threads[index].isLiked = !liked
            threads[index].likeCount += liked ? -1 : 1
            AppLogger.app.error("Discussion like failed: \(error.localizedDescription)")
        }
    }
}

/// A single thread with its replies and a reply composer.
@Observable
final class DiscussionThreadViewModel {
    private(set) var thread: DiscussionThread
    private(set) var replies: [DiscussionReply] = []
    private(set) var isLoading = false
    var errorMessage: String?

    var draft = ""
    private(set) var isSending = false
    var sendErrorMessage: String?

    private let service: DiscussionServiceProtocol

    init(thread: DiscussionThread, service: DiscussionServiceProtocol) {
        self.thread = thread
        self.service = service
    }

    var canSend: Bool { !draft.trimmed.isEmpty && !isSending }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let detail = try await service.thread(id: thread.id)
            thread = detail.thread
            replies = detail.replies
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Discussion thread load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func send() async {
        let body = draft.trimmed
        guard !body.isEmpty, !isSending else { return }
        isSending = true
        defer { isSending = false }

        do {
            let reply = try await service.addReply(threadID: thread.id, body: body)
            replies.append(reply)
            thread.replyCount += 1
            draft = ""
            sendErrorMessage = nil
        } catch {
            sendErrorMessage = error.localizedDescription
        }
    }
}

/// Compose a new thread.
@Observable
final class ComposeThreadViewModel {
    var title = ""
    var body = ""
    var category: DiscussionCategory = .general
    private(set) var isSaving = false
    var errorMessage: String?

    private let service: DiscussionServiceProtocol

    init(service: DiscussionServiceProtocol) {
        self.service = service
    }

    var canSubmit: Bool { !title.trimmed.isEmpty && !body.trimmed.isEmpty && !isSaving }

    /// Returns the created thread on success, or nil on failure.
    func submit() async -> DiscussionThread? {
        guard canSubmit else { return nil }
        isSaving = true
        defer { isSaving = false }

        do {
            let thread = try await service.createThread(title: title.trimmed, body: body.trimmed, category: category)
            errorMessage = nil
            return thread
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
