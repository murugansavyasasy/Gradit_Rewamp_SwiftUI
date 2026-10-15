//
//  SemCreditView.swift
//  Gradit
//
//  Student / parent Sem Credit Points: summary, By category / By semester tabs
//  with expandable breakdowns. Design: semCreadits.pdf.
//

import SwiftUI

struct SemCreditView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: CreditViewModel?

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model {
                if model.isParent, !model.children.isEmpty { childSwitcher(model) }
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = CreditViewModel(role: role, service: dependencies.creditService) }
            await model?.load()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Sem Credit Points").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                if let s = model?.summary {
                    Text("\(s.studentName) · \(s.programLine)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func childSwitcher(_ model: CreditViewModel) -> some View {
        HStack(spacing: 10) {
            ForEach(model.children) { child in
                let on = model.selectedChildID == child.id
                Button { model.selectChild(child.id) } label: {
                    HStack(spacing: 10) {
                        InitialsAvatar(initials: DashboardGreeting.initials(child.name), size: 38,
                                       foreground: on ? Theme.Colors.white : Theme.Colors.blue700,
                                       background: on ? Theme.Colors.blue600 : Theme.Colors.blue100)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(child.name).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                            Text(child.classLabel).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10).dashboardCard(radius: 14, border: on ? Theme.Colors.blue600 : Theme.Colors.line, borderWidth: on ? 1.5 : 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    @ViewBuilder
    private func content(_ model: CreditViewModel) -> some View {
        if model.isLoading, model.bundle == nil {
            loadingSkeleton
        } else if let error = model.errorMessage, model.bundle == nil {
            stateCard(error: error) { model.reload() }
        } else if let summary = model.summary {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    summaryCard(summary)
                    tabBar(model)
                    controls(model)
                    if model.tab == .byCategory {
                        ForEach(model.visibleCategories) { categoryCard(model, block: $0) }
                    } else {
                        ForEach(model.bundle?.semesters ?? []) { semesterCard(model, block: $0) }
                    }
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    // MARK: - Summary

    private func summaryCard(_ s: CreditSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Credits obtained · \(s.regulation)").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.white.opacity(0.85))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(s.obtained)").font(AppFont.jakarta(34, .heavy)).foregroundStyle(Theme.Colors.white)
                        Text("/ \(s.total)").font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.white.opacity(0.85))
                    }
                }
                Spacer(minLength: 0)
                ring(percent: s.percent)
            }
            HStack(spacing: 10) {
                summaryBox("\(s.toBeObtained)", "To be obtained")
                summaryBox("\(s.semestersCompleted) of \(s.totalSemesters)", "Semesters completed")
                summaryBox("\(s.creditsThisSemester)", "Credits this semester")
            }
            if let note = s.pendingNote {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.amber800)
                    Text(note).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.amber800).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 12))
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.blue700, in: .rect(cornerRadius: 18))
    }

    private func ring(percent: Int) -> some View {
        ZStack {
            Circle().stroke(Theme.Colors.white.opacity(0.25), lineWidth: 8)
            Circle().trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(Theme.Colors.white, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
            Text("\(percent)%").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.white)
        }
        .frame(width: 72, height: 72)
    }

    private func summaryBox(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.white)
            Text(label).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.white.opacity(0.85)).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading).frame(minHeight: 64, alignment: .top)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Theme.Colors.white.opacity(0.15), in: .rect(cornerRadius: 12))
    }

    // MARK: - Tabs & controls

    private func tabBar(_ model: CreditViewModel) -> some View {
        HStack(spacing: 4) {
            ForEach(CreditViewModel.Tab.allCases) { tab in
                let on = model.tab == tab
                Button(tab.title) { model.tab = tab }
                    .font(AppFont.jakarta(14, on ? .bold : .semibold)).foregroundStyle(on ? Theme.Colors.ink900 : Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(on ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                    .shadow(color: on ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
                    .buttonStyle(.plain)
            }
        }
        .padding(4).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.line))
    }

    private func controls(_ model: CreditViewModel) -> some View {
        HStack {
            if model.tab == .byCategory {
                AssignmentDropdown(label: String(localized: "Category"), value: model.categoryFilter, options: model.categoryOptions) { model.categoryFilter = $0 }
            }
            Spacer(minLength: 0)
            Button(model.expandAll ? "Collapse all" : "Expand all") { model.expandAll.toggle() }
                .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.blue600).buttonStyle(.plain)
        }
    }

    // MARK: - Category card

    private func categoryCard(_ model: CreditViewModel, block: CreditCategoryBlock) -> some View {
        let key = "cat-\(block.code)"
        let open = model.isExpanded(key)
        return VStack(alignment: .leading, spacing: 12) {
            Button { model.toggle(key) } label: {
                HStack(alignment: .top, spacing: 12) {
                    codeChip(block.code, tone: .neutral)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(block.name).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
                        Text("\(block.percent)% complete").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(block.obtained)").font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        + Text(" / \(block.total)").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink500)
                        Text("credits").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            progressBar(block.progress)
            HStack {
                Text("\(block.obtained) obtained").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.green700)
                Spacer()
                Text("\(block.toBeObtained) to be obtained").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.amber800)
            }
            if open { breakdownTable(block.rows) }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func breakdownTable(_ rows: [CreditSemesterRow]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Semester").frame(maxWidth: .infinity, alignment: .leading)
                Text("Obtained").frame(width: 70, alignment: .trailing)
                Text("To be\nobtained").frame(width: 62, alignment: .trailing).multilineTextAlignment(.trailing)
                Text("Total").frame(width: 48, alignment: .trailing)
            }
            .font(AppFont.jakarta(11, .bold)).foregroundStyle(Theme.Colors.ink500)
            .padding(.vertical, 8).padding(.horizontal, 10)
            .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 8))
            ForEach(rows) { row in
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(row.label).font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink900)
                        if row.upcoming { Text("Upcoming").font(AppFont.jakarta(10)).foregroundStyle(Theme.Colors.ink500) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(row.obtained)").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.green700).frame(width: 70, alignment: .trailing)
                    Text("\(row.toBeObtained)").font(AppFont.jakarta(14, .heavy)).foregroundStyle(row.toBeObtained > 0 ? Theme.Colors.amber800 : Theme.Colors.ink300).frame(width: 62, alignment: .trailing)
                    Text("\(row.total)").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900).frame(width: 48, alignment: .trailing)
                }
                .padding(.vertical, 10).padding(.horizontal, 10)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
            }
        }
    }

    // MARK: - Semester card

    private func semesterCard(_ model: CreditViewModel, block: SemesterCreditBlock) -> some View {
        let key = "sem-\(block.semester)"
        let open = model.isExpanded(key)
        let (fg, bg): (Color, Color) = switch block.status {
        case .completed: (Theme.Colors.green700, Theme.Colors.green50)
        case .current: (Theme.Colors.white, Theme.Colors.blue600)
        case .upcoming: (Theme.Colors.ink500, Theme.Colors.surfaceMuted)
        }
        return VStack(alignment: .leading, spacing: 12) {
            Button { model.toggle(key) } label: {
                HStack(spacing: 12) {
                    Text("S\(block.semester)").font(AppFont.jakarta(13, .heavy)).foregroundStyle(fg)
                        .frame(width: 40, height: 40).background(bg, in: .rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(block.label).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text(block.statusText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(block.obtained)").font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        + Text(" / \(block.total)").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink500)
                        Text("credits").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            if open {
                progressBar(block.progress)
                HStack {
                    Text("\(block.obtained) obtained").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.green700)
                    Spacer()
                    Text("\(block.toBeObtained) to be obtained").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.amber800)
                }
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    // MARK: - Shared

    private func codeChip(_ code: String, tone: StatusBadge.Tone) -> some View {
        Text(code).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink700)
            .frame(width: 40, height: 40).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))
    }

    private func progressBar(_ value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.surfaceMuted)
                Capsule().fill(Theme.Colors.blue600).frame(width: max(0, geo.size.width * value))
            }
        }
        .frame(height: 6)
    }

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 18).fill(Theme.Colors.ink300.opacity(0.3)).frame(height: 180)
                ForEach(0..<2, id: \.self) { _ in RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 110) }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden).redacted(reason: .placeholder)
    }

    private func stateCard(error: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "wifi.exclamationmark", size: 64, radius: 20, foreground: Theme.Colors.destructive, background: Theme.Colors.errorBackground)
            Text("Couldn't load credit points").font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("Check your internet connection and try again.").font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            Button("Try again", action: retry).font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                .padding(.horizontal, 20).frame(height: 48).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12)).buttonStyle(PressableButtonStyle())
            PoweredByFooter().padding(.top, 4)
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16).frame(maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    NavigationStack { SemCreditView(role: .parent) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
