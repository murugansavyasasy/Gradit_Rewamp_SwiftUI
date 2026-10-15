//
//  AuthComponents.swift
//  Gradit
//

import SwiftUI

/// Scrollable auth page: content at the top, CTA + "Powered by" pinned to the bottom
/// (pushed down by a spacer when there is room, scrolls when the keyboard is up).
struct AuthScaffold<Content: View, Bottom: View>: View {
    var spacing: CGFloat = 28
    @ViewBuilder var content: () -> Content
    @ViewBuilder var bottom: () -> Bottom

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: spacing) {
                        content()
                    }
                    Spacer(minLength: Theme.Spacing.lg)
                    VStack(spacing: Theme.Spacing.md) {
                        bottom()
                        PoweredByFooter()
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 72 pt icon tile + display title + body subtitle.
struct AuthHeader: View {
    let systemImage: String
    var tint: Color = Theme.Colors.blue600
    var tintBackground: Color = Theme.Colors.blue50
    let title: LocalizedStringKey
    let subtitle: Text

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 72, height: 72)
                .background(tintBackground, in: .rect(cornerRadius: 20))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.display)
                    .foregroundStyle(Theme.Colors.ink900)
                    .accessibilityAddTraits(.isHeader)
                subtitle
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.ink700)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Bold blue text button ("Forgot password?", "Back to sign in").
struct AuthLinkButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(AppFont.jakarta(14, .bold))
            .foregroundStyle(Theme.Colors.blue600)
            .frame(minHeight: 44)
            .contentShape(.rect)
    }
}
