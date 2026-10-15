//
//  SelectionCard.swift
//  Gradit
//

import SwiftUI

enum SelectionIndicatorStyle {
    /// Thick blue ring (Forgot password › Send code via).
    case ring
    /// Filled blue circle with a check (Role selection, Language).
    case check
}

/// Tappable card with an icon tile, title, subtitle and radio indicator.
struct SelectionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    var indicator: SelectionIndicatorStyle = .ring
    /// Fixed icon colors. When nil the tile is blue when selected and grey otherwise.
    var iconForeground: Color?
    var iconBackground: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(iconForeground ?? (isSelected ? Theme.Colors.white : Theme.Colors.ink700))
                    .frame(width: 44, height: 44)
                    .background(
                        iconBackground ?? (isSelected ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted),
                        in: .rect(cornerRadius: 12)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFont.jakarta(16, .bold))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text(subtitle)
                        .font(Theme.Typography.small)
                        .foregroundStyle(isSelected ? Theme.Colors.ink700 : Theme.Colors.ink500)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                RadioIndicator(isSelected: isSelected, style: indicator)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Theme.Colors.blue50 : Theme.Colors.white, in: .rect(cornerRadius: Theme.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(isSelected ? Theme.Colors.blue600 : Theme.Colors.line, lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

struct RadioIndicator: View {
    let isSelected: Bool
    var style: SelectionIndicatorStyle = .ring

    var body: some View {
        ZStack {
            if isSelected {
                switch style {
                case .ring:
                    Circle().fill(Theme.Colors.white)
                    Circle().strokeBorder(Theme.Colors.blue600, lineWidth: 6)
                case .check:
                    Circle().fill(Theme.Colors.blue600)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Theme.Colors.white)
                }
            } else {
                Circle().strokeBorder(Theme.Colors.border, lineWidth: 2)
            }
        }
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 12) {
        SelectionCard(title: "SMS to registered mobile", subtitle: "+91 ••••• •3210", systemImage: "iphone", isSelected: true) {}
        SelectionCard(title: "Email", subtitle: "pa•••••@gmail.com", systemImage: "envelope", isSelected: false) {}
    }
    .padding()
}
