//
//  ErrorStateView.swift
//  Gradit
//

import SwiftUI

struct ErrorStateView: View {
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retry {
                Button("Try Again", action: retry)
                    .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    ErrorStateView(message: "The network connection was lost.") {}
}
