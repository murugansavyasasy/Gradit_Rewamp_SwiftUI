//
//  OTPCodeField.swift
//  Gradit
//

import SwiftUI

/// Six digit boxes backed by one hidden text field, so SMS code AutoFill and paste work.
struct OTPCodeField: View {
    @Binding var code: String
    var length = 6
    var hasError = false

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.02)
                .accessibilityLabel("One-time code")
                .onChange(of: code) { _, newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(length))
                    if digits != newValue { code = digits }
                }

            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { index in
                    digitBox(at: index)
                }
            }
            .contentShape(.rect)
            .onTapGesture { isFocused = true }
            .accessibilityHidden(true)
        }
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            isFocused = true
        }
    }

    private func digit(at index: Int) -> String {
        guard index < code.count else { return "" }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }

    private func digitBox(at index: Int) -> some View {
        let isFilled = index < code.count
        let isActive = isFocused && (index == code.count || (code.count == length && index == length - 1))

        return Text(digit(at: index))
            .font(AppFont.jakarta(22, .bold))
            .foregroundStyle(Theme.Colors.ink900)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(background(isFilled: isFilled, isActive: isActive), in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        borderColor(isFilled: isFilled, isActive: isActive),
                        lineWidth: isActive ? 2 : (isFilled || hasError ? 1.5 : 1)
                    )
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive && !hasError ? Theme.Colors.blue100 : .clear)
                    .padding(-4)
            }
            .animation(.easeOut(duration: 0.12), value: isActive)
    }

    private func background(isFilled: Bool, isActive: Bool) -> Color {
        if hasError { return Theme.Colors.errorBackground }
        if isActive { return Theme.Colors.white }
        return isFilled ? Theme.Colors.blue50 : Theme.Colors.white
    }

    private func borderColor(isFilled: Bool, isActive: Bool) -> Color {
        if hasError { return Theme.Colors.error }
        return isActive || isFilled ? Theme.Colors.blue600 : Theme.Colors.border
    }
}

#Preview {
    @Previewable @State var code = "482"
    VStack(spacing: 24) {
        OTPCodeField(code: $code)
        OTPCodeField(code: .constant("000000"), hasError: true)
    }
    .padding(24)
}
