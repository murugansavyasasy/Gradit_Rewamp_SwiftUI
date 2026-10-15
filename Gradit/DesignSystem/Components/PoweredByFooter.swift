//
//  PoweredByFooter.swift
//  Gradit
//

import SwiftUI

/// "Powered by Savyasasy Software Solutions" footer used on every auth screen.
struct PoweredByFooter: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Powered by")
                .font(AppFont.jakarta(12, .semibold))
                .foregroundStyle(Theme.Colors.ink500)
            Image("SavyasasyLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 30)
                .accessibilityLabel("Savyasasy Software Solutions")
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PoweredByFooter()
}
