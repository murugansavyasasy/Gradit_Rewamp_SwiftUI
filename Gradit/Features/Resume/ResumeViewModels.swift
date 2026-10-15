//
//  ResumeViewModels.swift
//  Gradit
//
//  View model for the student / parent Resume Builder.
//

import Foundation
import Observation
internal import os

@Observable
final class ResumeViewModel {
    let role: UserRole
    private(set) var children: [FacultyChild] = []
    var selectedChildID: String?

    /// The editable resume. Section editors bind directly into this.
    var resume: Resume = .empty()

    private(set) var isLoaded = false
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?
    var didSave = false

    /// The template a student can pick for the exported resume.
    let templates = ["Classic", "Modern", "Minimal"]

    private let service: ResumeServiceProtocol
    private var childTask: Task<Void, Never>?

    init(role: UserRole, service: ResumeServiceProtocol) {
        self.role = role
        self.service = service
    }

    var isParent: Bool { role == .parent }
    /// Parents view a child's resume read-only; students edit their own.
    var isEditable: Bool { role == .student }

    var selectedChildName: String? {
        children.first { $0.id == selectedChildID }?.name
    }

    func load() async {
        guard !isLoaded else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if isParent, children.isEmpty {
                children = try await service.children()
                if selectedChildID == nil { selectedChildID = children.first?.id }
            }
            resume = try await service.resume(childID: selectedChildID)
            isLoaded = true
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            AppLogger.app.error("Resume load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func reload() { isLoaded = false; children = []; Task { await load() } }

    func selectChild(_ id: String) {
        guard id != selectedChildID else { return }
        selectedChildID = id
        isLoaded = false
        childTask?.cancel()
        childTask = Task {
            isLoading = true
            defer { isLoading = false }
            do {
                resume = try await service.resume(childID: selectedChildID)
                isLoaded = true
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func save() async {
        guard isEditable else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await service.save(resume, childID: selectedChildID)
            didSave = true
        } catch {
            AppLogger.app.error("Resume save failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
