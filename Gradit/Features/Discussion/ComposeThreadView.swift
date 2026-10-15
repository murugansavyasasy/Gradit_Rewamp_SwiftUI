//
//  ComposeThreadView.swift
//  Gradit
//
//  Compose a new discussion thread. Presented as a sheet from the board; the
//  created thread is handed back through `onCreated` so the list updates instantly.
//

import SwiftUI

struct ComposeThreadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ComposeThreadViewModel
    private let onCreated: (DiscussionThread) -> Void

    init(service: DiscussionServiceProtocol, onCreated: @escaping (DiscussionThread) -> Void) {
        _viewModel = State(initialValue: ComposeThreadViewModel(service: service))
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    categoryPicker
                    AppTextField(
                        label: "Title",
                        text: $viewModel.title,
                        placeholder: "What's this about?",
                        capitalization: .sentences,
                        submitLabel: .next
                    )
                    bodyEditor

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppFont.jakarta(13, .semibold))
                            .foregroundStyle(Theme.Colors.error)
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.Colors.white.ignoresSafeArea())
            .navigationTitle("New discussion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(AppFont.jakarta(15))
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Post", isLoading: viewModel.isSaving, isEnabled: viewModel.canSubmit) {
                    Task {
                        if let thread = await viewModel.submit() {
                            onCreated(thread)
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(Theme.Colors.white)
            }
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Category")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.ink700)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(DiscussionCategory.allCases) { category in
                        let isOn = viewModel.category == category
                        Button(category.title) { viewModel.category = category }
                            .font(AppFont.jakarta(13, isOn ? .bold : .semibold))
                            .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                            .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isOn ? [.isSelected] : [])
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var bodyEditor: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Message")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.ink700)

            TextEditor(text: $viewModel.body)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.ink900)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150, alignment: .topLeading)
                .padding(10)
                .background(Theme.Colors.white, in: .rect(cornerRadius: Theme.Radius.input))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.input).strokeBorder(Theme.Colors.border))
                .overlay(alignment: .topLeading) {
                    if viewModel.body.isEmpty {
                        Text("Share details with the college community…")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.ink500)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}

#Preview {
    ComposeThreadView(service: MockDiscussionService()) { _ in }
}
