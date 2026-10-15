//
//  PlacementListView.swift
//  Gradit
//
//  Student / parent Placement Events & Training list: alert, Upcoming/Historical
//  tabs, filters, grouped cards. Design: placementModule.pdf, placementTaining.pdf.
//

import SwiftUI

struct PlacementListView: View {
    let kind: PlacementKind
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: PlacementListViewModel?

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
            if model == nil { model = PlacementListViewModel(kind: kind, role: role, service: dependencies.placementService) }
            await model?.load()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.title).font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("From the placement cell").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func childSwitcher(_ model: PlacementListViewModel) -> some View {
        HStack(spacing: 10) {
            ForEach(model.children) { child in
                let on = model.selectedChildID == child.id
                HStack(spacing: 10) {
                    InitialsAvatar(initials: DashboardGreeting.initials(child.name), size: 34,
                                   foreground: on ? Theme.Colors.white : Theme.Colors.blue700,
                                   background: on ? Theme.Colors.blue600 : Theme.Colors.blue100)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(child.name).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text(child.classLabel).font(AppFont.jakarta(10)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Spacer(minLength: 0)
                }
                .padding(8).dashboardCard(radius: 12, border: on ? Theme.Colors.blue600 : Theme.Colors.line, borderWidth: on ? 1.5 : 1)
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    @ViewBuilder
    private func content(_ model: PlacementListViewModel) -> some View {
        if model.isLoading, model.bundles.isEmpty {
            loadingSkeleton
        } else if let error = model.errorMessage, model.bundles.isEmpty {
            stateCard(icon: "wifi.exclamationmark", title: String(localized: "Couldn't load \(kind == .events ? "placement events" : "placement training")"),
                      message: String(localized: "Check your internet connection and try again."), action: String(localized: "Try again")) { model.reload() }
        } else {
            VStack(spacing: 0) {
                tabs(model)
                controls(model)
                listOrEmpty(model)
            }
        }
    }

    private func tabs(_ model: PlacementListViewModel) -> some View {
        HStack(spacing: 0) {
            ForEach(PlacementListViewModel.Tab.allCases) { tab in
                let on = model.tab == tab
                Button { model.tab = tab } label: {
                    VStack(spacing: 4) {
                        Text("\(model.count(tab))").font(AppFont.jakarta(12, .heavy))
                            .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                            .frame(width: 24, height: 24).background(on ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted, in: Circle())
                        Text(tab.title).font(AppFont.jakarta(14, .bold)).foregroundStyle(on ? Theme.Colors.blue700 : Theme.Colors.ink500)
                        Rectangle().fill(on ? Theme.Colors.blue600 : .clear).frame(height: 2)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 4).contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
        .padding(.horizontal, 16)
    }

    private func controls(_ model: PlacementListViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 10) {
            if let alert = model.alert {
                Button { if let id = alert.itemID { router.push(.placement(.detail(kind: kind, id: id, childID: model.selectedChildID))) } } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "clock.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.amber800)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.title).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.amber800)
                            Text(alert.message).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.amber800).fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.amber800)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                TextField(String(localized: "Search \(kind == .events ? "event, company or course" : "training or trainer")"), text: $model.searchText).font(AppFont.jakarta(15))
            }
            .padding(.horizontal, 14).frame(height: 46).dashboardCard(radius: 12)
            HStack(spacing: 10) {
                AssignmentDropdown(label: String(localized: "Mode"), value: model.mode, options: ["All", "On-campus", "Off-campus", "Virtual"]) { model.mode = $0 }
                AssignmentDropdown(label: kind.filterLabel, value: model.eligibility, options: model.eligibilityOptions) { model.eligibility = $0 }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private func listOrEmpty(_ model: PlacementListViewModel) -> some View {
        if model.isEmpty {
            VStack(spacing: 10) {
                IconTile(systemImage: "briefcase", size: 56, radius: 18)
                Text("Nothing here yet").font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("The placement cell will post \(kind == .events ? "events" : "training") here.").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            }
            .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(.horizontal, 16)
            Spacer(minLength: 0)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(model.sections, id: \.title) { section in
                        Text(section.title).font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.ink500)
                        ForEach(section.items) { item in
                            Button { router.push(.placement(.detail(kind: kind, id: item.id, childID: model.selectedChildID))) } label: { card(item) }
                                .buttonStyle(PressableButtonStyle())
                        }
                    }
                    footerNote
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func card(_ item: PlacementItem) -> some View {
        let notEligible = item.eligibilityNote.lowercased().contains("not")
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                dateBadge(item)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        StatusBadge(text: item.typeLabel, tone: .blueSoft, weight: .bold)
                        StatusBadge(text: item.mode.title, tone: item.mode.tone, systemImage: item.mode.systemImage, weight: .bold)
                    }
                    if let h = item.highlightText {
                        StatusBadge(text: h, tone: item.highlight.tone, weight: .heavy)
                    }
                }
                Spacer(minLength: 0)
            }
            Text(item.title).font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
            Text(item.subtitle).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).fixedSize(horizontal: false, vertical: true)
            metaRow(icon: "clock", text: item.timeText)
            metaRow(icon: item.mode.systemImage, text: item.locationText)
            if let repeatText = item.repeatText {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.amber800)
                    Text(repeatText).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.amber800).fixedSize(horizontal: false, vertical: true)
                }
            }
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(kind == .events ? "Eligible courses" : "Applicable batches").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                    HStack(spacing: 6) {
                        ForEach(item.chips, id: \.self) { chip in
                            Text(chip).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.green700)
                                .padding(.horizontal, 10).padding(.vertical, 4).overlay(Capsule().strokeBorder(Theme.Colors.green600))
                        }
                    }
                }
                Spacer(minLength: 0)
                if let who = item.company ?? item.trainer {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(kind == .events ? "Company" : "Trainer").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                        Text(who).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    }
                }
            }
            HStack(spacing: 6) {
                Image(systemName: notEligible ? "minus.circle" : "checkmark.circle.fill").font(.system(size: 12, weight: .bold))
                Text(item.eligibilityNote).font(AppFont.jakarta(12, .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(notEligible ? Theme.Colors.ink500 : Theme.Colors.green700)
            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(notEligible ? Theme.Colors.surfaceMuted : Theme.Colors.green50, in: .rect(cornerRadius: 10))
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16, border: item.highlight == .ended ? Theme.Colors.line : Theme.Colors.amberBorder.opacity(item.highlight == .tomorrow || item.highlight == .today ? 1 : 0),
                       borderWidth: item.highlight == .tomorrow || item.highlight == .today ? 1.5 : 1)
    }

    private func dateBadge(_ item: PlacementItem) -> some View {
        VStack(spacing: 0) {
            Text(item.dateMonth).font(AppFont.jakarta(11, .bold)).foregroundStyle(Theme.Colors.white.opacity(0.9))
            Text(item.dateDay).font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.white)
            Text(item.dateWeekday).font(AppFont.jakarta(10, .semibold)).foregroundStyle(Theme.Colors.white.opacity(0.9))
        }
        .frame(width: 52, height: 60).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.Colors.ink500).frame(width: 16)
            Text(text).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink700).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footerNote: some View {
        VStack(spacing: 10) {
            Text(kind == .events
                 ? "Events are posted by the placement cell. For details or registration, contact the placement cell."
                 : "Trainings are planned by the placement cell for the batches listed on each card.")
                .font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            PoweredByFooter()
        }
        .padding(.top, 8)
    }

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 150)
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Colors.line))
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden).redacted(reason: .placeholder)
    }

    private func stateCard(icon: String, title: String, message: String, action: String, perform: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: icon, size: 64, radius: 20, foreground: Theme.Colors.destructive, background: Theme.Colors.errorBackground)
            Text(title).font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900).multilineTextAlignment(.center)
            Text(message).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            Button(action: perform) {
                Label(action, systemImage: "arrow.clockwise").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 20).frame(height: 48).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle()).padding(.top, 4)
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16).frame(maxHeight: .infinity, alignment: .top)
    }
}

#Preview("Events") {
    NavigationStack { PlacementListView(kind: .events, role: .student) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}

#Preview("Training") {
    NavigationStack { PlacementListView(kind: .training, role: .student) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
