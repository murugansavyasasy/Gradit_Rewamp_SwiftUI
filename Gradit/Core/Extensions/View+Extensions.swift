//
//  View+Extensions.swift
//  Gradit
//

import SwiftUI

extension View {
    /// Applies a modifier only when `condition` is true.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }

    /// Standard card styling used across the app.
    func cardStyle() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: .rect(cornerRadius: Theme.Radius.md))
    }
}
