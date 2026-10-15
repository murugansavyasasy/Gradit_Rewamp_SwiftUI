//
//  LanguagePickerSheet.swift
//  Gradit
//

import SwiftUI

/// Common › Sign in › Login › Language popup. Also reused from Settings.
struct LanguagePickerSheet: View {
    @Binding var selection: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @State private var pending: AppLanguage

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    init(selection: Binding<AppLanguage>) {
        _selection = selection
        _pending = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Choose language")
                        .font(AppFont.jakarta(20, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                        .accessibilityAddTraits(.isHeader)
                    Text("You can change this later in Settings")
                        .font(AppFont.jakarta(13))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 44, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.line))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(AppLanguage.allCases) { language in
                        languageButton(language)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            PrimaryButton(title: "Apply · \(pending.englishName)") {
                selection = pending
                dismiss()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
        .presentationDetents([.height(520), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Radius.sheet)
    }

    private func languageButton(_ language: AppLanguage) -> some View {
        let isSelected = language == pending
        return Button {
            pending = language
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: language.nativeName)
                        .font(AppFont.jakarta(16, .bold))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text(verbatim: language.englishName)
                        .font(AppFont.jakarta(12, isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Theme.Colors.blue700 : Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                RadioIndicator(isSelected: isSelected, style: .check)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 64)
            .background(isSelected ? Theme.Colors.blue50 : Theme.Colors.white, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Theme.Colors.blue600 : Theme.Colors.line, lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    @Previewable @State var language = AppLanguage.english
    Color.clear.sheet(isPresented: .constant(true)) {
        LanguagePickerSheet(selection: $language)
    }
}
