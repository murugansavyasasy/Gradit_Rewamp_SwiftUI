//
//  OnboardingTests.swift
//  GraditTests
//

import Foundation
import Testing
@testable import Gradit

@MainActor
struct OnboardingTests {

    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test.onboarding.\(UUID().uuidString)")!
    }

    // MARK: First launch

    @Test func freshInstallNeedsCountryAndOnboarding() {
        let store = OnboardingStore(defaults: freshDefaults())
        #expect(store.hasCompletedOnboarding == false)
        #expect(store.needsCountry)
    }

    @Test func completingOnboardingPersistsAcrossLaunches() {
        let defaults = freshDefaults()
        OnboardingStore(defaults: defaults).completeOnboarding()

        let relaunched = OnboardingStore(defaults: defaults)
        #expect(relaunched.hasCompletedOnboarding)
    }

    @Test func selectedCountryPersistsAcrossLaunches() throws {
        let defaults = freshDefaults()
        let uae = try #require(Country.withCode("AE"))
        OnboardingStore(defaults: defaults).selectCountry(uae)

        let relaunched = OnboardingStore(defaults: defaults)
        #expect(relaunched.selectedCountry == uae)
        #expect(!relaunched.needsCountry)
    }

    @Test func signOutDoesNotResetOnboarding() async throws {
        let defaults = freshDefaults()
        let onboarding = OnboardingStore(defaults: defaults)
        onboarding.completeOnboarding()

        let session = AuthSession(
            service: MockAuthService(latency: .zero),
            apiClient: APIClient(baseURL: URL(string: "https://example.com")!),
            store: InMemorySecureStore(),
            biometrics: StubBiometrics(kind: .none),
            defaults: defaults
        )
        try await session.signIn(identifier: "9876543210", password: "password123", keepSignedIn: true)
        await session.signOut()

        #expect(OnboardingStore(defaults: defaults).hasCompletedOnboarding)
    }

    // MARK: Countries

    @Test func searchByPhoneCode() {
        #expect(Country.search("+971").map(\.code) == ["AE"])
        #expect(Country.search("971").map(\.code) == ["AE"])
    }

    @Test func searchByNameAndCode() {
        #expect(Country.search("sri").map(\.code) == ["LK"])
        #expect(Country.search("gb").map(\.code) == ["GB"])
        #expect(Country.search("zzz").isEmpty)
    }

    @Test func suggestionComesFromDeviceRegion() {
        #expect(Country.suggested(for: Locale(identifier: "en_IN"))?.code == "IN")
        #expect(Country.suggested(for: Locale(identifier: "fr_FR")) == nil)
    }

    @Test func continueRequiresASelection() {
        let viewModel = CountrySelectionViewModel(selected: nil, suggested: nil)
        #expect(!viewModel.canContinue)
        viewModel.select(Country.all[0])
        #expect(viewModel.canContinue)
    }

    @Test func suggestionIsPreselected() {
        let india = Country.withCode("IN")
        let viewModel = CountrySelectionViewModel(selected: nil, suggested: india)
        #expect(viewModel.selection == india)
        #expect(!viewModel.popular.contains { $0.code == "IN" })
    }

    @Test func groupsAreAlphabetical() {
        let viewModel = CountrySelectionViewModel(selected: nil, suggested: nil)
        #expect(viewModel.groups.first?.letter == "A")
        #expect(viewModel.groups.flatMap(\.countries).count == Country.all.count)
    }
}
