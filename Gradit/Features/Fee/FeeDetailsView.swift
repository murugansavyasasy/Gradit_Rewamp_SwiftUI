//
//  FeeDetailsView.swift
//  Gradit
//
//  Student / parent Fee Details: summary card, Due / Fee structure / Payments
//  tabs, upload proof and pay. Design: Fee Details.png.
//

import SwiftUI
import UniformTypeIdentifiers

struct FeeDetailsView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: FeeDetailsViewModel?
    @State private var isUploading = false
    @State private var isConfirmingPay = false
    @State private var showPaid = false

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
            if model == nil { model = FeeDetailsViewModel(role: role, service: dependencies.feeService) }
            await model?.load()
        }
        .fileImporter(isPresented: $isUploading, allowedContentTypes: [.pdf, .image], allowsMultipleSelection: false) { _ in }
        .alert("Pay \(FeeFormat.rupees(model?.payableTotal ?? 0))?", isPresented: $isConfirmingPay) {
            Button("Cancel", role: .cancel) {}
            Button("Pay now") { showPaid = true }
        } message: {
            Text("You'll be taken to the secure payment gateway to complete this payment.")
        }
        .alert("Payment started", isPresented: $showPaid) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your payment is being processed. It will show under Payments as \"Under verification\" until confirmed.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Fee Details").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                if let s = model?.data?.summary {
                    Text("\(s.studentName) · \(s.programLine)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Button {} label: {
                Image(systemName: "square.and.arrow.down").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink700).frame(width: 40, height: 40).dashboardCard(radius: 12)
            }
            .buttonStyle(.plain).accessibilityLabel("Download statement")
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func childSwitcher(_ model: FeeDetailsViewModel) -> some View {
        HStack(spacing: 10) {
            ForEach(model.children) { child in
                let on = model.selectedChildID == child.id
                Button { model.selectChild(child.id) } label: {
                    HStack(spacing: 10) {
                        InitialsAvatar(initials: DashboardGreeting.initials(child.name), size: 36,
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
    private func content(_ model: FeeDetailsViewModel) -> some View {
        if model.isLoading, model.data == nil {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = model.errorMessage, model.data == nil {
            VStack(spacing: 10) {
                IconTile(systemImage: "wifi.exclamationmark", size: 64, radius: 20, foreground: Theme.Colors.destructive, background: Theme.Colors.errorBackground)
                Text("Couldn't load fee details").font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(error).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
                Button("Try again") { model.reload() }.font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 20).frame(height: 48).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12)).buttonStyle(PressableButtonStyle())
            }
            .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16).frame(maxHeight: .infinity, alignment: .top)
        } else if let data = model.data {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        summaryCard(data.summary)
                        tabBar(model)
                        switch model.tab {
                        case .due: dueTab(model, data: data)
                        case .structure: structureTab(data)
                        case .payments: paymentsTab(data)
                        }
                    }
                    .padding(16).padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                .refreshable { model.reload() }
                bottomBar(model)
            }
        }
    }

    // MARK: - Summary

    private func summaryCard(_ s: FeeSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Amount due").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.white.opacity(0.85))
                    Text(FeeFormat.rupees(s.amountDue)).font(AppFont.jakarta(30, .heavy)).foregroundStyle(Theme.Colors.white)
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill").font(.system(size: 10, weight: .bold))
                        Text(s.dueText).font(AppFont.jakarta(12, .bold))
                    }
                    .foregroundStyle(Theme.Colors.amber800)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.Colors.warningBackground, in: Capsule())
                }
                Spacer(minLength: 0)
                ring(percent: s.paidPercent)
            }
            HStack(spacing: 10) {
                summaryBox("Total", s.total)
                summaryBox("Paid", s.paid)
                summaryBox("In review", s.inReview)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.blue700, in: .rect(cornerRadius: 18))
    }

    private func ring(percent: Int) -> some View {
        ZStack {
            Circle().stroke(Theme.Colors.white.opacity(0.25), lineWidth: 8)
            Circle().trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(Theme.Colors.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(percent)%").font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.white)
                Text("paid").font(AppFont.jakarta(10)).foregroundStyle(Theme.Colors.white.opacity(0.85))
            }
        }
        .frame(width: 78, height: 78)
    }

    private func summaryBox(_ label: LocalizedStringKey, _ amount: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.white.opacity(0.85))
            Text(FeeFormat.rupees(amount)).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Theme.Colors.white.opacity(0.15), in: .rect(cornerRadius: 12))
    }

    // MARK: - Tabs

    private func tabBar(_ model: FeeDetailsViewModel) -> some View {
        HStack(spacing: 4) {
            ForEach(FeeDetailsViewModel.Tab.allCases) { tab in
                let on = model.tab == tab
                Button(tab.title) { model.tab = tab }
                    .font(AppFont.jakarta(14, on ? .bold : .semibold))
                    .foregroundStyle(on ? Theme.Colors.ink900 : Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(on ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                    .shadow(color: on ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
                    .buttonStyle(.plain)
            }
        }
        .padding(4).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.line))
    }

    // MARK: - Due

    private func dueTab(_ model: FeeDetailsViewModel, data: FeeDetails) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(data.dueItems) { item in dueCard(model, item: item) }
            if let note = data.paidNote {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.green700)
                    Text(note).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.green700).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.green50, in: .rect(cornerRadius: 12))
            }
        }
    }

    private func dueCard(_ model: FeeDetailsViewModel, item: FeeDueItem) -> some View {
        let selected = item.selectable && model.isSelected(item)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                IconTile(systemImage: item.selectable ? "doc.text" : "house", size: 40,
                         foreground: item.selectable ? Theme.Colors.blue600 : Theme.Colors.amber800,
                         background: item.selectable ? Theme.Colors.blue50 : Theme.Colors.warningBackground)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(item.subtitle).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                Text(FeeFormat.rupees(item.amount)).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            }
            if let note = item.reviewNote {
                Text(note).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.amber800)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(10)
                    .background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 10))
            }
            if item.selectable {
                Button { model.toggle(item) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: selected ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18, weight: .semibold)).foregroundStyle(selected ? Theme.Colors.blue600 : Theme.Colors.ink300)
                        Text("Include in this payment").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink900)
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16, border: selected ? Theme.Colors.blue600 : Theme.Colors.line, borderWidth: selected ? 1.5 : 1)
    }

    // MARK: - Fee structure

    private func structureTab(_ data: FeeDetails) -> some View {
        VStack(spacing: 14) {
            ForEach(data.structure) { item in structureCard(item) }
        }
    }

    private func structureCard(_ item: FeeStructureItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconTile(systemImage: icon(for: item.name), size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(item.subtitle).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                StatusBadge(text: item.status.title, tone: item.status == .paid ? .green : (item.status == .due ? .amber : .blueSoft), weight: .heavy)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Colors.surfaceMuted)
                    Capsule().fill(Theme.Colors.green600).frame(width: max(0, geo.size.width * item.progress))
                }
            }
            .frame(height: 6)
            HStack {
                Text("Paid \(FeeFormat.rupees(item.paid))").font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink500)
                Spacer()
                Text("of \(FeeFormat.rupees(item.total))").font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink900)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func icon(for name: String) -> String {
        if name.contains("Tuition") { "graduationcap" }
        else if name.contains("Hostel") { "house" }
        else if name.contains("Transport") { "bus" }
        else { "doc.text" }
    }

    // MARK: - Payments

    private func paymentsTab(_ data: FeeDetails) -> some View {
        VStack(spacing: 14) {
            ForEach(data.payments) { payment in paymentCard(payment) }
        }
    }

    private func paymentCard(_ p: FeePayment) -> some View {
        let success = p.status == .successful
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: success ? "checkmark" : "clock")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(success ? Theme.Colors.green700 : Theme.Colors.amber800)
                .frame(width: 36, height: 36)
                .background(success ? Theme.Colors.green50 : Theme.Colors.warningBackground, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(FeeFormat.rupees(p.amount)).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(p.detail).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).fixedSize(horizontal: false, vertical: true)
                Text(p.status.title).font(AppFont.jakarta(12, .heavy)).foregroundStyle(success ? Theme.Colors.green700 : Theme.Colors.amber800)
            }
            Spacer(minLength: 0)
            if p.hasReceipt {
                Button {} label: {
                    Label("Receipt", systemImage: "arrow.down.to.line").font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.blue600)
                        .padding(.horizontal, 10).frame(height: 34).background(Theme.Colors.blue50, in: .rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    // MARK: - Bottom bar

    private func bottomBar(_ model: FeeDetailsViewModel) -> some View {
        HStack(spacing: 12) {
            Button { isUploading = true } label: {
                Label("Upload proof", systemImage: "arrow.up.doc").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
            }
            .buttonStyle(.plain)
            Button { isConfirmingPay = true } label: {
                HStack(spacing: 6) {
                    Text("Pay \(FeeFormat.rupees(model.payableTotal))")
                    Image(systemName: "arrow.right")
                }
                .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.green600, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!model.canPay).opacity(model.canPay ? 1 : 0.5)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.white)
    }
}

#Preview {
    NavigationStack { FeeDetailsView(role: .student) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
