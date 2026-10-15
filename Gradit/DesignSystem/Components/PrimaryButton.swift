//
//  PrimaryButton.swift
//  Gradit
//

import SwiftUI

/// 52 pt tall button from the design system (Primary · Secondary · Tonal · Success).
struct PrimaryButton: View {
    enum Style { case primary, secondary, tonal, success }

    let title: LocalizedStringKey
    var style: Style = .primary
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(foreground) }
            }
            .font(Theme.Typography.button)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(background, in: .rect(cornerRadius: Theme.Radius.button))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .strokeBorder(Theme.Colors.blue600, lineWidth: 1.5)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isLoading || !isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(.easeOut(duration: 0.15), value: isLoading)
    }

    private var foreground: Color {
        switch style {
        case .primary, .success: Theme.Colors.white
        case .secondary: Theme.Colors.blue600
        case .tonal: Theme.Colors.blue700
        }
    }

    private var background: Color {
        switch style {
        case .primary: Theme.Colors.blue600
        case .secondary: Theme.Colors.white
        case .tonal: Theme.Colors.blue50
        case .success: Theme.Colors.green600
        }
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton(title: "Primary") {}
        PrimaryButton(title: "Secondary", style: .secondary) {}
        PrimaryButton(title: "Tonal", style: .tonal) {}
        PrimaryButton(title: "Success · Pay", style: .success) {}
        PrimaryButton(title: "Loading", isLoading: true) {}
        PrimaryButton(title: "Disabled", isEnabled: false) {}
    }
    .padding()
}
