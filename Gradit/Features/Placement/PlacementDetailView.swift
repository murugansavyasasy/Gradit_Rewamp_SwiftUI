//
//  PlacementDetailView.swift
//  Gradit
//
//  Student / parent placement event / training detail. Design: placementModule.pdf
//  p6–10, placementTaining.pdf p6–10.
//

import SwiftUI

struct PlacementDetailView: View {
    let kind: PlacementKind
    let id: String
    let childID: String?

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: PlacementDetailViewModel?

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: kind == .events ? String(localized: "Placement event") : String(localized: "Placement training"),
                             subtitle: String(localized: "From the placement cell"), showsBack: true) { dismiss() }
            if let model, let detail = model.detail {
                content(detail)
            } else if let model, model.errorMessage != nil {
                ErrorStateView(message: model.errorMessage ?? "") { model.reload() }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = PlacementDetailViewModel(kind: kind, id: id, childID: childID, service: dependencies.placementService) }
            await model?.load()
        }
    }

    private func content(_ d: PlacementDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                topCard(d)
                if d.kind == .events {
                    eligibilityCard(d)
                    if !d.orgs.isEmpty { orgsCard(d) }
                } else {
                    scheduleCard(d)
                    eligibilityCard(d)
                }
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Top card

    private func topCard(_ d: PlacementDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                StatusBadge(text: d.typeLabel, tone: .blueSoft, weight: .bold)
                StatusBadge(text: d.mode.title, tone: d.mode.tone, systemImage: d.mode.systemImage, weight: .bold)
                if d.highlight == .ended { StatusBadge(text: "Ended", tone: .neutral, weight: .heavy) }
            }
            if d.kind == .training, let h = d.highlightText {
                StatusBadge(text: h, tone: d.highlight.tone, weight: .heavy)
            }
            Text(d.title).font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
            Text(d.subtitle).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).fixedSize(horizontal: false, vertical: true)

            if d.kind == .events {
                VStack(alignment: .leading, spacing: 8) {
                    summaryRow(icon: "calendar", text: d.dateLine)
                    summaryRow(icon: "clock", text: d.timeText)
                    summaryRow(icon: "mappin.and.ellipse", text: d.locationText)
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
            } else if let trainer = d.trainer {
                HStack(spacing: 12) {
                    InitialsAvatar(initials: trainer.initials, size: 40, foreground: Theme.Colors.blue700, background: Theme.Colors.blue100)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Trainer").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                        Text(trainer.name).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text(trainer.role).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
            }

            actions(d)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func summaryRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.ink500).frame(width: 18)
            Text(text).font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func actions(_ d: PlacementDetail) -> some View {
        if d.highlight != .ended {
            VStack(spacing: 10) {
                if d.joinable {
                    Button {} label: {
                        Label(d.joinLabel, systemImage: "video").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
                            .frame(maxWidth: .infinity, minHeight: 50).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.blue600))
                    }.buttonStyle(PressableButtonStyle())
                } else {
                    Button {} label: {
                        Label("Open in Maps", systemImage: "map").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
                            .frame(maxWidth: .infinity, minHeight: 50).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.blue600))
                    }.buttonStyle(PressableButtonStyle())
                }
                HStack(spacing: 10) {
                    Button {} label: {
                        Label("Add to calendar", systemImage: "calendar.badge.plus").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink700)
                            .frame(maxWidth: .infinity, minHeight: 48).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
                    }.buttonStyle(.plain)
                    ShareLink(item: d.title) {
                        Label("Share", systemImage: "square.and.arrow.up").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink700)
                            .frame(maxWidth: .infinity, minHeight: 48).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
                    }
                }
            }
        }
    }

    // MARK: - Eligibility (for your children / applicable batches)

    private func eligibilityCard(_ d: PlacementDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(d.childrenHeading).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            if !d.batchChips.isEmpty {
                HStack(spacing: 8) {
                    ForEach(d.batchChips, id: \.self) { chip in
                        Text(chip).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
                            .padding(.horizontal, 12).padding(.vertical, 5).overlay(Capsule().strokeBorder(Theme.Colors.border))
                    }
                }
            }
            ForEach(d.children) { child in
                HStack(spacing: 12) {
                    InitialsAvatar(initials: DashboardGreeting.initials(child.name), size: 38,
                                   foreground: Theme.Colors.blue700, background: Theme.Colors.blue100)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(child.name).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        HStack(spacing: 4) {
                            Image(systemName: child.eligible ? "checkmark.circle.fill" : "minus.circle").font(.system(size: 11, weight: .bold))
                            Text(child.note).font(AppFont.jakarta(12, .semibold))
                        }
                        .foregroundStyle(child.eligible ? Theme.Colors.green700 : Theme.Colors.ink500)
                    }
                    Spacer(minLength: 0)
                }
                .padding(10).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.white, in: .rect(cornerRadius: 12))
            }
            Text("Based on the \(d.kind == .events ? "eligible courses" : "batches") listed by the placement cell. Other criteria below also apply.")
                .font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.green50, in: .rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Colors.green100))
    }

    // MARK: - Orgs (events)

    private func orgsCard(_ d: PlacementDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(d.orgsHeading).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            ForEach(d.orgs) { org in
                HStack(spacing: 12) {
                    Text(org.initials).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.blue700)
                        .frame(width: 40, height: 40).background(Theme.Colors.blue50, in: .rect(cornerRadius: 10))
                    Text(org.name).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    // MARK: - Schedule (training)

    private func scheduleCard(_ d: PlacementDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Schedule").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            ForEach(d.scheduleRows) { row in
                HStack(alignment: .top) {
                    Text(row.label).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).frame(width: 84, alignment: .leading)
                    Text(row.value).font(AppFont.jakarta(14, .heavy))
                        .foregroundStyle(row.highlight ? Theme.Colors.amber800 : Theme.Colors.ink900)
                        .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                }
            }
            if !d.nextSessions.isEmpty {
                Text("Next sessions").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900).padding(.top, 4)
                ForEach(d.nextSessions, id: \.self) { s in
                    HStack(spacing: 8) {
                        Image(systemName: "calendar").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                        Text(s).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink900)
                        Spacer(minLength: 0)
                    }
                    .padding(10).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }
}

#Preview("Event") {
    NavigationStack { PlacementDetailView(kind: .events, id: "ev-chennai", childID: nil) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}

#Preview("Training") {
    NavigationStack { PlacementDetailView(kind: .training, id: "tr-dsa", childID: nil) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
