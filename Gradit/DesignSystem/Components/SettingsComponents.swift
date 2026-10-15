//
//  SettingsComponents.swift
//  Gradit
//
//  Rows, cards, switches and dialogs shared by Profile and its sub-screens
//  (design: 01 Common › Profile and Settings).
//

import SwiftUI

// MARK: - Card with divided rows

/// White card, 18 pt radius, #EAECF0 border, rows separated by #EEF1F5 hairlines.
struct SettingsCard<Content: View>: View {
    var radius: CGFloat = 18
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { subviews in
                ForEach(Array(subviews.enumerated()), id: \.offset) { index, subview in
                    subview
                    if index < subviews.count - 1 {
                        Rectangle()
                            .fill(Theme.Colors.divider)
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .background(Theme.Colors.white, in: .rect(cornerRadius: radius))
        .overlay {
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(Theme.Colors.cardBorder)
        }
    }
}

/// 32 pt tinted icon + label + chevron. `isDestructive` gives the red Log out style.
struct SettingsRow: View {
    let title: String
    let systemImage: String
    var value: String?
    var isDestructive = false
    var showsChevron = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isDestructive ? Theme.Colors.destructive : Theme.Colors.blue600)
                    .frame(width: 32, height: 32)
                    .background(isDestructive ? Theme.Colors.errorBackground : Theme.Colors.blue50, in: .rect(cornerRadius: 10))
                    .accessibilityHidden(true)
                Text(title)
                    .font(AppFont.jakarta(15, isDestructive ? .semibold : .medium))
                    .foregroundStyle(isDestructive ? Theme.Colors.destructive : Theme.Colors.ink900)
                Spacer(minLength: 8)
                if let value {
                    Text(value)
                        .font(AppFont.jakarta(14))
                        .foregroundStyle(Theme.Colors.ink500)
                        .lineLimit(1)
                }
                if showsChevron && !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.chevron)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 50)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// Label + hint + green switch (Notification settings).
struct SettingsToggleRow: View {
    let title: String
    var hint: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.jakarta(15, .semibold))
                    .foregroundStyle(Theme.Colors.ink900)
                if let hint {
                    Text(hint)
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
            }
        }
        .tint(Theme.Colors.green600)
        .padding(.vertical, 8)
        .frame(minHeight: 50)
    }
}

// MARK: - Avatar

/// Circular photo or initials (Profile header 64 pt, Edit profile 96 pt).
struct ProfileAvatar: View {
    let name: String
    var photoURL: URL?
    var size: CGFloat = 64
    var background: Color = Theme.Colors.blue50

    var body: some View {
        ZStack {
            Circle().fill(background)
            Text(DashboardGreeting.initials(name))
                .font(AppFont.jakarta(size * 0.33, .heavy))
                .foregroundStyle(Theme.Colors.blue600)
            if let photoURL {
                AsyncImage(url: photoURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.clear
                }
                .clipShape(Circle())
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Centered confirmation dialog

/// Design's centred white card over a dimmed screen (Log out? / Clear cache?).
struct ConfirmationCard: View {
    let systemImage: String
    var iconForeground: Color = Theme.Colors.blue600
    var iconBackground: Color = Theme.Colors.blue50
    let title: String
    let message: String
    let confirmTitle: String
    var confirmColor: Color = Theme.Colors.blue600
    var isWorking = false
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color(hex: 0x101828, opacity: 0.48)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(iconForeground)
                    .frame(width: 56, height: 56)
                    .background(iconBackground, in: Circle())
                    .accessibilityHidden(true)
                Text(title)
                    .font(AppFont.jakarta(20, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                    .padding(.top, 4)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(AppFont.jakarta(14))
                    .foregroundStyle(Theme.Colors.ink700)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)

                Button(action: onConfirm) {
                    ZStack {
                        Text(confirmTitle).opacity(isWorking ? 0 : 1)
                        if isWorking { ProgressView().tint(Theme.Colors.white) }
                    }
                    .font(AppFont.jakarta(16, .bold))
                    .foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(confirmColor, in: .rect(cornerRadius: Theme.Radius.button))
                    .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(isWorking)

                Button("Cancel", action: onCancel)
                    .font(AppFont.jakarta(15, .bold))
                    .foregroundStyle(Theme.Colors.blue600)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .contentShape(.rect)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
            .background(Theme.Colors.white, in: .rect(cornerRadius: 22))
            .shadow(color: Color(hex: 0x101828, opacity: 0.24), radius: 24, y: 24)
            .padding(.horizontal, 24)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity)
    }
}

// MARK: - Password strength

/// Four-bar meter with a label, shared by Create password and Change password.
struct PasswordStrengthMeter: View {
    let strength: PasswordStrength

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { index in
                    Capsule()
                        .fill(index <= strength.rawValue ? barColor : Theme.Colors.line)
                        .frame(height: 6)
                }
            }
            .padding(.top, 4)
            .accessibilityHidden(true)

            Text(label)
                .font(AppFont.jakarta(13, .semibold))
                .foregroundStyle(textColor)
        }
    }

    private var barColor: Color {
        switch strength {
        case .empty, .weak: Theme.Colors.error
        case .fair: Theme.Colors.warning
        case .strong, .veryStrong: Theme.Colors.green600
        }
    }

    private var textColor: Color {
        switch strength {
        case .empty, .weak: Theme.Colors.red700
        case .fair: Theme.Colors.amber800
        case .strong, .veryStrong: Theme.Colors.green700
        }
    }

    private var label: String {
        switch strength {
        case .empty, .weak: String(localized: "Weak — add letters, numbers and a symbol")
        case .fair: String(localized: "Fair — use 12 or more characters to strengthen it")
        case .strong: String(localized: "Strong password")
        case .veryStrong: String(localized: "Very strong password")
        }
    }
}
