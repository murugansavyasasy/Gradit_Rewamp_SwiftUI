//
//  TimetableGridView.swift
//  Gradit
//
//  Timetable grid editor (Step 2): clash banners, weekly grid, cell editor,
//  preview and publish. Design: timetableModule.pdf p8–13.
//

import SwiftUI

struct TimetableGridView: View {
    let timetableID: String

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: TimetableEditorViewModel?
    @State private var editingCell: TimetableCell?
    @State private var isPreviewing = false
    @State private var showPublished = false

    var body: some View {
        VStack(spacing: 0) {
            header
            if let model, let editor = model.editor {
                content(model, editor: editor)
            } else if let model, model.errorMessage != nil {
                ErrorStateView(message: model.errorMessage ?? "") { model.reload() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = TimetableEditorViewModel(id: timetableID, service: dependencies.timetableService) }
            await model?.load()
        }
        .sheet(item: $editingCell) { cell in
            if let model {
                CellEditorSheet(model: model, cell: cell).presentationDetents([.large])
            }
        }
        .sheet(isPresented: $isPreviewing) {
            if let editor = model?.editor {
                NavigationStack { TimetablePreviewSheet(editor: editor) { isPreviewing = false; showPublished = true } }
            }
        }
        .fullScreenCover(isPresented: $showPublished) {
            if let editor = model?.editor { TimetablePublishedView(editor: editor) { dismiss() } }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            TopBarBackButton { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Timetable grid").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(model?.editor?.classLabel ?? "").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
            }
            Spacer(minLength: 0)
            if let model {
                Button { model.showsDetail.toggle() } label: {
                    Image(systemName: model.showsDetail ? "minus.magnifyingglass" : "plus.magnifyingglass")
                        .font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 40, height: 40).dashboardCard(radius: 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private func content(_ model: TimetableEditorViewModel, editor: TimetableEditor) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !editor.canPublish { cantPublishBanner(editor) }
                ForEach(editor.clashes) { clash in clashCard(model, clash: clash) }
                TimetableWeekGrid(grid: editor.grid, selectedDay: model.selectedDay, showsDetail: model.showsDetail) { cell in
                    editingCell = cell
                }
                .padding(12).dashboardCard(radius: 16)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) { bottomBar(editor) }
    }

    private func cantPublishBanner(_ editor: TimetableEditor) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Can't publish yet").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.destructive)
            if !editor.emptyPeriods.isEmpty {
                Text("• \(editor.emptyPeriods.count) empty periods: \(editor.emptyPeriods.joined(separator: ", "))")
                    .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.destructive)
            }
            if !editor.clashes.isEmpty {
                Text("• \(editor.clashes.count) clashes to fix (see below)")
                    .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.destructive)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.errorBackground, in: .rect(cornerRadius: 14))
    }

    private func clashCard(_ model: TimetableEditorViewModel, clash: TimetableClash) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.destructive)
                Text(clash.title).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.destructive)
            }
            Text(clash.detail).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button { model.resolve(clash) } label: {
                    Text(clash.primaryAction).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 44).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())
                Button("Edit cell") {
                    let parts = clash.title.components(separatedBy: " ").suffix(2)
                    if let day = parts.first, let period = parts.last,
                       let cell = model.editor?.grid.cell(day: String(day), period: String(period)) {
                        editingCell = cell
                    }
                }
                .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink700)
                .padding(.horizontal, 16).frame(minHeight: 44)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16, border: Theme.Colors.destructive.opacity(0.5), borderWidth: 1.5)
    }

    private func bottomBar(_ editor: TimetableEditor) -> some View {
        HStack(spacing: 10) {
            Button("Save draft") { dismiss() }
                .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink700)
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
            Button { isPreviewing = true } label: {
                Label("Preview", systemImage: "eye").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
            }
            .buttonStyle(.plain)
            Button { showPublished = true } label: {
                Text("Publish").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(editor.canPublish ? Theme.Colors.blue600 : Theme.Colors.ink300, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!editor.canPublish)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
        .background(Theme.Colors.white)
    }
}

// MARK: - Cell editor

private struct CellEditorSheet: View {
    let model: TimetableEditorViewModel
    let cell: TimetableCell
    @Environment(\.dismiss) private var dismiss

    @State private var code: String
    @State private var faculty: String
    @State private var room: String

    init(model: TimetableEditorViewModel, cell: TimetableCell) {
        self.model = model
        self.cell = cell
        _code = State(initialValue: cell.subjectCode ?? "")
        _faculty = State(initialValue: model.editor?.faculties.first ?? "")
        _room = State(initialValue: cell.room ?? model.editor?.rooms.first ?? "")
    }

    private var period: TimetablePeriod? { model.editor?.grid.periods.first { $0.id == cell.period } }
    private var facultyBusy: Bool { faculty.contains("busy") }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(fullWeekday(cell.day)) · \(cell.period)").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(period?.time ?? "").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 36, height: 36).background(Theme.Colors.surfaceMuted, in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(20)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Subject").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(model.editor?.subjectPalette ?? []) { subject in
                            let on = code == subject.code
                            Button { code = subject.code } label: {
                                VStack(spacing: 2) {
                                    Text(subject.code).font(AppFont.jakarta(14, .heavy))
                                    Text(subject.name).font(AppFont.jakarta(10)).foregroundStyle(Theme.Colors.ink500)
                                }
                                .foregroundStyle(on ? Theme.Colors.blue700 : Theme.Colors.ink900)
                                .frame(maxWidth: .infinity).frame(height: 56)
                                .background(on ? Theme.Colors.blue50 : Theme.Colors.white, in: .rect(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(on ? Theme.Colors.blue600 : Theme.Colors.line, lineWidth: on ? 1.5 : 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Faculty").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                        FormDropdown(value: faculty, options: model.editor?.faculties ?? [], isError: facultyBusy) { faculty = $0 }
                        if facultyBusy {
                            Text("Dr. Lakshmi Sundar is busy: B.E. CSE Sem 5 B (Computer Networks). Pick someone else or swap periods.")
                                .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.destructive)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Room / venue").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                        FormDropdown(value: room, options: model.editor?.rooms ?? []) { room = $0 }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 12) {
                Button("Clear") { model.clearCell(day: cell.day, period: cell.period); dismiss() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.destructive)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.destructive.opacity(0.5)))
                Button {
                    let name = model.editor?.subjectPalette.first { $0.code == code }?.name ?? code
                    model.setCell(day: cell.day, period: cell.period, code: code, name: name,
                                  teacher: faculty.replacingOccurrences(of: " — busy", with: ""), room: room)
                    dismiss()
                } label: {
                    Text("Save").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(code.isEmpty)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private func fullWeekday(_ short: String) -> String {
        switch short {
        case "Mon": "Monday"
        case "Tue": "Tuesday"
        case "Wed": "Wednesday"
        case "Thu": "Thursday"
        case "Fri": "Friday"
        case "Sat": "Saturday"
        default: short
        }
    }
}

// MARK: - Preview sheet

private struct TimetablePreviewSheet: View {
    let editor: TimetableEditor
    let onPublish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var audience = "Student"
    @State private var selectedDay = "Wed"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "eye").font(.system(size: 13, weight: .bold))
                    Text("Preview — exactly what students, parents and faculty will see from Mon, 12 Oct.")
                        .font(AppFont.jakarta(13, .bold))
                }
                .foregroundStyle(Theme.Colors.white).padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.blue700, in: .rect(cornerRadius: 14))

                HStack(spacing: 4) {
                    ForEach(["Student", "Parent", "Faculty"], id: \.self) { a in
                        let on = audience == a
                        Button(a) { audience = a }
                            .font(AppFont.jakarta(14, on ? .bold : .semibold)).foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(on ? Theme.Colors.blue600 : Theme.Colors.white, in: .rect(cornerRadius: 9))
                            .buttonStyle(.plain)
                    }
                }
                .padding(4).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))

                TimetableWeekGrid(grid: editor.grid, selectedDay: selectedDay, showsDetail: true)
                    .padding(12).dashboardCard(radius: 16)
            }
            .padding(16)
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle("Preview").navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button("Edit") { dismiss() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                Button { onPublish() } label: {
                    Label("Publish", systemImage: "paperplane.fill").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.white)
        }
    }
}

// MARK: - Published

private struct TimetablePublishedView: View {
    let editor: TimetableEditor
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack { Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 40, height: 40).background(Theme.Colors.surfaceMuted, in: Circle())
                }.buttonStyle(.plain)
            }.padding(.horizontal, 16).padding(.top, 8)
            Spacer()
            Image(systemName: "checkmark").font(.system(size: 40, weight: .bold)).foregroundStyle(Theme.Colors.green600)
                .frame(width: 96, height: 96).background(Theme.Colors.green50, in: Circle())
            Text("Timetable published").font(AppFont.jakarta(24, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("B.E. CSE Sem 5 A can now see the new timetable in the app.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center).padding(.horizontal, 24)
            VStack(spacing: 0) {
                row("Class", "B.E. CSE · Sem 5 · A")
                divider; row("Effective", "Mon, 12 Oct 2026")
                divider; row("Periods", "39 per week · Mon–Sat")
                divider; row("Notified", "58 students, 57 parents, 7 faculty")
            }
            .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14)).padding(.horizontal, 16)
            Spacer()
            VStack(spacing: 10) {
                PrimaryButton(title: "View timetable") { onClose() }
                Button { onClose() } label: {
                    Label("Create another", systemImage: "plus").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                }.buttonStyle(.plain)
                PoweredByFooter()
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private var divider: some View { Rectangle().fill(Theme.Colors.divider).frame(height: 1) }
    private func row(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).frame(width: 84, alignment: .leading)
            Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
    }
}

#Preview {
    NavigationStack { TimetableGridView(timetableID: "t1") }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
