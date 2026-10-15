//
//  TimetableViewModels.swift
//  Gradit
//
//  View models for the admin timetable list and grid editor.
//

import Foundation
import Observation
internal import os

// MARK: - List

@Observable
final class AdminTimetableListViewModel {
    var searchText = ""
    var course = String(localized: "All")
    var yearSem = String(localized: "All")
    var section = String(localized: "All")

    private(set) var items: [TimetableSummary] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: TimetableServiceProtocol

    init(service: TimetableServiceProtocol) {
        self.service = service
    }

    var visible: [TimetableSummary] {
        let q = searchText.trimmed.lowercased()
        return items.filter { q.isEmpty || $0.classLabel.lowercased().contains(q) }
    }

    func load() async {
        guard items.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await service.timetables()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Timetables load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { items = []; Task { await load() } }
}

// MARK: - Grid editor

@Observable
final class TimetableEditorViewModel {
    let id: String?
    var selectedDay = "Wed"
    var showsDetail = false
    private(set) var editor: TimetableEditor?
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: TimetableServiceProtocol

    init(id: String?, service: TimetableServiceProtocol) {
        self.id = id
        self.service = service
    }

    func load() async {
        guard editor == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            editor = try await service.editor(id: id)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Timetable editor load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { editor = nil; Task { await load() } }

    /// Update a cell from the cell editor; clears any clash on it.
    func setCell(day: String, period: String, code: String, name: String, teacher: String, room: String) {
        guard let index = editor?.grid.cells.firstIndex(where: { $0.day == day && $0.period == period }) else { return }
        editor?.grid.cells[index].subjectCode = code
        editor?.grid.cells[index].subjectName = name
        editor?.grid.cells[index].teacher = teacher
        editor?.grid.cells[index].teacherInitials = String(teacher.split(separator: " ").compactMap(\.first).prefix(2))
        editor?.grid.cells[index].room = room
        editor?.grid.cells[index].state = .edited
        editor?.grid.cells[index].clashReason = nil
    }

    func clearCell(day: String, period: String) {
        guard let index = editor?.grid.cells.firstIndex(where: { $0.day == day && $0.period == period }) else { return }
        editor?.grid.cells[index].subjectCode = nil
        editor?.grid.cells[index].subjectName = nil
        editor?.grid.cells[index].teacher = nil
        editor?.grid.cells[index].room = nil
        editor?.grid.cells[index].state = .empty
    }

    /// Resolve a clash banner (optimistic).
    func resolve(_ clash: TimetableClash) {
        editor?.clashes.removeAll { $0.id == clash.id }
    }
}
