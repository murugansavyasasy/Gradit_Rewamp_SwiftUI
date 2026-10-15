//
//  SubjectDetailView.swift
//  Gradit
//
//  Student / parent subject detail: meta, status (current/completed/arrear),
//  objectives & outcomes, units. Design: courseDetails.pdf p13–16.
//

import SwiftUI

struct SubjectDetailView: View {
    let childID: String?
    let code: String

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: SubjectDetailViewModel?
    @State private var expanded: Set<Int> = [1]

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Subject detail"),
                             subtitle: model?.detail.map { "\($0.code) · Semester \($0.semester)" }, showsBack: true) { dismiss() }
            if let model, let detail = model.detail {
                content(detail)
            } else if let model, model.errorMessage != nil {
                ErrorStateView(message: model.errorMessage ?? "") { model.reload() }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = SubjectDetailViewModel(childID: childID, code: code, service: dependencies.courseService) }
            await model?.load()
        }
    }

    private func content(_ d: SubjectDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                metaCard(d)
                statusCard(d)
                objectivesCard(d)
                unitsCard(d)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func metaCard(_ d: SubjectDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(d.code).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
                    .padding(.horizontal, 8).padding(.vertical, 3).background(Theme.Colors.surfaceMuted, in: Capsule())
                StatusBadge(text: d.type.title, tone: d.type == .elective ? .amber : .blueSoft, weight: .bold)
            }
            Text(d.name).font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                metaBox("Credits", "\(d.credits)")
                metaBox("Semester", "\(d.semester)")
                metaBox("Int / Ext", "\(d.intMarks) / \(d.extMarks)")
            }
            HStack(spacing: 10) {
                InitialsAvatar(initials: DashboardGreeting.initials(d.teacher), size: 40, foreground: Theme.Colors.green700, background: Theme.Colors.green50)
                VStack(alignment: .leading, spacing: 1) {
                    Text(d.teacher).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(d.teacherRole).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                Button {} label: {
                    Label("Message", systemImage: "bubble.left").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue600)
                        .padding(.horizontal, 14).frame(height: 40).background(Theme.Colors.blue50, in: .rect(cornerRadius: 10))
                }.buttonStyle(PressableButtonStyle())
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func metaBox(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            Text(value).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))
    }

    @ViewBuilder
    private func statusCard(_ d: SubjectDetail) -> some View {
        let (bg, border): (Color, Color) = switch d.statusKind {
        case .current: (Theme.Colors.white, Theme.Colors.line)
        case .completed: (Theme.Colors.green50, Theme.Colors.green100)
        case .arrear: (Theme.Colors.errorBackground, Theme.Colors.destructive.opacity(0.4))
        }
        VStack(alignment: .leading, spacing: 12) {
            Text("\(d.studentName)'s status\(d.statusKind == .current ? " this semester" : "")")
                .font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            HStack(spacing: 12) {
                switch d.statusKind {
                case .current:
                    statusMetric(title: "Attendance", value: "\(d.attendancePercent ?? 0)%", note: d.attendanceNote ?? "", valueColor: Theme.Colors.green700)
                    statusMetric(title: "Internal marks so far", value: d.internalMarks ?? "—", note: d.internalBreakdown ?? "", valueColor: Theme.Colors.ink900)
                case .completed:
                    statusMetric(title: "Result", value: d.resultText ?? "", note: d.resultNote ?? "", valueColor: Theme.Colors.green700)
                    statusMetric(title: "Credits earned", value: d.creditsEarnedText ?? "", note: d.creditsEarnedNote ?? "", valueColor: Theme.Colors.ink900)
                case .arrear:
                    statusMetric(title: "Result", value: d.resultText ?? "", note: d.resultNote ?? "", valueColor: Theme.Colors.destructive)
                    statusMetric(title: "Credits earned", value: d.creditsEarnedText ?? "", note: d.creditsEarnedNote ?? "", valueColor: Theme.Colors.ink900)
                }
            }
            HStack(spacing: 12) {
                pillButton("Attendance", icon: "calendar.badge.checkmark")
                pillButton("Exam marks", icon: "rosette")
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(bg, in: .rect(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(border))
    }

    private func statusMetric(title: LocalizedStringKey, value: String, note: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            Text(value).font(AppFont.jakarta(20, .heavy)).foregroundStyle(valueColor)
            Text(note).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pillButton(_ title: LocalizedStringKey, icon: String) -> some View {
        Button {} label: {
            Label(title, systemImage: icon).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.blue600)
                .frame(maxWidth: .infinity, minHeight: 46).background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
        }.buttonStyle(PressableButtonStyle())
    }

    @ViewBuilder
    private func objectivesCard(_ d: SubjectDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objectives and course outcomes").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            if let note = d.objectivesInSyllabusNote, d.objectives.isEmpty {
                Text(note).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(d.objectives, id: \.self) { obj in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundStyle(Theme.Colors.ink700)
                        Text(obj).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700).fixedSize(horizontal: false, vertical: true)
                    }
                }
                ForEach(d.outcomes) { co in
                    Text("\(co.code) · \(co.text)").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink900)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(10)
                        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func unitsCard(_ d: SubjectDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Units").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Text("\(d.units.count) units · \(d.units.count * 12) hours").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            VStack(spacing: 0) {
                ForEach(Array(d.units.enumerated()), id: \.element.id) { index, unit in
                    if index > 0 { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
                    unitRow(unit)
                }
            }
            .dashboardCard(radius: 14)
        }
    }

    private func unitRow(_ unit: CourseUnit) -> some View {
        let open = expanded.contains(unit.number)
        return VStack(alignment: .leading, spacing: 8) {
            Button {
                if open { expanded.remove(unit.number) } else { expanded.insert(unit.number) }
            } label: {
                HStack(spacing: 10) {
                    Text("\(unit.number)").font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.blue700)
                        .frame(width: 26, height: 26).background(Theme.Colors.blue50, in: .rect(cornerRadius: 8))
                    Text(unit.title).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
                    Text(unit.hours).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink500)
                    Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            if open, let detail = unit.detail {
                Text(detail).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    .padding(.leading, 36).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
    }
}

#Preview {
    NavigationStack { SubjectDetailView(childID: "aarav", code: "CS3492") }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
