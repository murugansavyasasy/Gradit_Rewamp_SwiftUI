//
//  CountrySelectionView.swift
//  Gradit
//
//  Design: 01 Common › Country selection (+ Search results, No match, Location off states).
//

import SwiftUI

struct CountrySelectionView: View {
    enum Mode {
        /// First launch: step label, Continue button.
        case onboarding
        /// Settings › Country: system back button, Save.
        case settings
    }

    let mode: Mode
    let onContinue: (Country) -> Void

    @State private var viewModel: CountrySelectionViewModel
    @FocusState private var isSearchFocused: Bool

    init(mode: Mode, selected: Country? = nil, onContinue: @escaping (Country) -> Void) {
        self.mode = mode
        self.onContinue = onContinue
        _viewModel = State(initialValue: CountrySelectionViewModel(selected: selected))
    }

    var body: some View {
        VStack(spacing: 0) {
            if mode == .onboarding {
                HStack {
                    Spacer()
                    Text("Step 1 of 2 · Region")
                        .font(AppFont.jakarta(12, .bold))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .padding(.vertical, 10)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if !viewModel.isSearching {
                        if let suggested = viewModel.suggested {
                            SuggestedCountryCard(country: suggested, isSelected: viewModel.selection == suggested) {
                                viewModel.select(suggested)
                            }
                        } else {
                            NoSuggestionNotice()
                        }
                    }

                    searchField

                    if !viewModel.isSearching {
                        popularSection
                    }

                    listSection

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.top, 2)
                        Text("Your country is saved on this device. You can change it later in Settings.")
                    }
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)

            bottomBar
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .animation(.easeOut(duration: 0.2), value: viewModel.isSearching)
        .animation(.easeOut(duration: 0.15), value: viewModel.selection)
        .sensoryFeedback(.selection, trigger: viewModel.selection)
        .toolbar(mode == .onboarding ? .hidden : .visible, for: .navigationBar)
        .navigationTitle(mode == .settings ? String(localized: "Country") : "")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Where is your college?")
                .font(Theme.Typography.display)
                .foregroundStyle(Theme.Colors.ink900)
                .accessibilityAddTraits(.isHeader)
            Text("We use your country to show the right college list, phone code and currency.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.ink700)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.suggested == nil ? "Choose your country" : "Or choose another country")
                .font(AppFont.jakarta(14, .heavy))
                .foregroundStyle(Theme.Colors.ink900)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink500)
                TextField("Search country or code, e.g. +971", text: $viewModel.query)
                    .font(AppFont.jakarta(15))
                    .foregroundStyle(Theme.Colors.ink900)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                if viewModel.isSearching {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.Colors.ink300)
                            .frame(width: 32, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, viewModel.isSearching ? 6 : 14)
            .frame(height: 48)
            .background(Theme.Colors.white, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSearchFocused ? Theme.Colors.blue600 : Theme.Colors.border, lineWidth: isSearchFocused ? 2 : 1)
            }
        }
    }

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("POPULAR WITH OUR COLLEGES")
                .font(AppFont.jakarta(12, .heavy))
                .tracking(0.7)
                .foregroundStyle(Theme.Colors.ink500)
                .accessibilityAddTraits(.isHeader)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.popular) { country in
                    CountryChip(country: country, isSelected: viewModel.selection == country) {
                        viewModel.select(country)
                    }
                }
            }
        }
    }

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.listTitle)
                    .font(AppFont.jakarta(12, .heavy))
                    .tracking(0.7)
                    .foregroundStyle(Theme.Colors.ink500)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(viewModel.countText)
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
            }

            if viewModel.results.isEmpty {
                NoMatchView(query: viewModel.query, onClear: viewModel.clearSearch)
            } else {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.groups) { group in
                        Text(group.letter)
                            .font(AppFont.jakarta(13, .heavy))
                            .foregroundStyle(Theme.Colors.blue600)
                            .padding(.horizontal, 4)
                            .padding(.top, 6)
                            .accessibilityHidden(true)
                        ForEach(group.countries) { country in
                            CountryRow(country: country, isSelected: viewModel.selection == country) {
                                viewModel.select(country)
                            }
                        }
                    }
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if let selection = viewModel.selection {
                HStack(spacing: 10) {
                    CodeTile(code: selection.code, width: 36, height: 26, radius: 6, fontSize: 12, isSelected: true)
                    Text("\(Text(selection.name).bold().foregroundStyle(Theme.Colors.ink900)) · \(selection.summary)")
                        .font(AppFont.jakarta(13))
                        .foregroundStyle(Theme.Colors.ink700)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            } else {
                Text("Select a country to continue")
                    .font(AppFont.jakarta(13, .semibold))
                    .foregroundStyle(Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                if let selection = viewModel.selection { onContinue(selection) }
            } label: {
                HStack(spacing: 8) {
                    Text(mode == .settings ? "Save" : "Continue")
                    if mode == .onboarding {
                        Image(systemName: "arrow.right").font(.system(size: 15, weight: .semibold))
                    }
                }
                .font(AppFont.jakarta(15, .bold))
                .foregroundStyle(Theme.Colors.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Theme.Colors.blue600, in: .rect(cornerRadius: Theme.Radius.button))
                .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!viewModel.canContinue)
            .opacity(viewModel.canContinue ? 1 : 0.5)

            if mode == .onboarding {
                PoweredByFooter()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(Theme.Colors.white)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.Colors.line).frame(height: 1)
        }
    }
}

// MARK: - Pieces

/// Country code badge used instead of a flag image, as in the design.
private struct CodeTile: View {
    let code: String
    var width: CGFloat = 44
    var height: CGFloat = 32
    var radius: CGFloat = 8
    var fontSize: CGFloat = 13
    let isSelected: Bool

    var body: some View {
        Text(code)
            .font(AppFont.jakarta(fontSize, .heavy))
            .tracking(0.5)
            .foregroundStyle(isSelected ? Theme.Colors.white : Theme.Colors.ink700)
            .frame(width: width, height: height)
            .background(isSelected ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted, in: .rect(cornerRadius: radius))
            .accessibilityHidden(true)
    }
}

private struct CheckRadio: View {
    let isSelected: Bool
    var size: CGFloat = 24
    var offColor: Color = Theme.Colors.border

    var body: some View {
        ZStack {
            if isSelected {
                Circle().fill(Theme.Colors.blue600)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(Theme.Colors.white)
            } else {
                Circle().strokeBorder(offColor, lineWidth: 2)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct SuggestedCountryCard: View {
    let country: Country
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Label("SUGGESTED FOR YOUR REGION", systemImage: "location")
                    .font(AppFont.jakarta(12, .heavy))
                    .tracking(0.5)
                    .foregroundStyle(Theme.Colors.blue700)
                    .labelStyle(CompactLabelStyle())

                HStack(spacing: 14) {
                    Text(country.code)
                        .font(AppFont.jakarta(16, .heavy))
                        .tracking(0.6)
                        .foregroundStyle(Theme.Colors.white)
                        .frame(width: 56, height: 40)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(country.name)
                            .font(AppFont.jakarta(20, .heavy))
                            .foregroundStyle(Theme.Colors.ink900)
                        Text(country.summary)
                            .font(AppFont.jakarta(13))
                            .foregroundStyle(Theme.Colors.ink700)
                    }
                    Spacer(minLength: 0)
                    CheckRadio(isSelected: isSelected, size: 28, offColor: Theme.Colors.blueBorder)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.blue50, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isSelected ? Theme.Colors.blue600 : Theme.Colors.blue100, lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(country.name), suggested for your region. Phone code \(country.dialCode), currency \(country.currency)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

private struct NoSuggestionNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconTile(systemImage: "location.slash", foreground: Theme.Colors.ink700, background: Theme.Colors.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Choose your country")
                    .font(AppFont.jakarta(14, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                Text("We couldn’t suggest one from this device. Pick it from the list — you can change it later in Settings.")
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink700)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.Colors.border, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CountryChip: View {
    let country: Country
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(country.code)
                    .font(AppFont.jakarta(12, .heavy))
                    .foregroundStyle(isSelected ? Theme.Colors.white : Theme.Colors.ink700)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted, in: Circle())
                Text(country.shortName)
                    .font(AppFont.jakarta(14, .bold))
                    .foregroundStyle(Theme.Colors.ink900)
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .frame(minHeight: 44)
            .background(isSelected ? Theme.Colors.blue50 : Theme.Colors.white, in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? Theme.Colors.blue600 : Theme.Colors.line, lineWidth: isSelected ? 2 : 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(country.name)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct CountryRow: View {
    let country: Country
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                CodeTile(code: country.code, isSelected: isSelected)
                VStack(alignment: .leading, spacing: 1) {
                    Text(country.name)
                        .font(AppFont.jakarta(15, isSelected ? .heavy : .semibold))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text(country.summary)
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                CheckRadio(isSelected: isSelected)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 60)
            .background(isSelected ? Theme.Colors.blue50 : Theme.Colors.white, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Theme.Colors.blue600 : Theme.Colors.line, lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(country.name), phone code \(country.dialCode), currency \(country.currency)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

private struct NoMatchView: View {
    let query: String
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Theme.Colors.ink500)
                .frame(width: 52, height: 52)
                .background(Theme.Colors.white, in: Circle())
            Text("No country matches “\(query.trimmingCharacters(in: .whitespaces))”")
                .font(AppFont.jakarta(15, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
            Text("Check the spelling, or search by phone code such as +91. If your country isn’t listed, your college doesn’t use GradIt there yet.")
                .font(AppFont.jakarta(13))
                .foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center)
            Button("Clear search", action: onClear)
                .font(AppFont.jakarta(14, .bold))
                .foregroundStyle(Theme.Colors.blue700)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .dashboardCard(radius: 12, border: Theme.Colors.border)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 16))
    }
}

private struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon
            configuration.title
        }
    }
}

/// Wrapping row layout for the "popular" chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview("Onboarding") {
    CountrySelectionView(mode: .onboarding) { _ in }
}

#Preview("Settings") {
    NavigationStack {
        CountrySelectionView(mode: .settings, selected: Country.withCode("AE")) { _ in }
    }
}
