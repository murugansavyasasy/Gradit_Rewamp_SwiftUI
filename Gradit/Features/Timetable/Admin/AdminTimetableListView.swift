//
//  AdminTimetableListView.swift
//  Gradit
//
//  Management timetable list: search, filters, class cards, states. Design: timetableModule.pdf p1–4.
//

import SwiftUI

struct AdminTimetableListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: AdminTimetableListViewModel?

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model {
                controls(model)
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) { createButton }
        .task {
            if model == nil { model = AdminTimetableListViewModel(service: dependencies.timetableService) }
            await model?.load()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Timetable").font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("Odd semester 2026–27").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            ZStack(alignment: .topTrailing) {
                Image(systemName: "person.2").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink700).frame(width: 40, height: 40).dashboardCard(radius: 12)
                CountBubble(count: 3).scaleEffect(0.7).offset(x: 8, y: -6)
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func controls(_ model: AdminTimetableListViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                TextField(String(localized: "Search class or section"), text: $model.searchText).font(AppFont.jakarta(15))
            }
            .padding(.horizontal, 14).frame(height: 46).dashboardCard(radius: 12)
            HStack(spacing: 10) {
                AssignmentDropdown(label: String(localized: "Course"), value: model.course, options: ["All", "B.E. CSE", "B.Tech IT", "B.E. ECE"]) { model.course = $0 }
                AssignmentDropdown(label: String(localized: "Year / Sem"), value: model.yearSem, options: ["All", "Sem 3", "Sem 5", "Sem 7"]) { model.yearSem = $0 }
                Spacer(minLength: 0)
            }
            HStack {
                AssignmentDropdown(label: String(localized: "Section"), value: model.section, options: ["All", "A", "B", "C"]) { model.section = $0 }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 10)
    }

    @ViewBuilder
    private func content(_ model: AdminTimetableListViewModel) -> some View {
        if model.isLoading, model.items.isEmpty {
            loadingSkeleton
        } else if let error = model.errorMessage, model.items.isEmpty {
            stateCard(icon: "wifi.exclamationmark", title: String(localized: "Couldn't load timetables"),
                      message: String(localized: "Check your internet connection and try again."),
                      action: String(localized: "Try again")) { model.reload() }
        } else if model.visible.isEmpty {
            stateCard(icon: "square.grid.2x2", title: String(localized: "No timetables yet"),
                      message: String(localized: "Create a class timetable. Students, parents and faculty see it as soon as you publish."),
                      action: String(localized: "Create timetable")) { router.push(.timetable(.setup)) }
        } else {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(model.visible) { item in
                        Button { router.push(.timetable(.editor(item.id))) } label: { card(item) }
                            .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(16).padding(.bottom, 96)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func card(_ item: TimetableSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                IconTile(systemImage: "square.grid.2x2", size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.classLabel).font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(item.term).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                StatusBadge(text: item.status.title, tone: item.status == .published ? .green : .neutral,
                            systemImage: item.status == .published ? "checkmark" : "pencil", weight: .heavy)
            }
            metaRow(icon: "clock", text: "\(item.periodsPerWeek) periods / week")
            metaRow(icon: "pencil", text: item.updatedText)
            if let issues = item.issuesText {
                Text(issues).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.amber800)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
            Text(text).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
        }
    }

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 128)
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Colors.line))
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden).redacted(reason: .placeholder)
    }

    private func stateCard(icon: String, title: String, message: String, action: String, perform: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: icon, size: 64, radius: 20,
                     foreground: icon.contains("wifi") ? Theme.Colors.destructive : Theme.Colors.blue600,
                     background: icon.contains("wifi") ? Theme.Colors.errorBackground : Theme.Colors.blue50)
            Text(title).font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(message).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            Button(action: perform) {
                Label(action, systemImage: icon.contains("wifi") ? "arrow.clockwise" : "plus")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 20).frame(height: 48).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle()).padding(.top, 4)
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18)
        .padding(16).frame(maxHeight: .infinity, alignment: .top)
    }

    private var createButton: some View {
        Button { router.push(.timetable(.setup)) } label: {
            Image(systemName: "plus").font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.Colors.white)
                .frame(width: 56, height: 56).background(Theme.Colors.blue600, in: Circle())
                .shadow(color: Theme.Colors.blue600.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(PressableButtonStyle()).padding(20).accessibilityLabel("Create timetable")
    }
}

#Preview {
    NavigationStack { AdminTimetableListView() }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
