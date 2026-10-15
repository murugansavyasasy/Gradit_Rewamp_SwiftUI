//
//  ExamApplicationListView.swift
//  Gradit
//
//  Student / parent exam application list: alert, Open/Applied/Closed tabs,
//  filters, cards. Design: examAplication.pdf p1–8.
//

import SwiftUI

struct ExamApplicationListView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: ExamListViewModel?

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
            if model == nil { model = ExamListViewModel(role: role, service: dependencies.examService) }
            await model?.load()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Exam Application Details").font(AppFont.jakarta(19, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(model?.isParent == true ? "\(childName) · from the exam cell" : "from the exam cell")
                    .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private var childName: String {
        model?.children.first { $0.id == model?.selectedChildID }?.name ?? ""
    }

    private func childSwitcher(_ model: ExamListViewModel) -> some View {
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
    private func content(_ model: ExamListViewModel) -> some View {
        if model.isLoading, model.bundle == nil {
            loadingSkeleton
        } else if let error = model.errorMessage, model.bundle == nil {
            stateCard(icon: "wifi.exclamationmark", title: String(localized: "Couldn't load exam applications"),
                      message: String(localized: "Check your internet connection and try again."), action: String(localized: "Try again")) { model.reload() }
        } else {
            VStack(spacing: 0) {
                if let alert = model.alert { alertBanner(alert) }
                tabs(model)
                controls(model)
                listOrEmpty(model)
            }
        }
    }

    private func alertBanner(_ alert: ExamAlert) -> some View {
        Button { if let id = alert.examID { router.push(.exam(.detail(id: id, childID: model?.selectedChildID))) } } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.amber800)
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.amber800)
                    Text(alert.message).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.amber800).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.amber800)
            }
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    private func tabs(_ model: ExamListViewModel) -> some View {
        HStack(spacing: 0) {
            ForEach(ExamListViewModel.Tab.allCases) { tab in
                let on = model.tab == tab
                Button { model.tab = tab } label: {
                    VStack(spacing: 4) {
                        Text("\(model.count(tab))").font(AppFont.jakarta(13, .heavy))
                            .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                            .frame(width: 24, height: 24).background(on ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted, in: Circle())
                        Text(tab.title).font(AppFont.jakarta(13, .bold)).foregroundStyle(on ? Theme.Colors.blue700 : Theme.Colors.ink500)
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

    private func controls(_ model: ExamListViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                TextField(String(localized: "Search exam or subject code"), text: $model.searchText).font(AppFont.jakarta(15))
            }
            .padding(.horizontal, 14).frame(height: 46).dashboardCard(radius: 12)
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    AssignmentDropdown(label: String(localized: "Semester"), value: model.semester, options: ["All", "Sem 3", "Sem 4", "Sem 5"]) { model.semester = $0 }
                    AssignmentDropdown(label: String(localized: "Exam type"), value: model.examType, options: model.examTypeOptions) { model.examType = $0 }
                    AssignmentDropdown(label: String(localized: "Academic year"), value: "All", options: ["All", "2026–27", "2025–26"]) { _ in }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(16)
    }

    @ViewBuilder
    private func listOrEmpty(_ model: ExamListViewModel) -> some View {
        if model.visible.isEmpty {
            VStack(spacing: 10) {
                IconTile(systemImage: "doc.badge.plus", size: 56, radius: 18)
                Text("No exam applications right now").font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900).multilineTextAlignment(.center)
                Text("No application windows are open for \(childName.isEmpty ? "you" : childName). The exam cell will notify you when one opens.")
                    .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            }
            .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(.horizontal, 16)
            Spacer(minLength: 0)
        } else {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(model.visible) { item in
                        Button { router.push(.exam(.detail(id: item.id, childID: model.selectedChildID))) } label: { card(item) }
                            .buttonStyle(PressableButtonStyle())
                    }
                    footerNote
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func card(_ item: ExamApplicationItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Text(item.title).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                StatusBadge(text: item.type.title, tone: item.type.tone, weight: .bold)
            }
            Text(item.semesterLine).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            HStack(spacing: 6) {
                Image(systemName: "calendar").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                Text(item.datesLine).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink700)
            }
            HStack(spacing: 8) {
                if item.closed {
                    pill(icon: "nosign", text: "Closed", color: Theme.Colors.ink500, bg: Theme.Colors.surfaceMuted)
                } else if let days = item.daysLeftText {
                    pill(icon: "clock", text: days, color: Theme.Colors.blue700, bg: Theme.Colors.blue50)
                }
                StatusBadge(text: item.status.title, tone: item.status.tone, systemImage: item.status.systemImage, weight: .heavy)
                Spacer(minLength: 0)
                Text(item.amountText).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func pill(icon: String, text: String, color: Color, bg: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .heavy))
            Text(text).font(AppFont.jakarta(12, .bold))
        }
        .foregroundStyle(color).padding(.horizontal, 9).padding(.vertical, 3).background(bg, in: Capsule())
    }

    private var footerNote: some View {
        VStack(spacing: 10) {
            Text("* Applications are made and paid on the college web portal. This app shows the details the exam cell uploads.")
                .font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            PoweredByFooter()
        }
        .padding(.top, 8)
    }

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 110)
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
            Text(title).font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
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

#Preview {
    NavigationStack { ExamApplicationListView(role: .student) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
