//
//  ProfileStore.swift
//  Gradit
//
//  Shared state for the Profile tab and the screens pushed from it.
//  Created per signed-in role by RoleTabShell and passed through the environment.
//

import Foundation
import Observation

@Observable
final class ProfileStore {
    let role: UserRole
    private(set) var profile: UserProfile?
    private(set) var preferences: NotificationPreferences?
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?

    private let service: ProfileServiceProtocol

    init(role: UserRole, service: ProfileServiceProtocol) {
        self.role = role
        self.service = service
    }

    // MARK: Profile

    func loadProfile() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await service.profile(role: role)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Validates and saves Edit profile. Returns true on success.
    func saveProfile(fullName: String, email: String, birthDate: Date?) async -> Bool {
        let name = fullName.trimmed
        let email = email.trimmed
        guard !name.isEmpty else { errorMessage = ProfileError.emptyName.localizedDescription; return false }
        guard email.isEmpty || email.isValidEmail else { errorMessage = ProfileError.invalidEmail.localizedDescription; return false }

        var draft = profile ?? UserProfile(fullName: name)
        draft.birthDate = birthDate

        isSaving = true
        defer { isSaving = false }
        do {
            let updated = try await service.updateProfile(
                fullName: name,
                email: email.isEmpty ? nil : email,
                dateOfBirth: draft.dateOfBirth
            )
            profile = merged(updated)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func uploadPhoto(jpegData: Data) async {
        isSaving = true
        defer { isSaving = false }
        do {
            profile = merged(try await service.uploadPhoto(jpegData: jpegData))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removePhoto() async {
        isSaving = true
        defer { isSaving = false }
        do {
            profile = merged(try await service.removePhoto())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Keeps the role-specific summary if an update response leaves it out.
    private func merged(_ updated: UserProfile) -> UserProfile {
        var result = updated
        if result.summary == nil { result.summary = profile?.summary }
        return result
    }

    // MARK: Notification settings

    func loadPreferences() async {
        do {
            preferences = try await service.notificationPreferences()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Optimistic: flips immediately, rolls back if saving fails.
    func setPreference(_ keyPath: WritableKeyPath<NotificationPreferences, Bool>, to value: Bool) async {
        guard var updated = preferences else { return }
        let previous = updated
        updated[keyPath: keyPath] = value
        preferences = updated
        do {
            preferences = try await service.updateNotificationPreferences(updated)
        } catch {
            preferences = previous
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Password

    func changePassword(current: String, new: String, signOutOtherDevices: Bool) async throws {
        try await service.changePassword(current: current, new: new, signOutOtherDevices: signOutOtherDevices)
    }
}
