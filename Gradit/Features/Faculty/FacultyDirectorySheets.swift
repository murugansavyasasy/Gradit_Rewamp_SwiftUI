//
//  FacultyDirectorySheets.swift
//  Gradit
//
//  Sheets for the faculty directory: stream picker, department multi-select,
//  department summary and export. Design: facultyModul.pdf p2, p4, p8, p9–10.
//

import SwiftUI

// MARK: - Stream

struct StreamSheet: View {
    let model: FacultyDirectoryViewModel
    let service: FacultyServiceProtocol

    @Environment(\.dismiss) private var dismiss
    @State private var streams: [FacultyStream] = []

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader(title: String(localized: "Stream / institution"),
                        subtitle: String(localized: "Step 1 · pick one")) { dismiss() }
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(streams) { stream in
                        row(stream)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .task { if streams.isEmpty { streams = (try? await service.streams()) ?? [] } }
    }

    private func row(_ stream: FacultyStream) -> some View {
        let isOn = model.streamName == stream.name
        return Button {
            model.apply(stream: stream.name)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.blue600 : Theme.Colors.ink300)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stream.name).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("\(stream.facultyCount) faculty · \(stream.departmentCount) departments")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                if isOn {
                    Text("Selected").font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.blue600)
                }
            }
            .padding(14)
            .dashboardCard(radius: 14, border: isOn ? Theme.Colors.blue600 : Theme.Colors.line,
                           borderWidth: isOn ? 1.5 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Department (multi-select)

struct DepartmentSheet: View {
    let model: FacultyDirectoryViewModel
    let service: FacultyServiceProtocol

    @Environment(\.dismiss) private var dismiss
    @State private var options: [FacultyDepartmentOption] = []
    @State private var selected: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader(title: String(localized: "Department"),
                        subtitle: String(localized: "\(model.streamName) · choose one or more")) { dismiss() }
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(options) { option in row(option) }
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 12) {
                Button("Clear") { selected.removeAll() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                Button {
                    model.apply(departments: Array(selected))
                    dismiss()
                } label: {
                    Text("Show \(shownCount) faculty")
                        .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .task {
            if options.isEmpty {
                options = (try? await service.departments(stream: model.streamName)) ?? []
                selected = Set(model.departments)
            }
        }
    }

    private var allCount: Int { options.first { $0.name == "All departments" }?.facultyCount ?? 0 }
    private var shownCount: Int {
        selected.isEmpty ? allCount : options.filter { selected.contains($0.name) }.reduce(0) { $0 + $1.facultyCount }
    }

    private func row(_ option: FacultyDepartmentOption) -> some View {
        let isAll = option.name == "All departments"
        let isOn = isAll ? selected.isEmpty : selected.contains(option.name)
        return Button {
            if isAll { selected.removeAll() }
            else if selected.contains(option.name) { selected.remove(option.name) }
            else { selected.insert(option.name) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.blue600 : Theme.Colors.ink300)
                Text(option.name).font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink900)
                Spacer(minLength: 0)
                Text("\(option.facultyCount)").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink500)
            }
            .padding(14)
            .dashboardCard(radius: 14, border: isOn ? Theme.Colors.blue600 : Theme.Colors.line,
                           borderWidth: isOn ? 1.5 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Department summary

struct DepartmentSummarySheet: View {
    let department: String
    let service: FacultyServiceProtocol

    @Environment(\.dismiss) private var dismiss
    @State private var summary: FacultyDeptSummary?

    var body: some View {
        VStack(spacing: 0) {
            if let summary {
                sheetHeader(title: String(localized: "\(summary.department) · summary"),
                            subtitle: summary.stream) { dismiss() }
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        hodCard(summary)
                        statsRow(summary)
                        divisions(summary)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)
                Button {
                    dismiss()
                } label: {
                    Label("Show only  \(summary.department)", systemImage: "person.2")
                        .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 20).padding(.vertical, 12)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .task { if summary == nil { summary = try? await service.departmentSummary(department) } }
    }

    private func hodCard(_ summary: FacultyDeptSummary) -> some View {
        HStack(spacing: 12) {
            InitialsAvatar(initials: DashboardGreeting.initials(summary.hodName), size: 44,
                           foreground: Theme.Colors.blue700, background: Theme.Colors.blue100)
            VStack(alignment: .leading, spacing: 2) {
                Text("Head of department").font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.blue700)
                Text(summary.hodName).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("\(summary.hodDesignation) · \(summary.hodDetail)")
                    .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.blue50, in: .rect(cornerRadius: 14))
    }

    private func statsRow(_ summary: FacultyDeptSummary) -> some View {
        HStack(spacing: 10) {
            box("\(summary.faculty)", "Faculty", Theme.Colors.ink900)
            box("\(summary.present)", "Present", Theme.Colors.green700)
            box("\(summary.absent)", "Absent / leave", Theme.Colors.ink900)
        }
    }

    private func box(_ value: String, _ label: String, _ fg: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(AppFont.jakarta(22, .heavy)).foregroundStyle(fg)
            Text(label).font(AppFont.jakarta(11, .bold)).foregroundStyle(Theme.Colors.ink500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14).dashboardCard(radius: 14)
    }

    private func divisions(_ summary: FacultyDeptSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Divisions covered · \(summary.divisions.count)")
                .font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
            FlowLayout(spacing: 8) {
                ForEach(summary.divisions, id: \.self) { division in
                    Text(division).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Theme.Colors.surfaceMuted, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Export

struct ExportFacultySheet: View {
    let filterSummary: String
    let count: Int

    @Environment(\.dismiss) private var dismiss
    @State private var isExcel = false
    @State private var exported = false

    private var fileName: String {
        "Arts-and-Science_Computer-Science_Faculty.\(isExcel ? "xlsx" : "pdf")"
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader(title: String(localized: "Export faculty list"),
                        subtitle: exported ? String(localized: "Saved") : String(localized: "\(count) faculty · current filters")) { dismiss() }
            if exported { completeState } else { formState }
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private var formState: some View {
        VStack(spacing: 14) {
            ScrollView {
                VStack(spacing: 12) {
                    formatRow(title: "PDF", detail: String(localized: "Ready to print or share · A4 portrait"), excel: false)
                    formatRow(title: "Excel (.xlsx)", detail: String(localized: "One row per faculty · easy to sort"), excel: true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("File name (from your filters)").font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink500)
                        Text(fileName).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.blue700)
                        Text("Includes \(count) faculty with designation, department, divisions, subjects and today's status. Grouped by department.")
                            .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            Button { withAnimation { exported = true } } label: {
                Label("Export  \(isExcel ? "Excel" : "PDF")", systemImage: "square.and.arrow.down")
                    .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, 20).padding(.bottom, 12)
        }
    }

    private func formatRow(title: String, detail: String, excel: Bool) -> some View {
        let isOn = isExcel == excel
        return Button { isExcel = excel } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.blue600 : Theme.Colors.ink300)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(detail).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                if isOn { Text("Selected").font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.blue600) }
            }
            .padding(14)
            .dashboardCard(radius: 14, border: isOn ? Theme.Colors.blue600 : Theme.Colors.line, borderWidth: isOn ? 1.5 : 1)
        }
        .buttonStyle(.plain)
    }

    private var completeState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark").font(.system(size: 34, weight: .bold)).foregroundStyle(Theme.Colors.green600)
                .frame(width: 84, height: 84).background(Theme.Colors.green50, in: Circle())
            Text("Export complete").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(fileName).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.blue700)
                .multilineTextAlignment(.center).padding(.horizontal, 24)
            Text("Saved to Downloads · \(count) faculty · \(isExcel ? "Excel" : "PDF") · Wed 07 Oct, 11:12 AM")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            Spacer()
            HStack(spacing: 12) {
                Button("Done") { dismiss() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                ShareLink(item: fileName) {
                    Label("Share file", systemImage: "square.and.arrow.up")
                        .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 16)
        }
    }
}

// MARK: - Shared sheet header

private func sheetHeader(title: String, subtitle: String, onClose: @escaping () -> Void) -> some View {
    HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(subtitle).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
        }
        Spacer()
        Button(action: onClose) {
            Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.Colors.ink700).frame(width: 36, height: 36)
                .background(Theme.Colors.surfaceMuted, in: Circle())
        }
        .buttonStyle(.plain)
    }
    .padding(20)
}
