//
//  SwapRequestsListView.swift
//  Gradit
//
//  Faculty "My swap requests": sent + received, with cancel / reply.
//  Design: timetableModule.pdf p27–29.
//

import SwiftUI

struct SwapRequestsListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var model: SwapRequestsViewModel?
    @State private var cancelling: SwapRequest?

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "My swap requests"),
                             subtitle: String(localized: "Sent and received"), showsBack: true) { dismiss() }
            if let model {
                tabs(model)
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = SwapRequestsViewModel(service: dependencies.timetableService) }
            await model?.load()
        }
        .alert("Cancel this swap request?", isPresented: Binding(get: { cancelling != nil }, set: { if !$0 { cancelling = nil } })) {
            Button("Keep request", role: .cancel) {}
            Button("Cancel request", role: .destructive) { if let c = cancelling { model?.cancel(c) } }
        } message: {
            if let c = cancelling { Text("\(c.counterpart) will be told. Your \(c.dateText) timetable stays as it is.") }
        }
    }

    private func tabs(_ model: SwapRequestsViewModel) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 18) {
                ForEach(SwapRequestsViewModel.Tab.allCases) { tab in
                    let on = model.tab == tab
                    Button { model.tab = tab } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 5) {
                                Text(tab.title).font(AppFont.jakarta(14, .bold))
                                Text("\(model.count(tab))").font(AppFont.jakarta(12, .heavy))
                            }
                            .foregroundStyle(on ? Theme.Colors.blue700 : Theme.Colors.ink500)
                            Rectangle().fill(on ? Theme.Colors.blue600 : .clear).frame(height: 2)
                        }
                        .padding(.top, 4).contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
    }

    @ViewBuilder
    private func content(_ model: SwapRequestsViewModel) -> some View {
        if model.isLoading, model.requests.isEmpty {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.visible.isEmpty {
            VStack(spacing: 10) {
                IconTile(systemImage: "arrow.left.arrow.right", size: 56, radius: 18)
                Text("No swap requests yet").font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("Tap one of your periods in My timetable to request a swap.")
                    .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
                Button("Open My timetable") { dismiss() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 20).frame(height: 48).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                    .buttonStyle(PressableButtonStyle())
            }
            .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16)
            .frame(maxHeight: .infinity, alignment: .top)
        } else {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(model.visible) { request in card(model, request: request) }
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func card(_ model: SwapRequestsViewModel, request: SwapRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(request.isSent ? "Sent" : "Received")
                    .font(AppFont.jakarta(11, .heavy)).foregroundStyle(Theme.Colors.ink700)
                    .padding(.horizontal, 8).padding(.vertical, 3).background(Theme.Colors.surfaceMuted, in: Capsule())
                Text(request.dateText).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                StatusBadge(text: request.status.title, tone: statusTone(request.status), weight: .heavy)
            }
            HStack(spacing: 8) {
                swapBox(request.giveSummary)
                Image(systemName: "arrow.left.arrow.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.blue600)
                swapBox(request.takeSummary)
            }
            Text(request.metaText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)

            if request.status == .pending, request.isSent {
                Button("Cancel request") { cancelling = request }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.destructive)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.destructive.opacity(0.5)))
            } else if request.status == .needsReply {
                Button { router.push(.timetable(.incoming(request))) } label: {
                    Text("Reply").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 48).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func swapBox(_ text: String) -> some View {
        let parts = text.components(separatedBy: " · ")
        return VStack(alignment: .leading, spacing: 2) {
            Text(parts.prefix(2).joined(separator: " · ")).font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(parts.dropFirst(2).joined(separator: " · ")).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))
    }

    private func statusTone(_ status: SwapStatus) -> StatusBadge.Tone {
        switch status {
        case .pending, .needsReply: .amber
        case .accepted: .green
        case .declined: .red
        case .expired: .neutral
        }
    }
}

#Preview {
    NavigationStack { SwapRequestsListView() }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
