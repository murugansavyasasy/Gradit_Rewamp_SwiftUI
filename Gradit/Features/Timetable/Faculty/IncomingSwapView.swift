//
//  IncomingSwapView.swift
//  Gradit
//
//  Faculty incoming swap request: accept / decline / expired.
//  Design: timetableModule.pdf p23–26.
//

import SwiftUI

struct IncomingSwapView: View {
    let request: SwapRequest

    @Environment(\.dismiss) private var dismiss
    @State private var result: SwapStatus
    @State private var isDeclining = false

    init(request: SwapRequest) {
        self.request = request
        _result = State(initialValue: request.status)
    }

    private var expired: Bool { result == .expired }

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Incoming swap request"),
                             subtitle: String(localized: "Reply before Mon, 12 Oct"), showsBack: true) { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if result == .accepted { banner("Swap applied for \(request.dateText).", "Both timetables are updated and show \"Swapped\". \(request.counterpart) and the class have been notified.", .green) }
                    if expired { banner("Expired · \(request.dateText) passed without a reply. Nothing changed.", "", .neutral) }
                    requesterCard
                    dateHeader
                    sideCard("YOU GIVE", Theme.Colors.amber800, request.giveSummary, afterSwap: request.takeSummary)
                    Image(systemName: "arrow.up.arrow.down").font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.Colors.blue600).frame(maxWidth: .infinity)
                    sideCard("YOU TAKE", Theme.Colors.blue700, request.takeSummary, afterSwap: "You teach DBMS")
                    Text("Subject and room stay the same; only the periods exchange.")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 13, weight: .bold))
                        Text("You are free at 10:55 AM on Monday. No clash.").font(AppFont.jakarta(12, .bold))
                    }
                    .foregroundStyle(Theme.Colors.green700).padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.green50, in: .rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note from \(request.counterpart)").font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.ink700)
                        Text("I have a department meeting at 10:55 AM on Monday. Could you take my P3 and I'll take your P1?")
                            .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(14).dashboardCard(radius: 14)
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) { bottomBar }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isDeclining) {
            DeclineSwapSheet(requester: request.counterpart) { result = .declined }.presentationDetents([.medium])
        }
    }

    private func banner(_ title: String, _ detail: String, _ tone: StatusBadge.Tone) -> some View {
        let fg = tone == .green ? Theme.Colors.green700 : Theme.Colors.ink700
        let bg = tone == .green ? Theme.Colors.green50 : Theme.Colors.surfaceMuted
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: tone == .green ? "checkmark.circle.fill" : "clock.fill").font(.system(size: 13, weight: .bold))
                Text(title).font(AppFont.jakarta(13, .heavy))
            }
            if !detail.isEmpty { Text(detail).font(AppFont.jakarta(12)).fixedSize(horizontal: false, vertical: true) }
        }
        .foregroundStyle(fg).padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(bg, in: .rect(cornerRadius: 12))
    }

    private var requesterCard: some View {
        HStack(spacing: 12) {
            InitialsAvatar(initials: DashboardGreeting.initials(request.counterpart), size: 44,
                           foreground: Theme.Colors.green700, background: Theme.Colors.green50)
            VStack(alignment: .leading, spacing: 2) {
                Text(request.counterpart).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("Computer Networks · asked today, 08:30 AM").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            StatusBadge(text: result == .needsReply ? "Waiting for you" : result.title,
                        tone: result == .accepted ? .green : (expired ? .neutral : .amber), weight: .heavy)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private var dateHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar").font(.system(size: 13, weight: .bold))
            Text("\(request.dateText) 2026 · this date only").font(AppFont.jakarta(13, .bold))
        }
        .foregroundStyle(Theme.Colors.ink900)
    }

    private func sideCard(_ title: String, _ tint: Color, _ summary: String, afterSwap: String) -> some View {
        let parts = summary.components(separatedBy: " · ")
        return VStack(alignment: .leading, spacing: 8) {
            Text(title).font(AppFont.jakarta(12, .heavy)).foregroundStyle(tint)
            row("Period", parts.prefix(2).joined(separator: " · "))
            row("Now", parts.dropFirst(2).joined(separator: " · "))
            row("Class", request.classLabel)
            row("After swap", afterSwap.components(separatedBy: " · ").dropFirst(2).joined(separator: " · "))
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 14, border: tint.opacity(0.4), borderWidth: 1)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).frame(width: 84, alignment: .leading)
            Text(value).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink900).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if result == .accepted {
            Button { dismiss() } label: {
                Text("See My timetable").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.green600, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.surfaceMuted)
        } else if !expired && result != .declined {
            HStack(spacing: 12) {
                Button("Decline") { isDeclining = true }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.destructive)
                    .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.destructive))
                Button { result = .accepted } label: {
                    Label("Accept", systemImage: "checkmark").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.surfaceMuted)
        }
    }
}

// MARK: - Decline sheet

private struct DeclineSwapSheet: View {
    let requester: String
    let onDecline: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Decline swap?").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 36, height: 36).background(Theme.Colors.surfaceMuted, in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(20)
            VStack(alignment: .leading, spacing: 12) {
                Text("\(requester) will be notified. Nothing changes in the timetable.")
                    .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).fixedSize(horizontal: false, vertical: true)
                Text("Note (optional)").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
                TextEditor(text: $note).font(AppFont.jakarta(15)).scrollContentBackground(.hidden)
                    .frame(minHeight: 90).padding(10).background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
                Button { onDecline(); dismiss() } label: {
                    Text("Decline request").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.destructive, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 20).padding(.bottom, 16)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }
}
