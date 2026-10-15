//
//  NotificationsView.swift
//  Gradit
//
//  In-app notifications list, opened from the dashboard header bell.
//  Grouped by Today / Yesterday / Earlier with read / unread state.
//

import SwiftUI

struct NotificationsView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: NotificationsViewModel?

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model {
                filterBar(model)
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = NotificationsViewModel(role: role, service: dependencies.notificationService) }
            await model?.load()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(subtitle).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            if let model, model.hasUnread {
                Button { model.markAllRead() } label: {
                    Text("Mark all").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue600)
                        .padding(.horizontal, 12).frame(height: 36).background(Theme.Colors.blue50, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private var subtitle: String {
        guard let model else { return String(localized: "Your recent updates") }
        return model.unreadCount == 0
            ? String(localized: "You're all caught up")
            : String(localized: "\(model.unreadCount) unread")
    }

    private func filterBar(_ model: NotificationsViewModel) -> some View {
        @Bindable var model = model
        return HStack(spacing: 8) {
            ForEach(NotificationsViewModel.Filter.allCases) { filter in
                let on = model.filter == filter
                Button { model.filter = filter } label: {
                    Text(filter.title)
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 16).frame(height: 36)
                        .background(on ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(on ? .clear : Theme.Colors.line))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ model: NotificationsViewModel) -> some View {
        if model.isLoading, !model.isLoaded {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = model.errorMessage, !model.isLoaded {
            errorState(error, model: model)
        } else if model.sections.isEmpty {
            emptyState(model)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(model.sections) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink500)
                            ForEach(section.items) { item in row(model, item: item) }
                        }
                    }
                    PoweredByFooter().padding(.top, 4)
                }
                .padding(16).padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func row(_ model: NotificationsViewModel, item: AppNotification) -> some View {
        Button { model.markRead(item) } label: {
            HStack(alignment: .top, spacing: 12) {
                IconTile(systemImage: item.kind.systemImage, size: 42,
                         foreground: item.kind.foreground, background: item.kind.background)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title).font(AppFont.jakarta(15, item.isRead ? .semibold : .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(item.message).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                        .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
                    Text(NotificationsFormat.relative(item.date)).font(AppFont.jakarta(11, .semibold)).foregroundStyle(Theme.Colors.ink400)
                }
                if !item.isRead {
                    Circle().fill(Theme.Colors.blue600).frame(width: 9, height: 9).padding(.top, 5)
                }
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(radius: 16, background: item.isRead ? Theme.Colors.white : Theme.Colors.blue50,
                           border: item.isRead ? Theme.Colors.line : Theme.Colors.blue100)
        }
        .buttonStyle(.plain)
    }

    private func emptyState(_ model: NotificationsViewModel) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "bell.slash", size: 64, radius: 20, foreground: Theme.Colors.ink500, background: Theme.Colors.surfaceMuted)
            Text(model.filter == .unread ? "No unread notifications" : "No notifications yet")
                .font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("We'll let you know when something needs your attention.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16).frame(maxHeight: .infinity, alignment: .top)
    }

    private func errorState(_ error: String, model: NotificationsViewModel) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "wifi.exclamationmark", size: 64, radius: 20, foreground: Theme.Colors.destructive, background: Theme.Colors.errorBackground)
            Text("Couldn't load notifications").font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(error).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            Button("Try again") { model.reload() }.font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                .padding(.horizontal, 20).frame(height: 48).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12)).buttonStyle(PressableButtonStyle())
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16).frame(maxHeight: .infinity, alignment: .top)
    }
}

/// Relative time label for a notification ("Just now", "2h ago", "3d ago").
enum NotificationsFormat {
    static func relative(_ date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return String(localized: "Just now") }
        if seconds < 3600 { return String(localized: "\(Int(seconds / 60))m ago") }
        if seconds < 86_400 { return String(localized: "\(Int(seconds / 3600))h ago") }
        let days = Int(seconds / 86_400)
        if days < 7 { return String(localized: "\(days)d ago") }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

#Preview("Student") {
    NavigationStack { NotificationsView(role: .student) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}

#Preview("Faculty") {
    NavigationStack { NotificationsView(role: .faculty) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
