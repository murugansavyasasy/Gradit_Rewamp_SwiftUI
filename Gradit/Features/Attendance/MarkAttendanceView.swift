//
//  MarkAttendanceView.swift
//  Gradit
//
//  Faculty marks a class roster Present/Absent/On duty/On leave, then confirms.
//  Design: attendanceGradit.pdf p34–35.
//

import SwiftUI

struct MarkAttendanceView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: MarkAttendanceViewModel?
    @State private var isConfirming = false

    let session: FacultyClassSession

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle("Mark attendance")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model == nil { model = MarkAttendanceViewModel(session: session, service: dependencies.attendanceService) }
            await model?.load()
        }
        .sheet(isPresented: $isConfirming) {
            if let model {
                SendAttendanceSheet(model: model) { dismiss() }
                    .presentationDetents([.large])
            }
        }
    }

    private func content(_ model: MarkAttendanceViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    classCard
                    periodPicker(model)
                    modePicker(model)
                    topicField(model)
                    searchField(model)
                    filterChips(model)
                    markAllRow(model)
                    ForEach(model.visible) { student in
                        studentRow(model, student: student)
                    }
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            bottomBar(model)
        }
    }

    private var classCard: some View {
        HStack(spacing: 12) {
            IconTile(systemImage: "book.closed", size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.subject).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(session.classLabel).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
                Text(session.room).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func periodPicker(_ model: MarkAttendanceViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Marking attendance for").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
            HStack {
                Text(model.periodLabel).font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.horizontal, 14).frame(height: 52).dashboardCard(radius: 12)
        }
    }

    private func modePicker(_ model: MarkAttendanceViewModel) -> some View {
        HStack(spacing: 4) {
            ForEach(MarkAttendanceViewModel.Mode.allCases) { mode in
                let isOn = model.mode == mode
                Button(mode.title) { model.mode = mode }
                    .font(AppFont.jakarta(15, isOn ? .bold : .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.ink900 : Theme.Colors.ink500)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                    .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
                    .buttonStyle(.plain)
            }
        }
        .padding(4).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
    }

    private func topicField(_ model: MarkAttendanceViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Topic covered").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
            TextField("e.g. Lab 6: Normalization – 3NF and BCNF", text: Binding(
                get: { model.topic }, set: { model.topic = $0 }))
                .font(AppFont.jakarta(15)).foregroundStyle(Theme.Colors.ink900)
                .padding(.horizontal, 14).frame(height: 52).dashboardCard(radius: 12)
        }
    }

    private func searchField(_ model: MarkAttendanceViewModel) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.Colors.ink500)
            TextField("Search name or number", text: Binding(get: { model.searchText }, set: { model.searchText = $0 }))
                .font(AppFont.jakarta(15)).autocorrectionDisabled()
        }
        .padding(.horizontal, 14).frame(height: 48).dashboardCard(radius: 14)
    }

    private func filterChips(_ model: MarkAttendanceViewModel) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(title: String(localized: "All"), count: model.roster.count, isOn: model.statusFilter == nil,
                     color: Theme.Colors.blue600) { model.statusFilter = nil }
                chip(title: MarkStatus.present.title, count: model.count(.present), isOn: model.statusFilter == .present,
                     color: Theme.Colors.green700) { toggleFilter(model, .present) }
                chip(title: MarkStatus.absent.title, count: model.count(.absent), isOn: model.statusFilter == .absent,
                     color: Theme.Colors.red700) { toggleFilter(model, .absent) }
                chip(title: MarkStatus.onDuty.title, count: model.count(.onDuty), isOn: model.statusFilter == .onDuty,
                     color: Theme.Colors.blue600) { toggleFilter(model, .onDuty) }
                chip(title: MarkStatus.onLeave.title, count: model.count(.onLeave), isOn: model.statusFilter == .onLeave,
                     color: Theme.Colors.amber800) { toggleFilter(model, .onLeave) }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func toggleFilter(_ model: MarkAttendanceViewModel, _ status: MarkStatus) {
        model.statusFilter = model.statusFilter == status ? nil : status
    }

    private func chip(title: String, count: Int, isOn: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if !isOn { Circle().fill(color).frame(width: 7, height: 7) }
                Text(title); Text("\(count)").fontWeight(.heavy)
            }
            .font(AppFont.jakarta(13, .bold))
            .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
            .padding(.horizontal, 14).frame(height: 36)
            .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
            .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
        }
        .buttonStyle(.plain)
    }

    private func markAllRow(_ model: MarkAttendanceViewModel) -> some View {
        HStack(alignment: .top) {
            Text("Tap the circle to switch Present / Absent")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Mark all present") { model.markAllPresent() }
                .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue600)
        }
    }

    private func studentRow(_ model: MarkAttendanceViewModel, student: RosterStudent) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.name).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("Register No: \(student.registerNo)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    Text("Admission No: \(student.admissionNo)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                Button { model.toggle(student) } label: {
                    Text(student.status.letter)
                        .font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.white)
                        .frame(width: 48, height: 48)
                        .background(circleColor(student.status), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(student.name) \(student.status.title). Tap to toggle.")
            }
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            HStack(spacing: 20) {
                statusToggle(model, student: student, status: .onDuty, label: "On Duty")
                statusToggle(model, student: student, status: .onLeave, label: "On Leave")
                Spacer(minLength: 0)
            }
        }
        .padding(14).dashboardCard(radius: 16)
    }

    private func statusToggle(_ model: MarkAttendanceViewModel, student: RosterStudent, status: MarkStatus, label: String) -> some View {
        Toggle(isOn: Binding(
            get: { student.status == status },
            set: { _ in model.set(status, for: student) }
        )) {
            Text(label).font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink900)
        }
        .toggleStyle(.switch)
        .tint(Theme.Colors.blue600)
        .fixedSize()
    }

    private func circleColor(_ status: MarkStatus) -> Color {
        switch status {
        case .present: Theme.Colors.green600
        case .absent: Theme.Colors.error
        case .onDuty: Theme.Colors.blue600
        case .onLeave: Theme.Colors.amber800
        }
    }

    private func bottomBar(_ model: MarkAttendanceViewModel) -> some View {
        HStack(spacing: 12) {
            Button("Cancel") { dismiss() }
                .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.ink700)
                .frame(maxWidth: .infinity, minHeight: 52)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
            Button { isConfirming = true } label: {
                Label("Send attendance", systemImage: "paperplane")
                    .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
        .background(Theme.Colors.white)
    }
}

/// Send-attendance confirmation sheet. Design p35.
private struct SendAttendanceSheet: View {
    let model: MarkAttendanceViewModel
    let onSent: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Send attendance?").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)

                VStack(spacing: 0) {
                    summaryRow("Class", model.session.classLabel)
                    Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                    summaryRow("Period", "\(model.session.period) · \(model.mode.title)")
                    Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                    summaryRow("Topic", model.topic.isEmpty ? "—" : model.topic)
                }
                .padding(.horizontal, 14).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))

                HStack(spacing: 10) {
                    countBox("\(model.count(.present))", "Present", Theme.Colors.green700, Theme.Colors.green50)
                    countBox("\(model.count(.absent))", "Absent", Theme.Colors.red700, Theme.Colors.errorBackground)
                    countBox("\(model.count(.onDuty))", "On duty", Theme.Colors.blue700, Theme.Colors.blue50)
                    countBox("\(model.count(.onLeave))", "On leave", Theme.Colors.amber800, Theme.Colors.warningBackground)
                }

                if !model.absentNames.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Absent students").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        FlowLayout(spacing: 8) {
                            ForEach(model.absentNames, id: \.self) { name in
                                Text(name).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.red700)
                                    .padding(.horizontal, 12).frame(height: 30)
                                    .background(Theme.Colors.errorBackground, in: Capsule())
                            }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle").foregroundStyle(Theme.Colors.blue700)
                    Text("Parents of absent students get an app alert and SMS. You can edit this attendance until 6 PM today.")
                        .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.blue700)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.blue50, in: .rect(cornerRadius: 12))
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button { onSent(); dismiss() } label: {
                    Text("Confirm & send").font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                Button("Review again") { dismiss() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
            .background(Theme.Colors.white)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private func summaryRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).frame(width: 64, alignment: .leading)
            Text(value).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 48)
    }

    private func countBox(_ value: String, _ label: String, _ fg: Color, _ bg: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(AppFont.jakarta(22, .heavy)).foregroundStyle(fg)
            Text(label).font(AppFont.jakarta(11, .bold)).foregroundStyle(fg)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(bg, in: .rect(cornerRadius: 12))
    }
}
