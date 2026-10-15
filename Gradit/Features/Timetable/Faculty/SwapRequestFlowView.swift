//
//  SwapRequestFlowView.swift
//  Gradit
//
//  Faculty swap request: choose a period (step 1) → review & send (step 2) → sent.
//  Design: timetableModule.pdf p20–22.
//

import SwiftUI

struct SwapRequestFlowView: View {
    let yourPeriod: String

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    private enum Step { case choose, review, sent }
    @State private var step: Step = .choose
    @State private var candidates: [SwapCandidate] = []
    @State private var selected: SwapCandidate?
    @State private var date = "Fri, 09 Oct"
    @State private var note = ""

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .choose: chooseStep
            case .review: reviewStep
            case .sent: sentStep
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { if candidates.isEmpty { candidates = (try? await dependencies.timetableService.swapCandidates(onDate: date)) ?? [] } }
    }

    // MARK: - Step 1

    private var chooseStep: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Request swap"),
                             subtitle: String(localized: "Step 1 of 2 · choose a period"), showsBack: true) { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    yourPeriodCard
                    dateChips
                    Text("B.E. CSE · Sem 5 A on \(date)").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    ForEach(candidates) { candidate in candidateRow(candidate) }
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("Back") { dismiss() }
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                    Button { step = .review } label: {
                        Label("Next: review", systemImage: "chevron.right").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                            .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                    }
                    .buttonStyle(PressableButtonStyle()).disabled(selected == nil).opacity(selected == nil ? 0.5 : 1)
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.white)
            }
        }
    }

    private var yourPeriodCard: some View {
        HStack(spacing: 12) {
            Text(yourPeriod.components(separatedBy: " · ").first ?? "P?")
                .font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.white)
                .frame(width: 40, height: 40).background(Theme.Colors.blue600, in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR PERIOD").font(AppFont.jakarta(10, .heavy)).foregroundStyle(Theme.Colors.blue700)
                Text(yourPeriod.components(separatedBy: " · ").dropFirst().joined(separator: " · "))
                    .font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("10:55 – 11:45 · B.E. CSE Sem 5 A · B-204").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.blue50, in: .rect(cornerRadius: 14))
    }

    private var dateChips: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Date (this date only)").font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink500)
            HStack(spacing: 8) {
                ForEach(["Today · Wed, 07 Oct", "Fri, 09 Oct", "Pick date · Mon, 12 Oct"], id: \.self) { option in
                    let label = option.components(separatedBy: " · ").first ?? option
                    let on = date == (option.contains("Fri") ? "Fri, 09 Oct" : label)
                    Button {
                        date = option.contains("Fri") ? "Fri, 09 Oct" : (option.contains("Today") ? "Wed, 07 Oct" : "Mon, 12 Oct")
                    } label: {
                        VStack(spacing: 1) {
                            Text(option.components(separatedBy: " · ").first ?? "").font(AppFont.jakarta(12, .bold))
                            if option.contains("·") { Text(option.components(separatedBy: " · ").last ?? "").font(AppFont.jakarta(10)) }
                        }
                        .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 12).frame(height: 48)
                        .background(on ? Theme.Colors.blue600 : Theme.Colors.white, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(on ? .clear : Theme.Colors.border))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func candidateRow(_ candidate: SwapCandidate) -> some View {
        let on = selected?.id == candidate.id
        return Button { if candidate.selectable { selected = candidate } } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(candidate.period).font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.blue700)
                    .frame(width: 34, height: 34).background(Theme.Colors.blue50, in: .rect(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 2) {
                    Text(candidate.time).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink500)
                    Text(candidate.subject).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(candidate.teacher).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    if let reason = candidate.reason {
                        Text(reason).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.destructive).fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(candidate.eligibility).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.green700).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if !candidate.selectable {
                    StatusBadge(text: candidate.eligibility, tone: .neutral)
                } else if on {
                    StatusBadge(text: "Selected", tone: .blueSolid, weight: .heavy)
                }
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(radius: 14, border: on ? Theme.Colors.blue600 : Theme.Colors.line, borderWidth: on ? 1.5 : 1)
            .opacity(candidate.selectable ? 1 : 0.6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2

    private var reviewStep: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Swap details"),
                             subtitle: String(localized: "Step 2 of 2 · check and send"), showsBack: true) { step = .choose }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar").font(.system(size: 13, weight: .bold))
                        Text("\(date) 2026 · this date only").font(AppFont.jakarta(13, .bold))
                    }
                    .foregroundStyle(Theme.Colors.ink900)

                    swapSideCard(title: "YOU GIVE", tint: Theme.Colors.amber800,
                                 rows: [("Period", yourPeriod), ("Now", "Your DBMS class"),
                                        ("Class", "B.E. CSE · Sem 5 A · B-204"),
                                        ("After swap", "\(selected?.subject ?? "") · \(selected?.teacher ?? "")")])
                    Image(systemName: "arrow.up.arrow.down").font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.Colors.blue600)
                        .frame(maxWidth: .infinity)
                    swapSideCard(title: "YOU TAKE", tint: Theme.Colors.blue700,
                                 rows: [("Period", "\(selected?.period ?? "") · \(selected?.time ?? "")"),
                                        ("Now", "\(selected?.subject ?? "") · \(selected?.teacher ?? "")"),
                                        ("Class", "B.E. CSE · Sem 5 A · B-204"), ("After swap", "You teach DBMS")])

                    Text("Subject and room stay the same; only the periods exchange. B.E. CSE Sem 5 A sees \"Swapped\" on both periods.")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 13, weight: .bold))
                        Text("Both sides checked: no clashes for you or \(selected?.teacher ?? "").").font(AppFont.jakarta(12, .bold))
                    }
                    .foregroundStyle(Theme.Colors.green700).padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.green50, in: .rect(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note for \(selected?.teacher ?? "") (optional)").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
                        TextEditor(text: $note).font(AppFont.jakarta(15)).scrollContentBackground(.hidden)
                            .frame(minHeight: 90).padding(10).background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
                    }
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("Back") { step = .choose }
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                    Button { step = .sent } label: {
                        Label("Send request", systemImage: "paperplane.fill").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                            .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.white)
            }
        }
    }

    private func swapSideCard(title: String, tint: Color, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(AppFont.jakarta(12, .heavy)).foregroundStyle(tint)
            ForEach(rows, id: \.0) { row in
                HStack(alignment: .top) {
                    Text(row.0).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).frame(width: 84, alignment: .leading)
                    Text(row.1).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink900).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 14, border: tint.opacity(0.4), borderWidth: 1)
    }

    // MARK: - Sent

    private var sentStep: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark").font(.system(size: 36, weight: .bold)).foregroundStyle(Theme.Colors.green600)
                .frame(width: 88, height: 88).background(Theme.Colors.green50, in: Circle())
            Text("Swap request sent").font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("\(selected?.teacher ?? "") will get a notification. If he doesn't reply before \(date), the request expires and nothing changes.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center).padding(.horizontal, 28)
            Spacer()
            VStack(spacing: 10) {
                Button { dismiss(); router.push(.timetable(.swapRequests)) } label: {
                    Text("View My swap requests").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                Button("Back to My timetable") { dismiss() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack { SwapRequestFlowView(yourPeriod: "P3 · Database Management Systems") }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
