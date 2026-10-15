//
//  ReaderNoticeListView.swift
//  Gradit
//
//  Student / parent notice board reader: filter chips, pinned/today/earlier
//  sections, notice cards, states. Design: NoticeBoard.pdf p17–21, p25.
//

import SwiftUI

struct ReaderNoticeListView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: ReaderNoticeListViewModel?

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model {
                searchField(model)
                filterChips(model)
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = ReaderNoticeListViewModel(role: role, service: dependencies.noticeService) }
            await model?.load()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Notice Board").font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("\(model?.unreadCount ?? 0) unread · UCE Chennai").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func searchField(_ model: ReaderNoticeListViewModel) -> some View {
        @Bindable var model = model
        return HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
            TextField(String(localized: "Search notices"), text: $model.searchText).font(AppFont.jakarta(15))
        }
        .padding(.horizontal, 14).frame(height: 46).dashboardCard(radius: 12)
        .padding(.horizontal, 16).padding(.bottom, 10)
    }

    private func filterChips(_ model: ReaderNoticeListViewModel) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(model.filters) { filter in
                    let on = model.filter == filter
                    Button { model.filter = filter } label: {
                        HStack(spacing: 5) {
                            Text(filter.title).font(AppFont.jakarta(14, .bold))
                            if let count = model.count(filter) {
                                Text("\(count)").font(AppFont.jakarta(12, .heavy))
                                    .foregroundStyle(on ? Theme.Colors.blue600 : Theme.Colors.white)
                                    .padding(.horizontal, 6).frame(minHeight: 18)
                                    .background(on ? Theme.Colors.white : Theme.Colors.blue600, in: Capsule())
                            }
                        }
                        .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 14).frame(height: 36)
                        .background(on ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(on ? .clear : Theme.Colors.border))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden).padding(.bottom, 10)
    }

    @ViewBuilder
    private func content(_ model: ReaderNoticeListViewModel) -> some View {
        if model.isLoading, model.items.isEmpty {
            loadingSkeleton
        } else if let error = model.errorMessage, model.items.isEmpty {
            stateCard(icon: "wifi.exclamationmark", title: String(localized: "Couldn't load notices"),
                      message: String(localized: "Check your internet connection and try again."), action: String(localized: "Try again")) { model.reload() }
        } else if model.visible.isEmpty {
            stateCard(icon: "megaphone", title: emptyTitle(model),
                      message: String(localized: "You've read everything. New notices from your college will show here."), action: nil, perform: nil)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(model.sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            sectionHeader(section.title)
                            ForEach(section.notices) { notice in
                                Button {
                                    model.markRead(notice)
                                    router.push(.notice(.readerDetail(notice.id)))
                                } label: { card(notice) }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                        .padding(section.title == "PINNED" ? 10 : 0)
                        .background(section.title == "PINNED" ? Theme.Colors.blue50 : .clear, in: .rect(cornerRadius: 16))
                    }
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func emptyTitle(_ model: ReaderNoticeListViewModel) -> String {
        model.filter == .unread ? String(localized: "No unread notices") : String(localized: "No notices yet")
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        if title == "PINNED" {
            HStack(spacing: 5) {
                Image(systemName: "mappin").font(.system(size: 11, weight: .heavy))
                Text("PINNED").font(AppFont.jakarta(12, .heavy))
            }
            .foregroundStyle(Theme.Colors.blue700)
        } else {
            Text(title).font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.ink500)
        }
    }

    private func card(_ notice: ReaderNotice) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                NoticeCategoryChip(category: notice.category)
                if notice.pinned { PinnedChip() }
                if notice.isExpired { StatusBadge(text: "Expired", tone: .neutral, weight: .heavy) }
                Spacer(minLength: 0)
                if notice.isNew, notice.isUnread {
                    HStack(spacing: 4) {
                        Circle().fill(Theme.Colors.blue600).frame(width: 7, height: 7)
                        Text("New").font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.blue600)
                    }
                }
            }
            Text(notice.title).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .fixedSize(horizontal: false, vertical: true)
            Text(notice.preview).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).lineLimit(2)
            HStack(spacing: 10) {
                NoticeAuthorRow(name: notice.authorName, role: notice.authorRole, time: notice.timeText)
                if notice.attachmentCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "paperclip").font(.system(size: 11, weight: .bold))
                        Text("\(notice.attachmentCount)").font(AppFont.jakarta(12, .bold))
                    }
                    .foregroundStyle(Theme.Colors.ink500)
                }
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16, border: notice.isUnread ? Theme.Colors.blueBorderLight : Theme.Colors.line,
                       borderWidth: notice.isUnread ? 1.5 : 1)
    }

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 120)
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
            Text(title).font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
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

#Preview {
    NavigationStack { ReaderNoticeListView(role: .student) }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
