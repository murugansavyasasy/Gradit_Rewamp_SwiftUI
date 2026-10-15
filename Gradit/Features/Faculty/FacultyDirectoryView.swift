//
//  FacultyDirectoryView.swift
//  Gradit
//
//  Staff faculty directory: stats, stream/department filters, By department /
//  By division / All faculty segments, grouped lists and export.
//  Design: facultyModul.pdf p1–10, p16–19.
//

import SwiftUI

struct FacultyDirectoryView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: FacultyDirectoryViewModel?
    @State private var sheet: Sheet?

    private enum Sheet: Identifiable {
        case stream, department, summary(String), export
        var id: String {
            switch self {
            case .stream: "stream"
            case .department: "department"
            case .summary(let d): "summary-\(d)"
            case .export: "export"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model {
                if let directory = model.directory {
                    content(model, directory: directory)
                } else if model.errorMessage != nil {
                    errorState(model)
                } else {
                    loadingSkeleton
                }
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = FacultyDirectoryViewModel(service: dependencies.facultyService) }
            if model?.directory == nil { await model?.load() }
        }
        .sheet(item: $sheet) { which in sheetContent(which) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Faculty").font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("UCE Chennai · 102 teaching staff").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            Button { sheet = .export } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(width: 40, height: 40).dashboardCard(radius: 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Export faculty list")
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    // MARK: - Content

    private func content(_ model: FacultyDirectoryViewModel, directory: FacultyDirectory) -> some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                statCards(directory)
                searchField($model)
                filterCard(model)
                if model.hasActiveFilters { activeChips(model) }
                Text(directory.summaryText)
                    .font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                segmentedControl(model)
                listContent(model)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable { model.reload() }
    }

    private func statCards(_ directory: FacultyDirectory) -> some View {
        HStack(spacing: 10) {
            statCard("\(directory.totalFaculty)", "Faculty", Theme.Colors.ink900, Theme.Colors.white)
            statCard("\(directory.present)", "Present", Theme.Colors.green700, Theme.Colors.green50)
            statCard("\(directory.absentLeave)", "Absent /\nleave", Theme.Colors.destructive, Theme.Colors.errorBackground)
            Button { router.push(.faculty(.freePeriods)) } label: {
                VStack(spacing: 3) {
                    HStack(spacing: 2) {
                        Text("\(directory.freePeriods)").font(AppFont.jakarta(22, .heavy))
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .heavy))
                    }
                    Text("Free\nperiods").font(AppFont.jakarta(11, .bold)).multilineTextAlignment(.center).lineLimit(2)
                }
                .foregroundStyle(Theme.Colors.amber800)
                .frame(maxWidth: .infinity).frame(height: 72)
                .background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.amberBorder))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private func statCard(_ value: String, _ label: String, _ fg: Color, _ bg: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(AppFont.jakarta(22, .heavy)).foregroundStyle(fg)
            Text(label).font(AppFont.jakarta(11, .bold)).foregroundStyle(fg)
                .multilineTextAlignment(.center).lineLimit(2)
        }
        .frame(maxWidth: .infinity).frame(height: 72)
        .background(bg, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.line))
    }

    private func searchField(_ model: Bindable<FacultyDirectoryViewModel>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
            TextField(String(localized: "Search name, subject or employee ID"), text: model.searchText)
                .font(AppFont.jakarta(15))
        }
        .padding(.horizontal, 14).frame(height: 46)
        .dashboardCard(radius: 12)
    }

    // MARK: - Filter card

    private func filterCard(_ model: FacultyDirectoryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            stepRow(number: "1", active: true, label: String(localized: "Stream / institution"),
                    value: model.streamName) { sheet = .stream }

            if model.stream == nil {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle").font(.system(size: 11, weight: .semibold))
                    Text("Choose a stream to filter by department.").font(AppFont.jakarta(12))
                }
                .foregroundStyle(Theme.Colors.ink500)
            } else {
                stepRow(number: "2", active: true, label: String(localized: "Department · one or more"),
                        value: model.departments.isEmpty ? String(localized: "All departments") : model.departments.joined(separator: ", ")) {
                    sheet = .department
                }
            }

            HStack(spacing: 10) {
                stepBadge("3", active: false)
                AssignmentDropdown(label: String(localized: "Year / Sem"), value: model.yearSem,
                                   options: ["All", "Year 1", "Year 2", "Year 3"]) { model.yearSem = $0 }
                AssignmentDropdown(label: String(localized: "Division"), value: model.division,
                                   options: ["All", "A", "B", "C"]) { model.division = $0 }
            }
            Text("Optional").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                .padding(.leading, 34)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    private func stepRow(number: String, active: Bool, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                stepBadge(number, active: active)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    Text(value).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900).lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
            }
            .padding(12)
            .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.blueBorderLight))
        }
        .buttonStyle(.plain)
    }

    private func stepBadge(_ number: String, active: Bool) -> some View {
        Text(number)
            .font(AppFont.jakarta(13, .heavy))
            .foregroundStyle(active ? Theme.Colors.white : Theme.Colors.ink700)
            .frame(width: 26, height: 26)
            .background(active ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted, in: Circle())
            .overlay(Circle().strokeBorder(active ? .clear : Theme.Colors.border))
    }

    private func activeChips(_ model: FacultyDirectoryViewModel) -> some View {
        FlowLayout(spacing: 8) {
            if let stream = model.stream { filterChip(stream) { model.apply(stream: nil) } }
            ForEach(model.departments, id: \.self) { dept in
                filterChip(dept) { model.apply(departments: model.departments.filter { $0 != dept }) }
            }
            Button("Reset all") { model.resetAll() }
                .font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.destructive)
                .underline()
                .buttonStyle(.plain)
        }
    }

    private func filterChip(_ text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(text).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue700)
            Button(action: onRemove) {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.Colors.blue700)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 12).padding(.trailing, 10).frame(height: 34)
        .background(Theme.Colors.blue50, in: Capsule())
    }

    private func segmentedControl(_ model: FacultyDirectoryViewModel) -> some View {
        HStack(spacing: 4) {
            ForEach(FacultyDirectoryViewModel.Segment.allCases) { segment in
                let isOn = model.segment == segment
                Button(segment.title) { model.segment = segment }
                    .font(AppFont.jakarta(14, isOn ? .bold : .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.ink900 : Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                    .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
                    .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.line))
    }

    // MARK: - Lists

    @ViewBuilder
    private func listContent(_ model: FacultyDirectoryViewModel) -> some View {
        if model.isEmpty {
            emptyState
        } else {
            switch model.segment {
            case .byDepartment:
                ForEach(model.visibleDepartmentGroups) { group in departmentCard(group) }
            case .byDivision:
                ForEach(model.visibleDivisionGroups) { group in divisionCard(group) }
            case .allFaculty:
                VStack(spacing: 0) {
                    ForEach(Array(model.visibleAllFaculty.enumerated()), id: \.element.id) { index, member in
                        if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                        memberButton(member)
                    }
                }
                .dashboardCard(radius: 16)
            }
        }
    }

    private func departmentCard(_ group: FacultyDeptGroup) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(group.department).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Button { sheet = .summary(group.department) } label: {
                            HStack(spacing: 2) {
                                Text("Summary").font(AppFont.jakarta(13, .bold))
                                Image(systemName: "chevron.right").font(.system(size: 9, weight: .heavy))
                            }
                            .foregroundStyle(Theme.Colors.blue600)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("\(group.total) faculty · \(group.presentToday) present today")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            VStack(spacing: 0) {
                ForEach(Array(group.members.enumerated()), id: \.element.id) { index, member in
                    if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                    memberButton(member)
                }
            }
        }
        .dashboardCard(radius: 16)
    }

    private func divisionCard(_ group: FacultyDivisionGroup) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.divisionLabel).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("Class teacher: \(group.classTeacher) · \(group.total) faculty")
                    .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            VStack(spacing: 0) {
                ForEach(Array(group.members.enumerated()), id: \.element.id) { index, member in
                    if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                    memberButton(member)
                }
            }
        }
        .dashboardCard(radius: 16)
    }

    private func memberButton(_ member: FacultyMember) -> some View {
        Button {
            router.push(.faculty(.profile(member.name.contains("Vignesh") ? "vignesh" : member.id)))
        } label: {
            FacultyMemberRow(member: member)
        }
        .buttonStyle(.plain)
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "person.2.slash", size: 56, radius: 18)
            Text("No faculty found for these filters")
                .font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .multilineTextAlignment(.center)
            Text("Try a different stream, department or search.")
                .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18)
    }

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14).fill(Theme.Colors.surfaceMuted).frame(height: 72)
                RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.surfaceMuted).frame(height: 120)
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 120)
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Colors.line))
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .redacted(reason: .placeholder)
    }

    private func errorState(_ model: FacultyDirectoryViewModel) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "wifi.exclamationmark", size: 64, radius: 20,
                     foreground: Theme.Colors.destructive, background: Theme.Colors.errorBackground)
            Text("Couldn't load the faculty list").font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("Check your internet connection and try again.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            Button { model.reload() } label: {
                Label("Try again", systemImage: "arrow.clockwise")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 20).frame(height: 48)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18)
        .padding(16).frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Sheets

    @ViewBuilder
    private func sheetContent(_ which: Sheet) -> some View {
        switch which {
        case .stream:
            if let model { StreamSheet(model: model, service: dependencies.facultyService).presentationDetents([.medium, .large]) }
        case .department:
            if let model { DepartmentSheet(model: model, service: dependencies.facultyService).presentationDetents([.large]) }
        case .summary(let dept):
            DepartmentSummarySheet(department: dept, service: dependencies.facultyService)
                .presentationDetents([.medium, .large])
        case .export:
            ExportFacultySheet(filterSummary: model?.directory?.summaryText ?? "", count: model?.directory?.totalFaculty ?? 0)
                .presentationDetents([.large])
        }
    }
}

#Preview {
    NavigationStack { FacultyDirectoryView() }
        .environment(AppRouter())
        .environment(AppDependencies(
            apiClient: APIClient(baseURL: AppConfig.baseURL),
            userService: MockUserService(), authService: MockAuthService(latency: .zero),
            dashboardService: MockDashboardService(latency: .zero), profileService: MockProfileService(latency: .zero),
            discussionService: MockDiscussionService(latency: .zero), messagingService: MockMessagingService(latency: .zero),
            attendanceService: MockAttendanceService(latency: .zero), assignmentService: MockAssignmentService(latency: .zero),
            facultyService: MockFacultyService(latency: .zero)))
}
