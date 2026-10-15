//
//  MyTimetableView.swift
//  Gradit
//
//  Faculty "My timetable": day strip, period cards (done/next/swapped/cover),
//  swap banner and request-swap. Design: timetableModule.pdf p17–19.
//

import SwiftUI

struct MyTimetableView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: MyTimetableViewModel?
    @State private var swappingPeriod: FacultyPeriodItem?

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model, let data = model.data {
                content(model, data: data)
            } else if let model, model.errorMessage != nil {
                ErrorStateView(message: model.errorMessage ?? "") { model.reload() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = MyTimetableViewModel(service: dependencies.timetableService) }
            await model?.load()
        }
        .sheet(item: $swappingPeriod) { period in
            RequestSwapSheet(period: period) {
                swappingPeriod = nil
                router.push(.timetable(.swapFlow(period: "\(period.period) · \(period.subjectName)")))
            }
            .presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("My timetable").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(model?.data?.teacher ?? "").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            Image(systemName: "bell.badge").font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.Colors.ink700)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func content(_ model: MyTimetableViewModel, data: FacultyTimetable) -> some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let banner = data.swapBanner { swapBannerCard(banner) }
                TimetableDayStrip(days: data.days, weekday: \.weekday, date: \.date,
                                  isToday: \.isToday, isSelected: { $0.date == model.selectedDay }) {
                    model.selectedDay = $0.date
                }
                if model.periods.isEmpty {
                    Text("No classes on this day.").font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500)
                        .frame(maxWidth: .infinity).padding(.vertical, 30)
                } else {
                    ForEach(model.periods) { period in
                        Button { swappingPeriod = period } label: { periodCard(period) }
                            .buttonStyle(.plain)
                            .disabled(period.state == .cover)
                    }
                    Text("Tap one of your periods to request a swap.")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Button { router.push(.timetable(.swapRequests)) } label: {
                        Label("My swap requests", systemImage: "arrow.left.arrow.right")
                            .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Theme.Colors.blue50, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable { model.reload() }
    }

    private func swapBannerCard(_ banner: SwapBanner) -> some View {
        Button { router.push(.timetable(.swapRequests)) } label: {
            HStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "arrow.left.arrow.right").font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.Colors.white).frame(width: 40, height: 40)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 10))
                    CountBubble(count: 1).scaleEffect(0.6).offset(x: 6, y: -6)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Swap request from \(banner.requester)").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(banner.detail).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.chevron)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.blue50, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func periodCard(_ period: FacultyPeriodItem) -> some View {
        let (text, tone): (String?, StatusBadge.Tone) = switch period.state {
        case .done: ("Done", .neutral)
        case .next: ("Next", .blueSoft)
        case .swapped: ("Swapped", .blueSoft)
        case .cover: ("Cover", .green)
        default: (nil, .neutral)
        }
        return TimetablePeriodCard(
            period: period.period, time: period.time, title: period.subjectName, subtitle: period.classLabel,
            statusText: text, statusTone: tone, note: period.note, noteIsChange: period.state != .cover,
            highlighted: period.state == .next || period.state == .cover)
    }
}

// MARK: - Request swap sheet

private struct RequestSwapSheet: View {
    let period: FacultyPeriodItem
    let onRequest: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Text(period.period).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.blue700)
                        .frame(width: 38, height: 38).background(Theme.Colors.blue50, in: .rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(period.subjectName).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text(period.time).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 36, height: 36).background(Theme.Colors.surfaceMuted, in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(20)
            VStack(spacing: 12) {
                detailRow(icon: "person.2", text: period.classLabel)
                Button { onRequest() } label: {
                    Label("Request swap", systemImage: "arrow.left.arrow.right")
                        .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                Text("Swaps apply to one date only.").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.horizontal, 20).padding(.bottom, 16)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
            Text(text).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink900)
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack { MyTimetableView() }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
