//
//  AppLogoMark.swift
//  Gradit
//

import SwiftUI

/// Blue rounded tile with the graduation-cap mark.
struct AppLogoMark: View {
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: "graduationcap")
            .font(.system(size: size * 0.5, weight: .medium))
            .foregroundStyle(Theme.Colors.white)
            .frame(width: size, height: size)
            .background(Theme.Colors.blue600, in: .rect(cornerRadius: size * 0.2857))
            .accessibilityHidden(true)
    }
}

#Preview {
    AppLogoMark()
}
