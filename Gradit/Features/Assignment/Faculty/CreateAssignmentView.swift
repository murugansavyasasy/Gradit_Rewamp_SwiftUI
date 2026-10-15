//
//  CreateAssignmentView.swift
//  Gradit
//
//  Faculty create-assignment flow: form + validation, due-date and pick-students
//  sheets, student preview and the published-success screen.
//  Design: assignment.pdf p5–10.
//

import SwiftUI
import UniformTypeIdentifiers

struct CreateAssignmentView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: CreateAssignmentViewModel?
    @State private var isPickingDate = false
    @State private var isPickingStudents = false
    @State private var isImportingFiles = false
    @State private var isPreviewing = false
    @State private var showPublished = false

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Create assignment"), showsBack: true) { dismiss() }
            if let model {
                form(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = CreateAssignmentViewModel(service: dependencies.assignmentService) }
            await model?.loadStudents()
        }
        .sheet(isPresented: $isPickingDate) {
            if let model { DueDateSheet(selectedDate: Binding(get: { model.dueDate }, set: { model.dueDate = $0 })) }
        }
        .sheet(isPresented: $isPickingStudents) {
            if let model { PickStudentsSheet(model: model).presentationDetents([.large]) }
        }
        .fileImporter(isPresented: $isImportingFiles,
                      allowedContentTypes: [.pdf, .image, .plainText, .rtf, .presentation, .spreadsheet, .audio, .data],
                      allowsMultipleSelection: true) { result in
            guard let model else { return }
            switch result {
            case .success(let urls):
                urls.forEach { model.addAttachment(from: $0) }
            case .failure(let error):
                model.errorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $isPreviewing) {
            if let model {
                NavigationStack {
                    AssignmentPreviewView(model: model, onPublish: { isPreviewing = false; publish(model) })
                }
            }
        }
        .fullScreenCover(isPresented: $showPublished) {
            if let model { AssignmentPublishedView(model: model, onClose: { dismiss() }) }
        }
    }

    private func publish(_ model: CreateAssignmentViewModel) {
        Task { if await model.publish() { showPublished = true } }
    }

    private func form(_ model: CreateAssignmentViewModel) -> some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if model.showErrors, !model.isValid { validationBanner(model) }
                titleCard($model)
                descriptionCard($model)
                attachmentsCard(model)
                recipientsCard($model)
                settingsCard($model)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { bottomBar(model) }
    }

    // MARK: - Validation banner

    private func validationBanner(_ model: CreateAssignmentViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.Colors.destructive)
                Text("Fix \(model.problems.count) things before publishing")
                    .font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.destructive)
            }
            ForEach(model.problems, id: \.self) { problem in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundStyle(Theme.Colors.destructive)
                    Text(problem).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.destructive)
                }
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.errorBackground, in: .rect(cornerRadius: 14))
    }

    // MARK: - Title & description

    private func titleCard(_ model: Bindable<CreateAssignmentViewModel>) -> some View {
        let error = model.wrappedValue.showErrors && model.wrappedValue.titleMissing
        return VStack(alignment: .leading, spacing: 8) {
            requiredLabel("Title")
            TextField(String(localized: "e.g. Normalization worksheet – 3NF"), text: model.title)
                .font(AppFont.jakarta(15))
                .padding(.horizontal, 14).frame(height: 48)
                .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(error ? Theme.Colors.destructive : Theme.Colors.inputBorder))
            if error {
                Text("Add a title for the assignment.")
                    .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.destructive)
            }
        }
        .padding(16).dashboardCard(radius: 16)
    }

    private func descriptionCard(_ model: Bindable<CreateAssignmentViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
            TextEditor(text: model.details)
                .font(AppFont.jakarta(15)).scrollContentBackground(.hidden)
                .frame(minHeight: 110).padding(10)
                .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
            Text("\(model.wrappedValue.details.count) / 1000")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16).dashboardCard(radius: 16)
    }

    // MARK: - Attachments

    private func attachmentsCard(_ model: CreateAssignmentViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Attachments").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                Text("(optional)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                Spacer()
                if !model.attachments.isEmpty {
                    Text("\(model.attachments.count) files").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
            }

            ForEach(model.attachments) { attachment in
                AttachmentRow(attachment: attachment, onRemove: { model.removeAttachment(attachment) })
            }

            Button { isImportingFiles = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperclip").font(.system(size: 14, weight: .bold))
                    Text("Add file").font(AppFont.jakarta(14, .bold))
                }
                .foregroundStyle(Theme.Colors.blue600)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Theme.Colors.blue50, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.Colors.blueBorderLight, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            }
            .buttonStyle(PressableButtonStyle())

            Text("PDF, images, documents, audio · up to 20 MB each.")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }

    // MARK: - Recipients

    private func recipientsCard(_ model: Bindable<CreateAssignmentViewModel>) -> some View {
        let vm = model.wrappedValue
        let error = vm.showErrors && vm.recipientsMissing
        return VStack(alignment: .leading, spacing: 12) {
            requiredLabel("Select recipients")

            HStack(spacing: 10) {
                labelledField("Course / Department") {
                    FormDropdown(value: vm.department, options: vm.departments) { model.wrappedValue.department = $0 }
                }
                labelledField("Year / Semester") {
                    FormDropdown(value: vm.yearSem, options: vm.yearSems) { model.wrappedValue.yearSem = $0 }
                }
            }
            HStack(spacing: 10) {
                labelledField("Section") {
                    FormDropdown(value: vm.section, options: vm.sections, isError: error && !vm.allStudents) { model.wrappedValue.section = $0 }
                }
                labelledField("Subject") {
                    FormDropdown(value: vm.subject, options: vm.subjects) { model.wrappedValue.subject = $0 }
                }
            }

            FlowLayout(spacing: 8) {
                selectedChip(vm.department)
                selectedChip(vm.yearSem)
                selectedChip(vm.section)
                selectedChip(vm.subject)
            }

            HStack(spacing: 4) {
                recipientToggle("All students in class", isOn: vm.allStudents) { model.wrappedValue.allStudents = true }
                recipientToggle("Pick students", isOn: !vm.allStudents) {
                    model.wrappedValue.allStudents = false
                    isPickingStudents = true
                }
            }
            .padding(4)
            .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))

            Text(vm.recipientsSummary)
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
        }
        .padding(16)
        .dashboardCard(radius: 16, border: error ? Theme.Colors.destructive : Theme.Colors.line)
    }

    private func selectedChip(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark").font(.system(size: 10, weight: .heavy))
            Text(text).font(AppFont.jakarta(12, .bold))
        }
        .foregroundStyle(Theme.Colors.blue700)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Theme.Colors.blue50, in: Capsule())
    }

    private func recipientToggle(_ title: LocalizedStringKey, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.jakarta(14, isOn ? .bold : .semibold))
                .foregroundStyle(isOn ? Theme.Colors.ink900 : Theme.Colors.ink500)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 9))
                .shadow(color: isOn ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings

    private func settingsCard(_ model: Bindable<CreateAssignmentViewModel>) -> some View {
        let vm = model.wrappedValue
        let dueError = vm.showErrors && vm.dueInPast
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                labelledField("Max marks") {
                    TextField("20", text: model.maxMarksText)
                        .keyboardType(.numberPad).font(AppFont.jakarta(15, .semibold))
                        .padding(.horizontal, 14).frame(height: 48)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
                }
                labelledField("Due date") {
                    Button { isPickingDate = true } label: {
                        HStack {
                            Text(vm.dueText)
                                .font(AppFont.jakarta(14, .semibold))
                                .foregroundStyle(vm.dueDate == nil ? Theme.Colors.ink500 : Theme.Colors.ink900)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: "calendar").font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.Colors.ink500)
                        }
                        .padding(.horizontal, 14).frame(height: 48)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(dueError ? Theme.Colors.destructive : Theme.Colors.inputBorder))
                    }
                    .buttonStyle(.plain)
                }
            }

            toggleRow("Late submission allowed", isOn: model.lateAllowed)
            toggleRow("Resubmission allowed", isOn: model.resubmissionAllowed)
        }
        .padding(16).dashboardCard(radius: 16)
    }

    private func toggleRow(_ title: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title).font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink900)
        }
        .tint(Theme.Colors.blue600)
    }

    // MARK: - Helpers

    private func requiredLabel(_ text: String) -> some View {
        HStack(spacing: 2) {
            Text(text).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("*").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.destructive)
        }
    }

    private func labelledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bottomBar(_ model: CreateAssignmentViewModel) -> some View {
        HStack(spacing: 10) {
            Button("Save draft") { Task { if await model.saveDraft() { dismiss() } } }
                .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink700)
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
            Button { isPreviewing = true } label: {
                Label("Preview", systemImage: "eye")
                    .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
            }
            .buttonStyle(.plain)
            Button { publish(model) } label: {
                Text("Publish")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
        .background(Theme.Colors.white)
    }
}

// MARK: - Due date sheet

private struct DueDateSheet: View {
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) private var dismiss

    // October 2026: starts on a Thursday (index 4), 31 days.
    private let firstWeekday = 4
    private let daysInMonth = 31
    private let today = 7
    @State private var selectedDay = 16
    @State private var selectedTime = "11:59 PM"

    private let times = ["09:00 AM", "01:00 PM", "05:00 PM", "11:59 PM"]
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Due date and time").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink700).frame(width: 36, height: 36)
                        .background(Theme.Colors.surfaceMuted, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            ScrollView {
                VStack(spacing: 16) {
                    Text("October 2026").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    HStack(spacing: 0) {
                        ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                            Text(day).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    calendarGrid
                    timeChips
                }
                .padding(.horizontal, 20)
            }

            PrimaryButton(title: LocalizedStringKey("Done · \(dayLabel) · \(selectedTime)")) {
                commit(); dismiss()
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .presentationDetents([.large])
    }

    private var dayLabel: String {
        let names = ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"]
        let weekdayIndex = (firstWeekday + selectedDay - 1) % 7
        let name = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][weekdayIndex]
        _ = names
        return "\(name), \(selectedDay) Oct"
    }

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.frame(height: 40) }
            ForEach(1...daysInMonth, id: \.self) { day in
                let isSelected = day == selectedDay
                let isToday = day == today
                Button { selectedDay = day } label: {
                    Text("\(day)")
                        .font(AppFont.jakarta(15, isSelected ? .heavy : .semibold))
                        .foregroundStyle(isSelected ? Theme.Colors.white : Theme.Colors.ink900)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(isSelected ? Theme.Colors.blue600 : .clear, in: Circle())
                        .overlay {
                            if isToday && !isSelected {
                                Circle().strokeBorder(Theme.Colors.blue600, lineWidth: 1.5)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var timeChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                ForEach(times, id: \.self) { time in
                    let isOn = selectedTime == time
                    Button(time) { selectedTime = time }
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 12).frame(height: 40)
                        .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func commit() {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = selectedDay
        let parts = selectedTime.split(separator: " ")
        let hm = parts.first?.split(separator: ":") ?? []
        var hour = Int(hm.first ?? "0") ?? 0
        let minute = Int(hm.last ?? "0") ?? 0
        if parts.last == "PM", hour != 12 { hour += 12 }
        if parts.last == "AM", hour == 12 { hour = 0 }
        components.hour = hour
        components.minute = minute
        selectedDate = Calendar.current.date(from: components)
    }
}

// MARK: - Pick students sheet

private struct PickStudentsSheet: View {
    @Bindable var model: CreateAssignmentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [AssignmentSubmission] {
        let query = search.trimmed.lowercased()
        return model.students.filter {
            query.isEmpty || $0.studentName.lowercased().contains(query) || $0.registerNo.contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pick students").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("\(model.department) · \(model.section) · \(model.students.count) students")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink700).frame(width: 36, height: 36)
                        .background(Theme.Colors.surfaceMuted, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.Colors.ink500)
                TextField(String(localized: "Search name or reg. no."), text: $search).font(AppFont.jakarta(15))
            }
            .padding(.horizontal, 14).frame(height: 46)
            .dashboardCard(radius: 12)
            .padding(.horizontal, 20)

            HStack {
                Text("\(model.pickedStudentIDs.count) selected")
                    .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
                Spacer()
                Button("Clear all") { model.pickedStudentIDs.removeAll() }
                    .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.blue600)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 10)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filtered) { student in
                        rowView(student)
                        Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)

            PrimaryButton(title: "Done · \(model.pickedStudentIDs.count) selected") { dismiss() }
                .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private func rowView(_ student: AssignmentSubmission) -> some View {
        let isOn = model.pickedStudentIDs.contains(student.id)
        return Button {
            if isOn { model.pickedStudentIDs.remove(student.id) } else { model.pickedStudentIDs.insert(student.id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isOn ? Theme.Colors.blue600 : Theme.Colors.ink300)
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.studentName).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text("Reg. \(student.registerNo)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12).contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview (student view)

private struct AssignmentPreviewView: View {
    let model: CreateAssignmentViewModel
    let onPublish: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "eye").font(.system(size: 13, weight: .bold))
                    Text("Student preview — this is exactly what students in \(model.department) \(model.section) will see.")
                        .font(AppFont.jakarta(13, .bold))
                }
                .foregroundStyle(Theme.Colors.white)
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.blue700, in: .rect(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SubjectChip(subject: model.subject)
                        Spacer()
                        StatusBadge(text: "Pending", tone: .amber, weight: .heavy)
                    }
                    Text(model.title.isEmpty ? String(localized: "Untitled assignment") : model.title)
                        .font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    HStack(spacing: 10) {
                        InitialsAvatar(initials: "MK", size: 40, foreground: Theme.Colors.green700, background: Theme.Colors.green50)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Dr. Meena Krishnan").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                            Text("Class advisor · \(model.subject)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        }
                    }
                    HStack(spacing: 10) {
                        previewBox(label: "Max marks", value: "\(model.maxMarks)")
                        previewBox(label: "Due date", value: model.dueText)
                    }
                    if !model.details.isEmpty {
                        Text("Instructions").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        Text(model.details).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !model.attachments.isEmpty {
                        Text("Attachments from teacher (\(model.attachments.count))")
                            .font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        ForEach(model.attachments) { AttachmentRow(attachment: $0) }
                    }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .dashboardCard(radius: 16)
            }
            .padding(16)
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button("Edit") { dismiss() }
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                Button { onPublish() } label: {
                    Label("Publish", systemImage: "paperplane.fill")
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

    private func previewBox(label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))
    }
}

// MARK: - Published success

private struct AssignmentPublishedView: View {
    let model: CreateAssignmentViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink700).frame(width: 40, height: 40)
                        .background(Theme.Colors.surfaceMuted, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.top, 8)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold)).foregroundStyle(Theme.Colors.green600)
                .frame(width: 96, height: 96)
                .background(Theme.Colors.green50, in: Circle())

            Text("Assignment published")
                .font(AppFont.jakarta(24, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("\"\(model.title)\" is now visible to your students.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center).padding(.horizontal, 24)

            VStack(spacing: 0) {
                summaryRow("Recipients", model.recipientsSummary)
                Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                summaryRow("Subject", model.subject)
                Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                summaryRow("Due date", model.dueText)
                if !model.attachments.isEmpty {
                    Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                    summaryRow("Attachments", String(localized: "\(model.attachments.count) files"))
                }
            }
            .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
            .padding(.horizontal, 16)

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: "View assignment") { onClose() }
                Button { onClose() } label: {
                    Label("Create another", systemImage: "plus")
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                }
                .buttonStyle(.plain)
                PoweredByFooter()
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private func summaryRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                .frame(width: 92, alignment: .leading)
            Text(value).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
    }
}

#Preview {
    NavigationStack { CreateAssignmentView() }
        .environment(AppRouter())
        .environment(AppDependencies.preview)
}
