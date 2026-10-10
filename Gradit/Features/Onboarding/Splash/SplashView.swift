//
//  SplashView.swift
//  Gradit
//
//  Design: 01 Common › Splash.
//  Branded launch screen: GradIt mark, tagline and feature chips over a short
//  loading beat, then `onFinish`. Shows on every cold start; the onboarding that
//  may follow is first-run only (see RootView + OnboardingStore).
//

import SwiftUI

struct SplashView: View {
    /// Called once the loading beat is over. The app decides what to show next.
    var onFinish: () -> Void = {}

    @State private var progress: CGFloat = 0

    private let features: [(icon: String, label: LocalizedStringKey)] = [
        ("mic.fill", "Voice"),
        ("location.fill", "Geo attendance"),
        ("doc.text.fill", "Resume"),
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Theme.Colors.white.ignoresSafeArea()

                rings
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                VStack(spacing: Theme.Spacing.lg) {
                    Spacer()

                    HStack(spacing: 12) {
                        AppLogoMark(size: 72)
                        Text("GradIt")
                            .font(AppFont.jakarta(40, .heavy))
                            .foregroundStyle(Theme.Colors.ink900)
                    }

                    Text("One app for your whole campus")
                        .font(AppFont.jakarta(18, .bold))
                        .foregroundStyle(Theme.Colors.ink700)
                        .multilineTextAlignment(.center)

                    chips

                    Spacer()
                }
                .padding(.horizontal, 24)

                VStack {
                    Spacer()
                    bottomWave
                }
                .ignoresSafeArea()
            }
        }
        .task {
            withAnimation(.easeInOut(duration: 1.6)) { progress = 1 }
            try? await Task.sleep(for: .seconds(1.8))
            onFinish()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("GradIt. One app for your whole campus. Loading.")
    }

    // MARK: - Pieces

    /// Faint concentric rings behind the mark, as in the design.
    private var rings: some View {
        ZStack {
            ForEach(1...3, id: \.self) { ring in
                Circle()
                    .stroke(Theme.Colors.blue100.opacity(0.45), lineWidth: 1)
                    .frame(width: CGFloat(ring) * 150, height: CGFloat(ring) * 150)
            }
        }
        .offset(y: -60)
        .accessibilityHidden(true)
    }

    private var chips: some View {
        HStack(spacing: 8) {
            ForEach(features, id: \.icon) { feature in
                HStack(spacing: 6) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.blue600)
                    Text(feature.label)
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(Theme.Colors.ink900)
                        .lineLimit(1)
                }
                .fixedSize()
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Theme.Colors.white, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.Colors.line))
                .shadow(color: Theme.Colors.ink900.opacity(0.05), radius: 6, y: 2)
            }
        }
    }

    private var bottomWave: some View {
        ZStack(alignment: .bottom) {
            WaveShape()
                .fill(Theme.Colors.blue600)

            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    ProgressView(value: progress)
                        .tint(Theme.Colors.white)
                        .frame(width: 180)
                    Text("Loading…")
                        .font(AppFont.jakarta(14, .bold))
                        .foregroundStyle(Theme.Colors.white)
                }
                poweredBy
            }
            .padding(.bottom, 44)
        }
        .frame(height: 280)
    }

    /// Light-on-dark "Powered by" for the blue wave (the shared footer is dark-on-light).
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
        .accessibilityHidden(true)
    }
}

/// Gentle wave that tops the blue footer region in the splash design.
private struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.28))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.20),
            control1: CGPoint(x: rect.width * 0.35, y: rect.height * -0.02),
            control2: CGPoint(x: rect.width * 0.60, y: rect.height * 0.42)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

#Preview {
    SplashView()
}
