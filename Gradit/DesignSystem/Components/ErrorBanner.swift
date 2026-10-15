//
//  ErrorBanner.swift
//  Gradit
//

import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(AppFont.jakarta(14, .semibold))
        .foregroundStyle(Theme.Colors.error)
        .padding(14)
        .background(Theme.Colors.errorBackground, in: .rect(cornerRadius: Theme.Radius.md))
        .accessibilityElement(children: .combine)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

#Preview {
    ErrorBanner(message: "That ID and password don’t match. Check and try again.").padding()
}
