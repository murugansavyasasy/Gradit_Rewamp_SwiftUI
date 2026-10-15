//
//  NoticeViewModels.swift
//  Gradit
//
//  View models for the admin/faculty notice list, detail and create flows.
//

import Foundation
import Observation
internal import os

// MARK: - List

@Observable
final class NoticeListViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case all, published, scheduled, drafts, expired
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .published: String(localized: "Published")
            case .scheduled: String(localized: "Scheduled")
            case .drafts: String(localized: "Drafts")
            case .expired: String(localized: "Expired")
            }
        }
        func matches(_ status: NoticeStatus) -> Bool {
            switch self {
            case .all: true
            case .published: status == .published
            case .scheduled: status == .scheduled
            case .drafts: status == .draft
            case .expired: status == .expired
            }
        }
    }

    var tab: Tab = .all
    var searchText = ""
    var category = String(localized: "All")
    var audience = String(localized: "All")
    var newestFirst = true

    private(set) var items: [NoticeItem] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: NoticeServiceProtocol

    init(service: NoticeServiceProtocol) {
        self.service = service
    }

    var categoryOptions: [String] {
        [String(localized: "All")] + NoticeCategory.allCases.map(\.title)
    }

    func count(_ tab: Tab) -> Int { items.filter { tab.matches($0.status) }.count }

    var visible: [NoticeItem] {
        let all = String(localized: "All")
        let q = searchText.trimmed.lowercased()
        let filtered = items.filter { notice in
            tab.matches(notice.status)
                && (q.isEmpty || notice.title.lowercased().contains(q))
                && (category == all || notice.category.title == category)
        }
        return newestFirst ? filtered : filtered.reversed()
    }

    func load() async {
        guard items.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await service.notices()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Notices load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { items = []; Task { await load() } }
}

// MARK: - Detail

@Observable
final class NoticeDetailViewModel {
    let noticeID: String
    let isReader: Bool
    let role: UserRole
    private(set) var detail: NoticeDetail?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: NoticeServiceProtocol

    init(noticeID: String, isReader: Bool, role: UserRole, service: NoticeServiceProtocol) {
        self.noticeID = noticeID
        self.isReader = isReader
        self.role = role
        self.service = service
    }

    func load() async {
        guard detail == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            detail = isReader
                ? try await service.readerNotice(id: noticeID, studentID: role == .parent ? "s1" : nil)
                : try await service.notice(id: noticeID)
            if isReader { try? await service.markRead(id: noticeID, read: true) }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Notice detail load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { detail = nil; Task { await load() } }

    func markUnread() { Task { try? await service.markRead(id: noticeID, read: false) } }
}

// MARK: - Create

@Observable
final class CreateNoticeViewModel {
    var title = ""
    var message = ""
    var category: NoticeCategory = .general
    var highPriority = false
    var toStudents = true
    var toParents = true
    var toStaff = false
    var classLabel = "B.E. CSE · Sem 5"
    var section = "A & B"
    var attachments: [AssignmentAttachment] = []
    var pinned = true
    var expiryDate: Date?

    var showErrors = false
    private(set) var isWorking = false
    var errorMessage: String?

    let classOptions = ["B.E. CSE · Sem 5", "B.E. CSE · Sem 3", "B.E. CSE · Sem 7", "All classes"]
    let sectionOptions = ["A", "B", "A & B", "All sections"]

    private let service: NoticeServiceProtocol

    init(service: NoticeServiceProtocol) {
        self.service = service
    }

    var titleMissing: Bool { title.trimmed.isEmpty }
    var audienceMissing: Bool { !toStudents && !toParents && !toStaff }
    var expiryInvalid: Bool {
        guard let expiryDate else { return true }
        return expiryDate < .now
    }

    var problems: [String] {
        var items: [String] = []
        if titleMissing { items.append(String(localized: "Title is missing")) }
        if audienceMissing { items.append(String(localized: "No audience selected")) }
        if expiryInvalid { items.append(String(localized: "Expiry date is before the publish date")) }
        return items
    }

    var isValid: Bool { problems.isEmpty }

    var audienceSummary: String {
        var who: [String] = []
        if toStudents { who.append(String(localized: "Students")) }
        if toParents { who.append(String(localized: "Parents")) }
        if toStaff { who.append(String(localized: "Staff")) }
        let people = who.isEmpty ? String(localized: "No one") : who.joined(separator: ", ")
        return "\(classLabel) \(section) · \(people)"
    }

    var recipientsText: String {
        let base = (toStudents ? 100 : 0) + (toParents ? 98 : 0) + (toStaff ? 7 : 0)
        return String(localized: "\(base) recipients")
    }

    var expiryText: String {
        guard let expiryDate else { return String(localized: "Set expiry date") }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy"
        return formatter.string(from: expiryDate)
    }

    // MARK: Attachments

    /// Adds a file chosen from the system file picker (reads its name, size and kind).
    func addAttachment(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let name = url.lastPathComponent
        guard !attachments.contains(where: { $0.name == name }) else { return }

        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let kind = Self.kind(for: url.pathExtension.lowercased())
        let size = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
        attachments.append(AssignmentAttachment(id: url.absoluteString, name: name, kind: kind,
                                                detail: "\(Self.kindLabel(kind)) · \(size)"))
    }

    func removeAttachment(_ attachment: AssignmentAttachment) {
        attachments.removeAll { $0.id == attachment.id }
    }

    private static func kind(for ext: String) -> AttachmentKind {
        switch ext {
        case "pdf": .pdf
        case "jpg", "jpeg", "png", "heic", "gif", "webp", "tiff": .image
        case "m4a", "mp3", "wav", "aac", "caf": .voice
        default: .document
        }
    }

    private static func kindLabel(_ kind: AttachmentKind) -> String {
        switch kind {
        case .pdf: String(localized: "PDF")
        case .image: String(localized: "Image")
        case .voice: String(localized: "Voice note")
        case .document: String(localized: "Document")
        }
    }

    private func draft(scheduled: Bool) -> NoticeDraft {
        NoticeDraft(title: title.trimmed, message: message.trimmed, category: category, highPriority: highPriority,
                    toStudents: toStudents, toParents: toParents, toStaff: toStaff,
                    classLabel: classLabel, section: section, attachmentNames: attachments.map(\.name),
                    pinned: pinned, expiryText: expiryText, scheduled: scheduled)
    }

    func publish() async -> Bool {
        guard isValid else { showErrors = true; return false }
        isWorking = true
        defer { isWorking = false }
        do { try await service.publish(draft(scheduled: false)); return true }
        catch { errorMessage = error.localizedDescription; return false }
    }

    func saveDraft() async -> Bool {
        isWorking = true
        defer { isWorking = false }
        do { try await service.publish(draft(scheduled: true)); return true }
        catch { errorMessage = error.localizedDescription; return false }
    }
}
