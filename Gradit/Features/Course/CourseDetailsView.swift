//
//  CourseDetailsView.swift
//  Gradit
//
//  Student / parent Course Details: program card, stats, semester progress and
//  Overview / Subjects / Syllabus / Faculty tabs. Design: courseDetails.pdf.
//

import SwiftUI

struct CourseDetailsView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: CourseDetailsViewModel?
    @State private var facultySheet: CourseFacultyItem?
    @State private var syllabusDoc: SyllabusDoc?

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
            if model == nil { model = CourseDetailsViewModel(role: role, service: dependencies.courseService) }
            await model?.load()
        }
        .sheet(item: $facultySheet) { item in FacultyQuickSheet(item: item).presentationDetents([.medium]) }
        .sheet(item: $syllabusDoc) { doc in SyllabusViewerSheet(doc: doc) }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Course Details").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                if let o = model?.overview {
                    Text("\(o.studentName) · \(shortProgram(o.programName))").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func shortProgram(_ name: String) -> String {
        name.contains("Information") ? "B.Tech IT" : "B.E. CSE"
    }

    private func childSwitcher(_ model: CourseDetailsViewModel) -> some View {
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
    private func content(_ model: CourseDetailsViewModel) -> some View {
        if model.isLoading, model.bundle == nil {
            loadingSkeleton
        } else if let error = model.errorMessage, model.bundle == nil {
            stateCard(icon: "wifi.exclamationmark", title: String(localized: "Couldn't load course details"),
                      message: String(localized: "Check your internet connection and try again."), action: String(localized: "Try again")) { model.reload() }
        } else if let overview = model.overview {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    programBanner(overview, condensed: model.tab != .overview)
                    tabBar(model)
                    switch model.tab {
                    case .overview: overviewTab(overview)
                    case .subjects: subjectsTab(model)
                    case .syllabus: syllabusTab(model)
                    case .faculty: facultyTab(model)
                    }
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable { model.reload() }
        } else {
            stateCard(icon: "book.closed", title: String(localized: "Course details are not available yet"),
                      message: String(localized: "The college hasn't published the course details yet. They'll appear here when the web portal is updated."), action: nil, perform: nil)
        }
    }

    // MARK: - Program banner

    private func programBanner(_ o: CourseOverview, condensed: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "graduationcap.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(width: 42, height: 42).background(Theme.Colors.white.opacity(0.18), in: .rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(o.programName).font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(condensed ? "\(o.yearSemester) · \(o.division) · \(o.completedCount) of \(o.totalSemesters) completed"
                                   : "\(o.studentName) · Reg. no. \(o.regNo)")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.white.opacity(0.85))
                }
                Spacer(minLength: 0)
            }
            if !condensed {
                VStack(spacing: 10) {
                    HStack(spacing: 10) { bannerField("Stream", o.stream); bannerField("Department", o.department) }
                    HStack(spacing: 10) { bannerField("Academic year", o.academicYear); bannerField("Year and semester", o.yearSemester) }
                    HStack(spacing: 10) { bannerField("Division", o.division); bannerField("Duration", o.duration) }
                }
                .padding(14).background(Theme.Colors.white, in: .rect(cornerRadius: 14))
                Text(o.regulation).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.white.opacity(0.85))
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.blue700, in: .rect(cornerRadius: 18))
    }

    private func bannerField(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tabBar(_ model: CourseDetailsViewModel) -> some View {
        HStack(spacing: 2) {
            ForEach(CourseDetailsViewModel.Tab.allCases) { tab in
                let on = model.tab == tab
                Button { model.tab = tab } label: {
                    VStack(spacing: 6) {
                        Text(tab.title).font(AppFont.jakarta(14, on ? .heavy : .semibold))
                            .foregroundStyle(on ? Theme.Colors.blue700 : Theme.Colors.ink500)
                        Rectangle().fill(on ? Theme.Colors.blue600 : .clear).frame(height: 2)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 4).contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
    }

    // MARK: - Overview tab

    private func overviewTab(_ o: CourseOverview) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                statCard(value: "\(o.totalCredits)", label: "Total credits", note: "For the whole course", valueColor: Theme.Colors.ink900)
                statCard(value: "\(o.creditsEarned)", label: "Credits earned", note: o.creditsEarnedNote, valueColor: Theme.Colors.green700)
            }
            HStack(spacing: 10) {
                statCard(value: "\(o.subjectsThisSemester)", label: "Subjects this semester", note: o.subjectsNote, valueColor: Theme.Colors.ink900)
                statCard(value: nil, label: "Class teacher", note: o.classTeacherSem, big: o.classTeacher, valueColor: Theme.Colors.ink900)
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Semester progress").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Spacer()
                    Text("\(o.completedCount) of \(o.totalSemesters) completed").font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(o.semesters) { semesterCell($0) }
                }
            }
        }
    }

    private func statCard(value: String?, label: LocalizedStringKey, note: String, big: String? = nil, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let value { Text(value).font(AppFont.jakarta(26, .heavy)).foregroundStyle(valueColor) }
            else if let big { Text(big).font(AppFont.jakarta(15, .heavy)).foregroundStyle(valueColor).fixedSize(horizontal: false, vertical: true) }
            Text(label).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink700)
            Text(note).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
        }
        .frame(maxWidth: .infinity, alignment: .leading).frame(minHeight: 92, alignment: .top)
        .padding(14).dashboardCard(radius: 16)
    }

    private func semesterCell(_ s: SemesterProgress) -> some View {
        let (fg, bg): (Color, Color) = switch s.status {
        case .completed: (Theme.Colors.green700, Theme.Colors.green50)
        case .current: (Theme.Colors.white, Theme.Colors.blue600)
        case .upcoming: (Theme.Colors.ink500, Theme.Colors.surfaceMuted)
        }
        return VStack(spacing: 4) {
            Text(s.label).font(AppFont.jakarta(13, .heavy))
            HStack(spacing: 2) {
                Image(systemName: s.status.systemImage).font(.system(size: 8, weight: .heavy))
                Text(s.status.title).font(AppFont.jakarta(9, .bold))
            }
        }
        .foregroundStyle(fg).frame(maxWidth: .infinity).frame(height: 56)
        .background(bg, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(s.status == .completed ? Theme.Colors.green100 : .clear))
    }

    // MARK: - Subjects tab

    private func subjectsTab(_ model: CourseDetailsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            semesterChips(model)
            if let block = model.currentBlock {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(block.label).font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text(block.term).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                    Spacer()
                    StatusBadge(text: block.status.title, tone: block.status == .completed ? .green : (block.status == .current ? .blueSoft : .amber), weight: .heavy)
                }
                if let warning = block.electiveWarning { electiveWarningCard(warning) }
                ForEach(block.subjects) { subject in
                    Button { router.push(.course(.subject(childID: model.selectedChildID, code: subject.code, semester: block.semester))) } label: {
                        subjectCard(subject)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private func semesterChips(_ model: CourseDetailsViewModel) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            ForEach(model.semesters) { block in
                let on = model.selectedSemester == block.semester
                Button { model.selectedSemester = block.semester } label: {
                    VStack(spacing: 2) {
                        Text("Sem \(block.semester)").font(AppFont.jakarta(13, .heavy))
                        Text(block.status.title).font(AppFont.jakarta(9, .bold))
                    }
                    .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(on ? Theme.Colors.blue600 : Theme.Colors.white, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(on ? .clear : Theme.Colors.line))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func electiveWarningCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.amber800)
            VStack(alignment: .leading, spacing: 2) {
                Text("Elective not selected").font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.amber800)
                Text(text).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.amber800).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 12))
    }

    private func subjectCard(_ s: CourseSubject) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(s.code).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
                Spacer()
                StatusBadge(text: s.type.title, tone: s.type == .elective ? .amber : .blueSoft, weight: .bold)
            }
            Text(s.name).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Text("\(s.credits) credits").font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink700)
                Text("Marks \(s.intMarks) / \(s.extMarks)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                HStack(spacing: 4) {
                    Image(systemName: "person").font(.system(size: 10, weight: .bold))
                    Text(s.teacher ?? String(localized: "To be assigned")).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
                }
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    // MARK: - Syllabus tab

    private func syllabusTab(_ model: CourseDetailsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Syllabus documents").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Text(model.overview?.regulation.replacingOccurrences(of: " · ", with: "\n") ?? "")
                    .font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.trailing)
            }
            VStack(spacing: 0) {
                ForEach(Array((model.bundle?.syllabus ?? []).enumerated()), id: \.element.id) { index, doc in
                    if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                    syllabusRow(doc)
                }
            }
            .dashboardCard(radius: 16)
        }
    }

    private func syllabusRow(_ doc: SyllabusDoc) -> some View {
        HStack(spacing: 12) {
            FileKindTile(kind: .pdf, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.semesterLabel).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(doc.uploaded ? doc.meta : String(localized: "Syllabus not uploaded")).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            if doc.uploaded {
                Button("View") { syllabusDoc = doc }
                    .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue600)
                    .padding(.horizontal, 14).frame(height: 36).overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.Colors.border))
                Button {} label: {
                    Image(systemName: "arrow.down.to.line").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.Colors.white)
                        .frame(width: 36, height: 36).background(Theme.Colors.blue600, in: .rect(cornerRadius: 10))
                }.buttonStyle(.plain)
            } else {
                StatusBadge(text: "Not uploaded", tone: .neutral, weight: .heavy)
            }
        }
        .padding(12)
    }

    // MARK: - Faculty tab

    private func facultyTab(_ model: CourseDetailsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let block = model.currentBlock {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(block.label) faculty").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("\(block.subjects.count) subjects · \(block.faculty.count) faculty · \(block.term.components(separatedBy: " · ").first ?? "")")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                ForEach(block.faculty) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(item.subjectCode) · \(item.subjectName)").font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
                        Button { facultySheet = item } label: { facultyRow(item) }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func facultyRow(_ item: CourseFacultyItem) -> some View {
        HStack(spacing: 12) {
            InitialsAvatar(initials: DashboardGreeting.initials(item.teacherName), size: 42,
                           foreground: Theme.Colors.blue700, background: Theme.Colors.blue100)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.teacherName).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(item.designation).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                Text(item.subjectName).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.blue600)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.chevron)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    // MARK: - States

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 18).fill(Theme.Colors.ink300.opacity(0.3)).frame(height: 160)
                HStack(spacing: 10) { ForEach(0..<2, id: \.self) { _ in RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 92) } }
                HStack(spacing: 10) { ForEach(0..<2, id: \.self) { _ in RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.white).frame(height: 92) } }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden).redacted(reason: .placeholder)
    }

    private func stateCard(icon: String, title: String, message: String, action: String?, perform: (() -> Void)?) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: icon, size: 56, radius: 18,
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
            PoweredByFooter().padding(.top, 4)
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16).frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Faculty quick sheet

private struct FacultyQuickSheet: View {
    let item: CourseFacultyItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    InitialsAvatar(initials: DashboardGreeting.initials(item.teacherName), size: 48,
                                   foreground: Theme.Colors.blue700, background: Theme.Colors.blue100)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.teacherName).font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text(item.designation).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 36, height: 36).background(Theme.Colors.surfaceMuted, in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(20)
            VStack(spacing: 0) {
                infoRow("Teaches", item.subjectName)
                divider; infoRow("Qualification", "Ph.D., M.E. (CSE)")
                divider; infoRow("Experience", "18 years")
                divider; infoRow("Cabin", "Cabin B-210")
                divider; infoRow("Meeting hours", "Thu, 03:05 – 03:55 PM")
            }
            .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14)).padding(.horizontal, 20)
            HStack(spacing: 12) {
                Button {} label: {
                    Label("Message", systemImage: "bubble.left").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
                        .frame(maxWidth: .infinity, minHeight: 50).background(Theme.Colors.blue50, in: .rect(cornerRadius: 12))
                }.buttonStyle(PressableButtonStyle())
                Button {} label: {
                    Text("Open in Faculty").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 50).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }.buttonStyle(PressableButtonStyle())
            }
            .padding(20)
            Spacer(minLength: 0)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private var divider: some View { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
    private func infoRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).frame(width: 110, alignment: .leading)
            Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
    }
}

// MARK: - Syllabus viewer

private struct SyllabusViewerSheet: View {
    let doc: SyllabusDoc
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.semesterLabel).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.white).lineLimit(1)
                    Text(doc.meta).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.white.opacity(0.8))
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(width: 36, height: 36).background(Theme.Colors.white.opacity(0.18), in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(16)
            Spacer()
            RoundedRectangle(cornerRadius: 10).fill(Theme.Colors.white).frame(width: 220, height: 300)
                .overlay(Image(systemName: "doc.richtext").font(.system(size: 44, weight: .light)).foregroundStyle(Theme.Colors.ink300))
            Spacer()
            HStack {
                Image(systemName: "chevron.left").foregroundStyle(Theme.Colors.white)
                Spacer(); Text("Page 1 of 24 · viewed online").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.white); Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.Colors.white)
            }
            .padding(.horizontal, 24).padding(.bottom, 10)
            Button {} label: {
                Label("Download to phone", systemImage: "arrow.down.to.line").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle()).padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(Theme.Colors.ink900.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack { CourseDetailsView(role: .parent) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
