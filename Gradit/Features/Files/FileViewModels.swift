//
//  FileViewModels.swift
//  Gradit
//
//  View models for the admin/faculty files list, folders, upload and detail.
//

import Foundation
import Observation
internal import os

// MARK: - List

@Observable
final class FileListViewModel {
    let isReader: Bool
    let role: UserRole
    var kind: FileKind?               // nil == All
    var searchText = ""
    var folder = String(localized: "All")
    var category = String(localized: "All")
    var audience = String(localized: "All")
    var newestFirst = true
    var isGrid = false

    private(set) var items: [SharedFile] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: FileServiceProtocol

    init(isReader: Bool, role: UserRole, service: FileServiceProtocol) {
        self.isReader = isReader
        self.role = role
        self.service = service
    }

    func count(_ kind: FileKind?) -> Int {
        guard let kind else { return items.count }
        return items.filter { $0.kind == kind }.count
    }

    var categoryOptions: [String] { [String(localized: "All")] + FileCategory.allCases.map(\.title) }
    var folderOptions: [String] { [String(localized: "All")] + Array(Set(items.compactMap { _ in "" })).filter { !$0.isEmpty } }

    var visible: [SharedFile] {
        let all = String(localized: "All")
        let q = searchText.trimmed.lowercased()
        let filtered = items.filter { file in
            (kind == nil || file.kind == kind)
                && (q.isEmpty || file.name.lowercased().contains(q))
                && (category == all || file.category.title == category)
        }
        return newestFirst ? filtered : filtered.reversed()
    }

    func load() async {
        guard items.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            items = isReader ? try await service.readerFiles(studentID: role == .parent ? "s1" : nil) : try await service.files()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Files load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { items = []; Task { await load() } }
}

// MARK: - Folders

@Observable
final class FoldersViewModel {
    private(set) var folders: [FileFolder] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: FileServiceProtocol

    init(service: FileServiceProtocol) {
        self.service = service
    }

    var totalFiles: Int { folders.reduce(0) { $0 + $1.fileCount } }

    func load() async {
        guard folders.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            folders = try await service.folders()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(name: String) {
        folders.insert(FileFolder(id: UUID().uuidString, name: name, fileCount: 0), at: 0)
    }

    func rename(_ folder: FileFolder, to name: String) {
        guard let index = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        folders[index].name = name
    }

    func delete(_ folder: FileFolder) {
        folders.removeAll { $0.id == folder.id }
    }
}

// MARK: - Upload

@Observable
final class UploadFilesViewModel {
    struct LocalFile: Identifiable, Hashable {
        let id = UUID().uuidString
        let name: String
        let sizeText: String
        let kind: FileKind
        let typeLabel: String
        var progress: Double          // 0...1
        var failed: Bool
        var uploaded: Bool { progress >= 1 && !failed }
    }

    var files: [LocalFile] = []
    var title = ""
    var details = ""
    var category: FileCategory = .circular
    var toStudents = true
    var toParents = true
    var toStaff = false
    var classLabel = "B.E. CSE · Sem 5"
    var section = "Division A"
    var folder = "Exams"
    var expiryDate: Date?
    var downloadAllowed = true

    var showErrors = false
    private(set) var isWorking = false
    var errorMessage: String?

    let classOptions = ["B.E. CSE · Sem 5", "B.E. CSE · Sem 3", "B.Tech IT · Sem 3", "All classes"]
    let sectionOptions = ["Division A", "Division B", "Division A, B", "All divisions"]
    let folderOptions = ["Exams", "CSE · Sem 5", "Labs", "Events 2026", "Hostel", "Forms", "Syllabus", "Unsorted"]

    private let service: FileServiceProtocol

    init(service: FileServiceProtocol) {
        self.service = service
    }

    var readyCount: Int { files.filter(\.uploaded).count }
    var hasFailed: Bool { files.contains(where: \.failed) }

    var titleMissing: Bool { title.trimmed.isEmpty }
    var filesMissing: Bool { files.filter(\.uploaded).isEmpty }
    var audienceMissing: Bool { !toStudents && !toParents && !toStaff }

    var problems: [String] {
        var items: [String] = []
        if filesMissing { items.append(String(localized: "Add at least one file")) }
        if titleMissing { items.append(String(localized: "Title is missing")) }
        if audienceMissing { items.append(String(localized: "No audience selected")) }
        return items
    }
    var isValid: Bool { problems.isEmpty }

    var audienceSummary: String {
        var who: [String] = []
        if toStudents { who.append(String(localized: "Students")) }
        if toParents { who.append(String(localized: "Parents")) }
        if toStaff { who.append(String(localized: "Staff")) }
        return "\(classLabel) · \(section) · \(who.joined(separator: ", "))"
    }
    var recipientsText: String {
        let base = (toStudents ? 60 : 0) + (toParents ? 57 : 0) + (toStaff ? 7 : 0)
        return String(localized: "\(base) people")
    }
    var expiryText: String {
        guard let expiryDate else { return String(localized: "No expiry") }
        let f = DateFormatter(); f.dateFormat = "EEE d MMM yyyy"
        return f.string(from: expiryDate)
    }

    /// Adds a file chosen from the system file picker.
    func addFile(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let name = url.lastPathComponent
        guard !files.contains(where: { $0.name == name }) else { return }
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let (kind, label) = Self.kind(for: url.pathExtension.lowercased())
        files.append(LocalFile(name: name, sizeText: ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file),
                               kind: kind, typeLabel: label, progress: 1, failed: false))
    }

    func remove(_ file: LocalFile) { files.removeAll { $0.id == file.id } }
    func retry(_ file: LocalFile) {
        guard let index = files.firstIndex(where: { $0.id == file.id }) else { return }
        files[index].failed = false
        files[index].progress = 1
    }

    private static func kind(for ext: String) -> (FileKind, String) {
        switch ext {
        case "jpg", "jpeg", "png", "heic", "gif": (.image, "Image · \(ext.uppercased())")
        case "pdf": (.pdf, "PDF")
        case "mp4", "mov", "m4v": (.video, "Video · \(ext.uppercased())")
        default: (.document, ext.uppercased())
        }
    }

    private func draft() -> UploadDraft {
        UploadDraft(fileNames: files.map(\.name), title: title.trimmed, description: details.trimmed, category: category,
                    toStudents: toStudents, toParents: toParents, toStaff: toStaff, classLabel: classLabel,
                    section: section, folder: folder, expiryText: expiryText, downloadAllowed: downloadAllowed)
    }

    func publish() async -> Bool {
        guard isValid else { showErrors = true; return false }
        isWorking = true
        defer { isWorking = false }
        do { try await service.publish(draft()); return true }
        catch { errorMessage = error.localizedDescription; return false }
    }

    func saveDraft() async -> Bool {
        isWorking = true
        defer { isWorking = false }
        do { try await service.publish(draft()); return true }
        catch { errorMessage = error.localizedDescription; return false }
    }
}

// MARK: - Detail

@Observable
final class FileDetailViewModel {
    let fileID: String
    let isReader: Bool
    let role: UserRole
    private(set) var detail: FileDetail?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: FileServiceProtocol

    init(fileID: String, isReader: Bool, role: UserRole, service: FileServiceProtocol) {
        self.fileID = fileID
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
                ? try await service.readerFileDetail(id: fileID, studentID: role == .parent ? "s1" : nil)
                : try await service.fileDetail(id: fileID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reload() { detail = nil; Task { await load() } }
}
