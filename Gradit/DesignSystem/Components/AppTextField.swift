//
//  AppTextField.swift
//  Gradit
//

import SwiftUI

/// Labelled 52 pt input with the design system's focus ring.
/// Set `isSecure` for a password field with a show/hide button.
struct AppTextField: View {
    let label: LocalizedStringKey
    @Binding var text: String
    var placeholder: LocalizedStringKey = ""
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var capitalization: TextInputAutocapitalization = .never
    var submitLabel: SubmitLabel = .next
    var errorMessage: String?
    var onSubmit: () -> Void = {}

    @FocusState private var isFocused: Bool
    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.ink700)

            HStack(spacing: 0) {
                field
                    .focused($isFocused)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.ink900)
                    .keyboardType(keyboard)
                    .textContentType(contentType)
                    .textInputAutocapitalization(capitalization)
                    .autocorrectionDisabled()
                    .submitLabel(submitLabel)
                    .onSubmit(onSubmit)
                    .padding(.leading, 16)
                    .padding(.trailing, isSecure ? 4 : 16)
                    .frame(height: 52)

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.ink500)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                    .padding(.trailing, 4)
                }
            }
            .background(Theme.Colors.white, in: .rect(cornerRadius: Theme.Radius.input))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .strokeBorder(borderColor, lineWidth: isFocused || errorMessage != nil ? 2 : 1)
            }
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.input + 4)
                    .fill(isFocused ? ringColor : .clear)
                    .padding(-4)
            }
            .contentShape(.rect)
            .onTapGesture { isFocused = true }

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.Typography.small)
                    .foregroundStyle(Theme.Colors.error)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    @ViewBuilder
    private var field: some View {
        if isSecure && !isRevealed {
            SecureField(placeholder, text: $text)
        } else {
            TextField(placeholder, text: $text)
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return Theme.Colors.error }
        return isFocused ? Theme.Colors.blue600 : Theme.Colors.border
    }

    private var ringColor: Color {
        errorMessage != nil ? Theme.Colors.errorBackground : Theme.Colors.blue100
    }
}

#Preview {
    @Previewable @State var id = ""
    @Previewable @State var password = "password123"
    VStack(spacing: 18) {
        AppTextField(label: "Mobile number, email or ID", text: $id, placeholder: "98765 43210")
        AppTextField(label: "Password", text: $password, isSecure: true)
        AppTextField(label: "With error", text: $id, errorMessage: "This field is required")
    }
    .padding(24)
}
