//
//  OnboardingFlowView.swift
//  Gradit
//
//  First launch only: College welcome → App intro (4 pages) → Country selection → Login.
//  Shown by RootView while `OnboardingStore.hasCompletedOnboarding` is false.
//

import SwiftUI

enum OnboardingStep: Hashable {
    case intro
    case country
}

struct OnboardingFlowView: View {
    @Environment(OnboardingStore.self) private var store
    @State private var path: [OnboardingStep] = []

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingWelcomeView(onContinue: { path.append(.intro) })
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .intro:
                        OnboardingView(onFinish: finishIntro)
                    case .country:
                        CountrySelectionView(mode: .onboarding) { country in
                            store.selectCountry(country)
                            store.completeOnboarding()
                        }
                    }
                }
        }
        .tint(Theme.Colors.ink900)
    }

    /// Skip and Get started on the intro slides both land here. Pick a country if one
    /// isn't set yet, otherwise finish straight away (e.g. a country kept from an earlier launch).
    private func finishIntro() {
        if store.needsCountry {
            path.append(.country)
        } else {
            store.completeOnboarding()
        }
    }
}

#Preview("Fresh install") {
    OnboardingFlowView()
        .environment(OnboardingStore.preview(completed: false, countryCode: nil))
}
