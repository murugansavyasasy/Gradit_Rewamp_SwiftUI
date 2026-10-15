//
//  ProfileTests.swift
//  GraditTests
//

import Foundation
import Testing
@testable import Gradit

@MainActor
struct ProfileTests {

    private func makeStore(role: UserRole = .parent) -> ProfileStore {
        ProfileStore(role: role, service: MockProfileService(latency: .zero))
    }

    @Test func loadsProfileForRole() async {
        let store = makeStore(role: .management)
        await store.loadProfile()
        #expect(store.profile?.fullName.isEmpty == false)
        #expect(store.profile?.summary?.contains("Staff ID") == true)
    }

    @Test func savingProfileUpdatesStore() async {
        let store = makeStore()
        await store.loadProfile()
        let saved = await store.saveProfile(fullName: "Rajesh K. Sharma", email: "rajesh@example.com", birthDate: nil)
        #expect(saved)
        #expect(store.profile?.fullName == "Rajesh K. Sharma")
        #expect(store.profile?.summary != nil)
    }

    @Test func savingRejectsInvalidEmail() async {
        let store = makeStore()
        await store.loadProfile()
        let saved = await store.saveProfile(fullName: "Rajesh", email: "not-an-email", birthDate: nil)
        #expect(!saved)
        #expect(store.errorMessage != nil)
    }

    @Test func savingRejectsEmptyName() async {
        let store = makeStore()
        let saved = await store.saveProfile(fullName: "   ", email: "", birthDate: nil)
        #expect(!saved)
    }

    @Test func birthDateRoundTrips() {
        var profile = UserProfile(fullName: "A", dateOfBirth: "1978-08-12")
        let date = profile.birthDate
        #expect(date != nil)
        profile.birthDate = date
        #expect(profile.dateOfBirth == "1978-08-12")
    }

    @Test func togglingPreferenceSaves() async {
        let store = makeStore()
        await store.loadPreferences()
        #expect(store.preferences?.bus == false)
        await store.setPreference(\.bus, to: true)
        #expect(store.preferences?.bus == true)
    }

    @Test func changePasswordRequiresValidInput() {
        let viewModel = ChangePasswordViewModel()
        viewModel.currentPassword = "oldpassword"
        viewModel.newPassword = "Aarav@Sem5"
        viewModel.confirmation = "Aarav@Sem"
        #expect(viewModel.showsMismatch)
        #expect(!viewModel.canSubmit)
        viewModel.confirmation = "Aarav@Sem5"
        #expect(viewModel.canSubmit)
    }

    @Test func changePasswordReportsWrongCurrentPassword() async {
        let store = makeStore()
        let viewModel = ChangePasswordViewModel()
        viewModel.currentPassword = "123"
        viewModel.newPassword = "Campus@2026"
        viewModel.confirmation = "Campus@2026"
        await viewModel.submit(using: store)
        #expect(viewModel.errorMessage == ProfileError.wrongCurrentPassword.localizedDescription)
        #expect(!viewModel.didSucceed)
    }

    @Test func profileTabTitleDependsOnRole() {
        #expect(DashboardTab.tabs(for: .parent).last == .me)
        #expect(DashboardTab.tabs(for: .management).last == .profile)
    }
}
