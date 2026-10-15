//
//  OnboardingView.swift
//  Gradit
//
//  Design: 01 Common › Onboarding › App intro 1–4.
//  Swipe or tap Next; Skip (pages 1–3) and Get started (page 4) both finish onboarding.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var index = 0
    private let slides = OnboardingSlide.all

    private var isLast: Bool { index == slides.count - 1 }

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            let heroHeight = min(430, max(330, proxy.size.height * 0.52))

            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { offset, slide in
                        OnboardingSlidePage(
                            slide: slide,
                            index: offset,
                            count: slides.count,
                            heroHeight: heroHeight,
                            topInset: topInset
                        )
                        .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 4) {
                    Button(action: advance) {
                        HStack(spacing: 8) {
                            Text(isLast ? "Get started" : "Next")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .font(AppFont.jakarta(15, .bold))
                        .foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(isLast ? Theme.Colors.green600 : Theme.Colors.blue600, in: .rect(cornerRadius: Theme.Radius.button))
                        .contentShape(.rect)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityHint(isLast ? "Finishes the introduction and opens sign in" : "Shows the next page")

                    PoweredByFooter()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 6)
            }
            .overlay(alignment: .top) {
                header
            }
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: index)
    }

    private var header: some View {
        HStack(spacing: 10) {
            if index > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { index -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink900)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.white.opacity(0.8), in: .rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous")
            } else {
                HStack(spacing: 8) {
                    AppLogoMark(size: 32)
                    Text("GradIt")
                        .font(AppFont.jakarta(14, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                }
                .frame(minHeight: 44)
                .accessibilityElement(children: .combine)
            }

            Spacer()

            if !isLast {
                Button("Skip", action: onFinish)
                    .font(AppFont.jakarta(14, .bold))
                    .foregroundStyle(Theme.Colors.ink900)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Theme.Colors.white.opacity(0.8), in: .rect(cornerRadius: 12))
                    .buttonStyle(.plain)
                    .accessibilityHint("Skips the introduction and opens sign in")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private func advance() {
        if isLast {
            onFinish()
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { index += 1 }
        }
    }
}

/// One swipeable page: tinted hero with illustration, then progress, tag, title and body.
private struct OnboardingSlidePage: View {
    let slide: OnboardingSlide
    let index: Int
    let count: Int
    let heroHeight: CGFloat
    let topInset: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .top) {
                slide.illustration
                    .padding(.horizontal, 24)
                    .padding(.top, topInset + 66)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(slide.accessibilityLabel)
                    .accessibilityAddTraits(.isImage)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .frame(height: heroHeight + topInset, alignment: .top)
            .background {
                ZStack {
                    slide.soft
                    Circle()
                        .fill(slide.blob)
                        .frame(width: 360, height: 360)
                        .offset(x: 140, y: -120)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    Circle()
                        .fill(slide.blob)
                        .frame(width: 220, height: 220)
                        .offset(x: -90, y: 70)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        ForEach(0..<count, id: \.self) { step in
                            Capsule()
                                .fill(step == index ? Theme.Colors.blue600 : (step < index ? Theme.Colors.blueBorder : Theme.Colors.line))
                                .frame(height: 6)
                        }
                    }
                    .accessibilityHidden(true)
                    Text("\(index + 1) of \(count)")
                        .font(AppFont.jakarta(12, .bold))
                        .foregroundStyle(Theme.Colors.ink500)
                        .accessibilityLabel("Page \(index + 1) of \(count)")
                }

                Text(slide.tag)
                    .font(AppFont.jakarta(12, .heavy))
                    .foregroundStyle(slide.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(slide.soft, in: Capsule())

                Text(slide.title)
                    .font(AppFont.jakarta(26, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(slide.body)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.ink700)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    OnboardingView { }
}
