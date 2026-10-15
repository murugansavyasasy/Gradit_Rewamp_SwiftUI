//
//  CreateNoticeView.swift
//  Gradit
//
//  Create notice: form + validation, expiry-date sheet, receiver preview and
//  published success. Design: NoticeBoard.pdf p5–9, p13.
//

import SwiftUI
import UniformTypeIdentifiers

struct CreateNoticeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: CreateNoticeViewModel?
    @State private var isPickingExpiry = false
    @State private var isImportingFiles = false
    @State private var isPreviewing = false
    @State private var showPublished = false

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Create notice"), showsBack: true) { dismiss() }
            if let model {
                form(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { if model == nil { model = CreateNoticeViewModel(service: dependencies.noticeService) } }
        .sheet(isPresented: $isPickingExpiry) {
            if let model { NoticeExpirySheet(date: Binding(get: { model.expiryDate }, set: { model.expiryDate = $0 })) }
        }
        .fileImporter(isPresented: $isImportingFiles,
                      allowedContentTypes: [.pdf, .image, .plainText, .rtf, .presentation, .spreadsheet, .data],
                      allowsMultipleSelection: true) { result in
            guard let model else { return }
            switch result {
            case .success(let urls): urls.forEach { model.addAttachment(from: $0) }
            case .failure(let error): model.errorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $isPreviewing) {
            if let model { NavigationStack { NoticePreviewSheet(model: model) { isPreviewing = false; publish(model) } } }
        }
        .fullScreenCover(isPresented: $showPublished) {
            if let model { NoticePublishedView(model: model) { dismiss() } }
        }
    }

    private func publish(_ model: CreateNoticeViewModel) {
        Task { if await model.publish() { showPublished = true } }
    }

    private func form(_ model: CreateNoticeViewModel) -> some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if model.showErrors, !model.isValid { validationBanner(model) }
                titleCard($model)
                messageCard($model)
                categoryCard($model)
                audienceCard($model)
                attachmentsCard(model)
                settingsCard($model)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { bottomBar(model) }
    }

    private func validationBanner(_ model: CreateNoticeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.Colors.destructive)
                Text("Fix \(model.problems.count) things before publishing").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.destructive)
            }
            ForEach(model.problems, id: \.self) { p in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundStyle(Theme.Colors.destructive)
                    Text(p).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.destructive)
                }
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.errorBackground, in: .rect(cornerRadius: 14))
    }

    private func titleCard(_ model: Bindable<CreateNoticeViewModel>) -> some View {
        let error = model.wrappedValue.showErrors && model.wrappedValue.titleMissing
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                Text("Title").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("*").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.destructive)
                Spacer()
                Text("\(model.wrappedValue.title.count) / 100").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            TextField(String(localized: "e.g. Model exam timetable"), text: model.title)
                .font(AppFont.jakarta(15)).padding(.horizontal, 14).frame(height: 48)
                .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(error ? Theme.Colors.destructive : Theme.Colors.inputBorder))
            if error { Text("Add a title for the notice.").font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.destructive) }
        }
        .padding(16).dashboardCard(radius: 16)
    }

    private func messageCard(_ model: Bindable<CreateNoticeViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
            HStack(spacing: 16) {
                Image(systemName: "bold").font(.system(size: 14, weight: .bold))
                Image(systemName: "list.bullet").font(.system(size: 14, weight: .bold))
                Spacer()
            }
            .foregroundStyle(Theme.Colors.ink700).padding(.horizontal, 12).frame(height: 36)
            .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 8))
            TextEditor(text: model.message).font(AppFont.jakarta(15)).scrollContentBackground(.hidden)
                .frame(minHeight: 120).padding(10).background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
            Text("\(model.wrappedValue.message.count) / 1500").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16).dashboardCard(radius: 16)
    }

    private func categoryCard(_ model: Bindable<CreateNoticeViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
            FlowLayout(spacing: 8) {
                ForEach(NoticeCategory.allCases) { category in
                    let on = model.wrappedValue.category == category
                    Button { model.wrappedValue.category = category } label: {
                        HStack(spacing: 4) {
                            if on { Image(systemName: "checkmark").font(.system(size: 10, weight: .heavy)) }
                            Text(category.title).font(AppFont.jakarta(14, .bold))
                        }
                        .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                        .padding(.horizontal, 14).frame(height: 38)
                        .background(on ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(on ? .clear : Theme.Colors.border))
                    }
                    .buttonStyle(.plain)
                }
            }
            Toggle(isOn: model.highPriority) {
                Text("High priority").font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink900)
            }
            .tint(Theme.Colors.blue600)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func audienceCard(_ model: Bindable<CreateNoticeViewModel>) -> some View {
        let vm = model.wrappedValue
        let error = vm.showErrors && vm.audienceMissing
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 2) {
                Text("Audience").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text("*").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.destructive)
            }
            HStack(spacing: 8) {
                audienceToggle("Students", on: vm.toStudents) { model.wrappedValue.toStudents.toggle() }
                audienceToggle("Parents", on: vm.toParents) { model.wrappedValue.toParents.toggle() }
                audienceToggle("Staff", on: vm.toStaff) { model.wrappedValue.toStaff.toggle() }
            }
            HStack(spacing: 10) {
                labelled("Class") { FormDropdown(value: vm.classLabel, options: vm.classOptions) { model.wrappedValue.classLabel = $0 } }
                labelled("Section") { FormDropdown(value: vm.section, options: vm.sectionOptions) { model.wrappedValue.section = $0 } }
            }
            if error { Text("Select at least one audience.").font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.destructive) }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16, border: error ? Theme.Colors.destructive : Theme.Colors.line)
    }

    private func audienceToggle(_ title: LocalizedStringKey, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle").font(.system(size: 14, weight: .bold))
                Text(title).font(AppFont.jakarta(14, .bold))
            }
            .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(on ? Theme.Colors.blue600 : Theme.Colors.white, in: .rect(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(on ? .clear : Theme.Colors.border))
        }
        .buttonStyle(.plain)
    }

    private func attachmentsCard(_ model: CreateNoticeViewModel) -> some View {
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
            Text("PDF, images, documents · up to 20 MB each.")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func settingsCard(_ model: Bindable<CreateNoticeViewModel>) -> some View {
        let vm = model.wrappedValue
        let dueError = vm.showErrors && vm.expiryInvalid
        return VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: model.pinned) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Pin to top").font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink900)
                    Text("Keeps the notice at the top until it expires.").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
            }
            .tint(Theme.Colors.blue600)
            labelled("Expiry date") {
                Button { isPickingExpiry = true } label: {
                    HStack {
                        Text(vm.expiryText).font(AppFont.jakarta(15, .semibold))
                            .foregroundStyle(vm.expiryDate == nil ? Theme.Colors.ink500 : Theme.Colors.ink900)
                        Spacer(minLength: 0)
                        Image(systemName: "calendar").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                    }
                    .padding(.horizontal, 14).frame(height: 48).background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(dueError ? Theme.Colors.destructive : Theme.Colors.inputBorder))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func labelled<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bottomBar(_ model: CreateNoticeViewModel) -> some View {
        HStack(spacing: 10) {
            Button("Save draft") { Task { if await model.saveDraft() { dismiss() } } }
                .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink700)
                .frame(maxWidth: .infinity, minHeight: 50).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
            Button { isPreviewing = true } label: {
                Label("Preview", systemImage: "eye").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, minHeight: 50).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
            }
            .buttonStyle(.plain)
            Button { publish(model) } label: {
                Text("Publish").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 50).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.white)
    }
}

// MARK: - Expiry sheet

private struct NoticeExpirySheet: View {
    @Binding var date: Date?
    @Environment(\.dismiss) private var dismiss
    private let firstWeekday = 4
    private let daysInMonth = 31
    private let today = 7
    @State private var selectedDay = 26
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Expiry date").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 36, height: 36).background(Theme.Colors.surfaceMuted, in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(20)
            VStack(spacing: 16) {
                Text("October 2026").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                HStack(spacing: 0) {
                    ForEach(Array(weekdays.enumerated()), id: \.offset) { _, d in
                        Text(d).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500).frame(maxWidth: .infinity)
                    }
                }
                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.frame(height: 40) }
                    ForEach(1...daysInMonth, id: \.self) { day in
                        let on = day == selectedDay
                        Button { selectedDay = day } label: {
                            Text("\(day)").font(AppFont.jakarta(15, on ? .heavy : .semibold))
                                .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink900)
                                .frame(maxWidth: .infinity).frame(height: 40)
                                .background(on ? Theme.Colors.blue600 : .clear, in: Circle())
                                .overlay { if day == today && !on { Circle().strokeBorder(Theme.Colors.blue600, lineWidth: 1.5) } }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            PrimaryButton(title: "Done · \(dayLabel)") { commit(); dismiss() }
                .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .presentationDetents([.large])
    }

    private var dayLabel: String {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let idx = (firstWeekday + selectedDay - 1) % 7
        return "\(names[idx]), \(selectedDay) Oct"
    }
    private func commit() {
        var c = DateComponents(); c.year = 2026; c.month = 10; c.day = selectedDay; c.hour = 23; c.minute = 59
        date = Calendar.current.date(from: c)
    }
}

// MARK: - Preview

private struct NoticePreviewSheet: View {
    let model: CreateNoticeViewModel
    let onPublish: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "eye").font(.system(size: 13, weight: .bold))
                    Text("Receiver preview — this is exactly what \(model.recipientsText) will see.").font(AppFont.jakarta(13, .bold))
                }
                .foregroundStyle(Theme.Colors.white).padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.blue700, in: .rect(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        NoticeCategoryChip(category: model.category)
                        if model.pinned { PinnedChip() }
                    }
                    Text(model.title.isEmpty ? String(localized: "Untitled notice") : model.title)
                        .font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    NoticeAuthorRow(name: "Dr. Suresh Kumar", role: "Principal", time: "Wed, 07 Oct 2026 · 02:30 PM")
                    Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                    Text(model.message.isEmpty ? String(localized: "No message yet.") : model.message)
                        .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700).lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    if !model.attachments.isEmpty {
                        Text("Attachments (\(model.attachments.count))").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        ForEach(model.attachments) { AttachmentRow(attachment: $0) }
                    }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
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

private struct NoticePublishedView: View {
    let model: CreateNoticeViewModel
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
            Text("Notice published").font(AppFont.jakarta(24, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("\"\(model.title)\" is live\(model.pinned ? " and pinned" : "") on the notice board.")
                .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center).padding(.horizontal, 24)
            VStack(spacing: 0) {
                row("Audience", model.audienceSummary)
                divider; row("Notified", "Push and SMS sent")
                divider; row("Expires", model.expiryText)
                if !model.attachments.isEmpty {
                    divider; row("Attachments", String(localized: "\(model.attachments.count) files"))
                }
            }
            .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14)).padding(.horizontal, 16)
            Spacer()
            VStack(spacing: 10) {
                PrimaryButton(title: "View notice") { onClose() }
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
    NavigationStack { CreateNoticeView() }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
