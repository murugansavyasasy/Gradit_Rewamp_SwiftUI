//
//  ClassTimetableView.swift
//  Gradit
//
//  Student / parent class timetable: Day + Week, child switcher, change notes,
//  period detail and states. Design: timetableModule.pdf p30–41.
//

import SwiftUI

struct ClassTimetableView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: ClassTimetableViewModel?
    @State private var detail: LearnerPeriodItem?
    @State private var isDownloading = false

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model {
                if model.isParent, !model.children.isEmpty { childSwitcher(model) }
                modeToggle(model)
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = ClassTimetableViewModel(role: role, service: dependencies.timetableService) }
            await model?.load()
        }
        .sheet(item: $detail) { period in PeriodDetailSheet(period: period).presentationDetents([.medium, .large]) }
        .alert("Download timetable?", isPresented: $isDownloading) {
            Button("Cancel", role: .cancel) {}
            Button("Download") {}
        } message: {
            Text("A PDF of the weekly timetable for \(model?.data?.classLabel ?? "") will be saved to your phone.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Class timetable").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(model?.data?.classLabel ?? "").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            Button { isDownloading = true } label: {
                Image(systemName: "square.and.arrow.down").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink700).frame(width: 40, height: 40).dashboardCard(radius: 12)
            }
            .buttonStyle(.plain).accessibilityLabel("Download timetable")
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func childSwitcher(_ model: ClassTimetableViewModel) -> some View {
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

    private func modeToggle(_ model: ClassTimetableViewModel) -> some View {
        @Bindable var model = model
        return HStack(spacing: 4) {
            ForEach(ClassTimetableViewModel.ViewMode.allCases) { mode in
                let on = model.viewMode == mode
                Button(mode.title) { model.viewMode = mode }
                    .font(AppFont.jakarta(15, on ? .bold : .semibold)).foregroundStyle(on ? Theme.Colors.ink900 : Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(on ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                    .shadow(color: on ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
                    .buttonStyle(.plain)
            }
        }
        .padding(4).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.line))
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    @ViewBuilder
    private func content(_ model: ClassTimetableViewModel) -> some View {
        if model.isLoading, model.data == nil {
            loadingSkeleton
        } else if let error = model.errorMessage, model.data == nil {
            stateCard(icon: "wifi.exclamationmark", title: String(localized: "Couldn't load the timetable"),
                      message: String(localized: "Check your internet connection and try again."), action: String(localized: "Try again")) { model.reload() }
        } else if let data = model.data, !data.published {
            stateCard(icon: "clock", title: String(localized: "Timetable not published yet"),
                      message: String(localized: "Your college hasn't published the timetable for \(data.classLabel). You'll get a notification when it's ready."), action: nil, perform: nil)
        } else if let data = model.data {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if model.viewMode == .day {
                        TimetableDayStrip(days: data.days, weekday: \.weekday, date: \.date,
                                          isToday: \.isToday, isSelected: { $0.date == model.selectedDay }) { model.selectedDay = $0.date }
                        if let note = data.changesNote { changesCard(note) }
                        if model.periods.isEmpty {
                            closedCard(data)
                        } else {
                            ForEach(model.periods) { period in
                                Button { detail = period } label: { periodCard(period) }.buttonStyle(.plain)
                            }
                        }
                    } else {
                        TimetableWeekGrid(grid: data.weekGrid, selectedDay: "Wed", showsDetail: false)
                            .padding(12).dashboardCard(radius: 16)
                        Text("Tap any period for details. ★ = substitute, ⇄ = swapped, Free = free period, — = no class.")
                            .font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500).fixedSize(horizontal: false, vertical: true)
                    }
                    Text(data.updatedText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func changesCard(_ note: String) -> some View {
        let lines = note.components(separatedBy: "\n")
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill").font(.system(size: 13, weight: .bold))
                Text(lines.first ?? "").font(AppFont.jakarta(14, .heavy))
            }
            ForEach(lines.dropFirst(), id: \.self) { line in
                Text(line).font(AppFont.jakarta(12)).fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(Theme.Colors.amber800).padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 14))
    }

    private func periodCard(_ period: LearnerPeriodItem) -> some View {
        let (text, tone): (String?, StatusBadge.Tone) = switch period.state {
        case .now: ("Now", .blueSolid)
        case .swapped: ("Swapped", .blueSoft)
        case .substitute: ("Changed", .amber)
        case .free: ("Free", .neutral)
        default: (nil, .neutral)
        }
        return TimetablePeriodCard(
            period: period.period, time: period.time, title: period.subjectName,
            subtitle: "\(period.teacher) · \(period.room)", statusText: text, statusTone: tone,
            note: period.changeNote, noteIsChange: true, highlighted: period.state == .now)
    }

    private func closedCard(_ data: ClassTimetable) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "calendar", size: 56, radius: 18)
            Text("No classes on this day").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(data.closedNote ?? "There are no classes scheduled.").font(AppFont.jakarta(13))
                .foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18)
    }

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 84)
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Colors.line))
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden).redacted(reason: .placeholder)
    }

    private func stateCard(icon: String, title: String, message: String, action: String?, perform: (() -> Void)?) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: icon, size: 64, radius: 20,
                     foreground: icon.contains("wifi") ? Theme.Colors.destructive : Theme.Colors.blue600,
                     background: icon.contains("wifi") ? Theme.Colors.errorBackground : Theme.Colors.blue50)
            Text(title).font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900).multilineTextAlignment(.center)
            Text(message).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            if let action, let perform {
                Button(action: perform) {
                    Label(action, systemImage: "arrow.clockwise").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                        .padding(.horizontal, 20).frame(height: 48).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle()).padding(.top, 4)
            }
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16).frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Period detail sheet

private struct PeriodDetailSheet: View {
    let period: LearnerPeriodItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Text(period.period).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.blue700)
                        .frame(width: 38, height: 38).background(Theme.Colors.blue50, in: .rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(period.subjectName).font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text("Wednesday · \(period.period) · \(period.time)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 36, height: 36).background(Theme.Colors.surfaceMuted, in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(20)
            VStack(alignment: .leading, spacing: 14) {
                if let note = period.changeNote {
                    Text(note).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.amber800)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                        .background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 12))
                }
                HStack(spacing: 10) {
                    InitialsAvatar(initials: DashboardGreeting.initials(period.teacher), size: 40,
                                   foreground: Theme.Colors.green700, background: Theme.Colors.green50)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Teacher").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                        Text(period.teacher).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    }
                    Spacer(minLength: 0)
                    Button {} label: {
                        Label("Message", systemImage: "bubble.left").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.white)
                            .padding(.horizontal, 14).frame(height: 40).background(Theme.Colors.blue600, in: .rect(cornerRadius: 10))
                    }.buttonStyle(PressableButtonStyle())
                }
                detailRow(icon: "mappin.and.ellipse", text: period.room)
                detailRow(icon: "clock", text: period.time)
                Button {} label: {
                    HStack {
                        Label("\(period.subjectName) assignments", systemImage: "book")
                            .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.chevron)
                    }
                    .padding(14).dashboardCard(radius: 12)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.bottom, 16)
            Spacer(minLength: 0)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
            Text(text).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink900)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    NavigationStack { ClassTimetableView(role: .parent) }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
