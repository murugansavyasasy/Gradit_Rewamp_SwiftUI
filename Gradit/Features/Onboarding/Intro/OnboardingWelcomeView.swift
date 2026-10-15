//
//  OnboardingWelcomeView.swift
//  Gradit
//
//  Design: 01 Common › Onboarding › College welcome (authscreen.pdf page 2).
//  Full-blue welcome naming the college; "Get started" moves on to the intro slides.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    /// Advances to the feature intro slides.
    var onContinue: () -> Void = {}

    var body: some View {
        ZStack {
            Theme.Colors.blue600.ignoresSafeArea()
            decoration

            VStack(spacing: 0) {
                Spacer()

                logoTile

                VStack(spacing: 10) {
                    Text(collegeName)
                        .font(AppFont.jakarta(30, .heavy))
                        .foregroundStyle(Theme.Colors.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if !city.isEmpty {
                        Text(city)
                            .font(AppFont.jakarta(20, .heavy))
                            .foregroundStyle(Theme.Colors.white)
                    }
                    Text("Campus app for students & parents")
                        .font(AppFont.jakarta(16))
                        .foregroundStyle(Theme.Colors.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 28)
                .accessibilityElement(children: .combine)

                Spacer()

                dots
                    .padding(.bottom, 24)

                Button(action: onContinue) {
                    Text("Get started")
                        .font(AppFont.jakarta(16, .bold))
                        .foregroundStyle(Theme.Colors.blue600)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: Theme.Radius.button))
                        .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())

                poweredBy
                    .padding(.top, 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Content

    /// Everything before the last comma in the configured college name.
    private var collegeName: String {
        let parts = AppConfig.collegeName.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.first ?? AppConfig.collegeName
    }

    /// The segment after the first comma (e.g. the city), if any.
    private var city: String {
        let parts = AppConfig.collegeName.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.count > 1 ? parts[1] : ""
    }

    // MARK: - Pieces

    private var logoTile: some View {
        Image(systemName: "graduationcap.fill")
            .font(.system(size: 46, weight: .semibold))
            .foregroundStyle(Theme.Colors.blue600)
            .frame(width: 112, height: 112)
            .background(Theme.Colors.white, in: .rect(cornerRadius: 28))
            .shadow(color: Color(hex: 0x101828, opacity: 0.18), radius: 18, y: 10)
            .accessibilityHidden(true)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Theme.Colors.white.opacity(index == 0 ? 1 : 0.4))
                    .frame(width: index == 0 ? 22 : 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }

    private var decoration: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .stroke(Theme.Colors.white.opacity(0.08), lineWidth: 1.5)
                    .frame(width: 420, height: 420)
                    .position(x: proxy.size.width * 0.85, y: proxy.size.height * 0.16)
                Circle()
                    .stroke(Theme.Colors.white.opacity(0.08), lineWidth: 1.5)
                    .frame(width: 320, height: 320)
                    .position(x: proxy.size.width * 0.08, y: proxy.size.height * 0.78)
            }
        }
        .accessibilityHidden(true)
    }

    /// Light-on-dark "Powered by" for the blue background.
    private var poweredBy: some View {
        HStack(spacing: 10) {
            Text("Powered by")
                .font(AppFont.jakarta(12, .semibold))
                .foregroundStyle(Theme.Colors.white.opacity(0.9))
            Image("SavyasasyLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 26)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.Colors.white, in: .rect(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .accessibilityHidden(true)
    }
}

#Preview {
    OnboardingWelcomeView()
}
