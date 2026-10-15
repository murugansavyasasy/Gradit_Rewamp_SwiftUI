//
//  CheckboxToggleStyle.swift
//  Gradit
//

import SwiftUI

/// Square checkbox ("Keep me signed in").
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(configuration.isOn ? Theme.Colors.blue600 : Theme.Colors.white)
                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.Colors.white)
                    } else {
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Theme.Colors.border, lineWidth: 1.5)
                    }
                }
                .frame(width: 20, height: 20)

                configuration.label
                    .font(AppFont.jakarta(14))
                    .foregroundStyle(Theme.Colors.ink700)
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}
