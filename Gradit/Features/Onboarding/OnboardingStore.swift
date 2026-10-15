//
//  OnboardingStore.swift
//  Gradit
//
//  First-launch state, persisted in UserDefaults and read synchronously at
//  launch so RootView can pick the first screen without a flash.
//  Sign-in, sign-out and restarts never reset it.
//

import Foundation
import Observation

@Observable
final class OnboardingStore {
    enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedCountryCode = "selectedCountryCode"
    }

    private(set) var hasCompletedOnboarding: Bool
    private(set) var selectedCountryCode: String?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.selectedCountryCode = defaults.string(forKey: Keys.selectedCountryCode)
    }

    var selectedCountry: Country? {
        selectedCountryCode.flatMap(Country.withCode)
    }

    var needsCountry: Bool { selectedCountry == nil }

    func selectCountry(_ country: Country) {
        selectedCountryCode = country.code
        defaults.set(country.code, forKey: Keys.selectedCountryCode)
    }

    /// Called from both "Get started" and "Skip".
    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: Keys.hasCompletedOnboarding)
    }

    #if DEBUG
    /// Debug helper to see the first-launch flow again.
    func resetForTesting() {
        hasCompletedOnboarding = false
        selectedCountryCode = nil
        defaults.removeObject(forKey: Keys.hasCompletedOnboarding)
        defaults.removeObject(forKey: Keys.selectedCountryCode)
    }
    #endif
}

extension OnboardingStore {
    /// In-memory store for SwiftUI previews.
    static func preview(completed: Bool = true, countryCode: String? = "IN") -> OnboardingStore {
        let defaults = UserDefaults(suiteName: "preview.onboarding") ?? .standard
        defaults.removePersistentDomain(forName: "preview.onboarding")
        defaults.set(completed, forKey: Keys.hasCompletedOnboarding)
        if let countryCode { defaults.set(countryCode, forKey: Keys.selectedCountryCode) }
        return OnboardingStore(defaults: defaults)
    }
}
