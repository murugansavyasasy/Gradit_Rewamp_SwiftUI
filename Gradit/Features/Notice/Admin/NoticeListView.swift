//
//  NoticeListView.swift
//  Gradit
//
//  Admin/faculty notice list: search, filters, status tabs, notice cards with
//  read counts, states. Design: NoticeBoard.pdf p1–4, p14.
//

import SwiftUI

struct NoticeListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(AuthSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: NoticeListViewModel?

    private var subtitle: String {
        session.currentRole == .faculty ? "Dr. Meena Krishnan · CSE" : "Dr. Suresh Kumar · Principal"
    }

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Notice Board"), subtitle: subtitle, showsBack: isPresented) { dismiss() }
            if let model {
                controls(model)
                tabs(model)
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) { createButton }
        .task {
            if model == nil { model = NoticeListViewModel(service: dependencies.noticeService) }
            await model?.load()
        }
    }

    private func controls(_ model: NoticeListViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                TextField(String(localized: "Search by title"), text: $model.searchText).font(AppFont.jakarta(15))
            }
            .padding(.horizontal, 14).frame(height: 46).dashboardCard(radius: 12)
            HStack(spacing: 10) {
                AssignmentDropdown(label: String(localized: "Category"), value: model.category, options: model.categoryOptions) { model.category = $0 }
                AssignmentDropdown(label: String(localized: "Audience"), value: model.audience, options: ["All", "Students", "Parents", "Staff"]) { model.audience = $0 }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                AssignmentDropdown(label: String(localized: "Status"), value: model.tab.title,
                                   options: NoticeListViewModel.Tab.allCases.map(\.title)) { title in
                    if let t = NoticeListViewModel.Tab.allCases.first(where: { $0.title == title }) { model.tab = t }
                }
                Button { model.newestFirst.toggle() } label: {
                    HStack(spacing: 6) {
                        Text(model.newestFirst ? String(localized: "Newest first") : String(localized: "Oldest first"))
                            .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                        Image(systemName: "arrow.up.arrow.down").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
                    }
                    .padding(.horizontal, 12).frame(height: 38).background(Theme.Colors.white, in: Capsule())
                    .overlay(Capsule().strokeBorder(Theme.Colors.border))
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 10)
    }

    private func tabs(_ model: NoticeListViewModel) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach(NoticeListViewModel.Tab.allCases) { tab in
                    let on = model.tab == tab
                    Button { model.tab = tab } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Text("\(model.count(tab))").font(AppFont.jakarta(12, .heavy))
                                    .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                                    .padding(.horizontal, 8).frame(height: 22)
                                    .background(on ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted, in: Capsule())
                                Text(tab.title).font(AppFont.jakarta(15, .bold)).foregroundStyle(on ? Theme.Colors.blue700 : Theme.Colors.ink500)
                            }
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
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func content(_ model: NoticeListViewModel) -> some View {
        if model.isLoading, model.items.isEmpty {
            loadingSkeleton
        } else if let error = model.errorMessage, model.items.isEmpty {
            stateCard(icon: "wifi.exclamationmark", title: String(localized: "Couldn't load your notices"),
                      message: String(localized: "Check your internet connection and try again."), action: String(localized: "Try again")) { model.reload() }
        } else if model.visible.isEmpty {
            stateCard(icon: "megaphone", title: String(localized: "No notices yet"),
                      message: String(localized: "Notices you publish to students, parents and staff will show here with read counts."),
                      action: String(localized: "Create notice")) { router.push(.notice(.create)) }
        } else {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(model.visible) { notice in
                        Button { router.push(.notice(.detail(notice.id))) } label: { card(notice) }
                            .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(16).padding(.bottom, 96)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        }
    }

    private func card(_ notice: NoticeItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text(notice.title).font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                StatusBadge(text: notice.status.title, tone: notice.status.tone, weight: .heavy)
            }
            HStack(spacing: 8) {
                NoticeCategoryChip(category: notice.category)
                if notice.pinned { PinnedChip() }
            }
            metaRow(icon: "person.2", text: notice.audienceText)
            HStack(spacing: 12) {
                metaRow(icon: "calendar", text: notice.dateText)
                if notice.attachmentCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "paperclip").font(.system(size: 11, weight: .bold))
                        Text("\(notice.attachmentCount) attachments").font(AppFont.jakarta(12))
                    }
                    .foregroundStyle(Theme.Colors.ink500)
                }
            }
            if notice.totalCount > 0 {
                HStack {
                    Text("\(notice.readCount) / \(notice.totalCount) read").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
                    Spacer()
                    Text(notice.progressPercentText).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink900)
                }
                progressBar(notice.progress)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func progressBar(_ value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.surfaceMuted)
                Capsule().fill(Theme.Colors.green600).frame(width: max(0, geo.size.width * value))
            }
        }
        .frame(height: 6)
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
            Text(text).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700).lineLimit(2)
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
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16).frame(maxHeight: .infinity, alignment: .top)
    }

    private var createButton: some View {
        Button { router.push(.notice(.create)) } label: {
            Image(systemName: "plus").font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.Colors.white)
                .frame(width: 56, height: 56).background(Theme.Colors.blue600, in: Circle())
                .shadow(color: Theme.Colors.blue600.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(PressableButtonStyle()).padding(20).accessibilityLabel("Create notice")
    }
}

#Preview {
    NavigationStack { NoticeListView() }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
        .environment(AuthSession(service: MockAuthService(latency: .zero), apiClient: APIClient(baseURL: AppConfig.baseURL)))
}
