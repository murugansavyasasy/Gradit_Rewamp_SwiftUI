//
//  UploadFilesView.swift
//  Gradit
//
//  Upload files · step 1 (add files + fields) → preview → published.
//  Design: filesModule.pdf p10–14.
//

import SwiftUI
import UniformTypeIdentifiers

struct UploadFilesView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: UploadFilesViewModel?
    @State private var isImporting = false
    @State private var isPickingExpiry = false
    @State private var isPreviewing = false
    @State private var showPublished = false

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Upload files"),
                             subtitle: String(localized: "Step 1 of 2 · add files and audience"), showsBack: true) { dismiss() }
            if let model {
                form(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { if model == nil { model = UploadFilesViewModel(service: dependencies.fileService) } }
        .fileImporter(isPresented: $isImporting,
                      allowedContentTypes: [.pdf, .image, .movie, .video, .plainText, .presentation, .spreadsheet, .data],
                      allowsMultipleSelection: true) { result in
            guard let model else { return }
            if case .success(let urls) = result { urls.forEach { model.addFile(from: $0) } }
        }
        .sheet(isPresented: $isPickingExpiry) {
            if let model { FileExpirySheet(date: Binding(get: { model.expiryDate }, set: { model.expiryDate = $0 })) }
        }
        .sheet(isPresented: $isPreviewing) {
            if let model { NavigationStack { UploadPreviewSheet(model: model) { isPreviewing = false; publish(model) } } }
        }
        .fullScreenCover(isPresented: $showPublished) {
            if let model { FilesPublishedView(model: model) { dismiss() } }
        }
    }

    private func publish(_ model: UploadFilesViewModel) {
        Task { if await model.publish() { showPublished = true } }
    }

    private func form(_ model: UploadFilesViewModel) -> some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if model.showErrors, !model.isValid { validationBanner(model) }
                addFilesCard(model)
                detailsCard($model)
                categoryCard($model)
                audienceCard($model)
                settingsCard($model)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { bottomBar(model) }
    }

    private func validationBanner(_ model: UploadFilesViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.Colors.destructive)
                Text("Fix \(model.problems.count) things before publishing").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.destructive)
            }
            ForEach(model.problems, id: \.self) { p in
                HStack(alignment: .top, spacing: 6) { Text("•").foregroundStyle(Theme.Colors.destructive)
                    Text(p).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.destructive) }
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.errorBackground, in: .rect(cornerRadius: 14))
    }

    private func addFilesCard(_ model: UploadFilesViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add files").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
            HStack(spacing: 10) {
                addTile("camera", "Camera"); addTile("photo.on.rectangle", "Gallery")
                addTile("doc", "Files"); addTile("video", "Video")
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Images JPG, PNG · up to 10 MB each").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                Text("Documents PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX · up to 25 MB each").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
                Text("Videos MP4, MOV · up to 200 MB each").font(AppFont.jakarta(11)).foregroundStyle(Theme.Colors.ink500)
            }
            .padding(10).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 10))

            if !model.files.isEmpty {
                Text("\(model.files.count) of 10 files · \(model.readyCount) ready")
                    .font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
                ForEach(model.files) { fileRow(model, file: $0) }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func addTile(_ icon: String, _ label: LocalizedStringKey) -> some View {
        Button { isImporting = true } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.Colors.blue600)
                Text(label).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink900)
            }
            .frame(maxWidth: .infinity).frame(height: 70)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func fileRow(_ model: UploadFilesViewModel, file: UploadFilesViewModel.LocalFile) -> some View {
        HStack(spacing: 12) {
            FileKindTile(kind: file.kind, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(file.name).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900).lineLimit(1)
                HStack(spacing: 6) {
                    StatusBadge(text: file.typeLabel, tone: file.kind.chipTone, weight: .bold)
                    Text(file.sizeText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    if file.failed { Text("Failed").font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.destructive) }
                    else { Text("Uploaded").font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.green700) }
                }
                if file.failed {
                    Button { model.retry(file) } label: {
                        Label("Retry", systemImage: "arrow.clockwise").font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.blue600)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
            Button { model.remove(file) } label: {
                Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.ink500).frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .padding(10).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
    }

    private func detailsCard(_ model: Bindable<UploadFilesViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Title").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                TextField(String(localized: "e.g. IA 2 timetable and seating"), text: model.title)
                    .font(AppFont.jakarta(15)).padding(.horizontal, 14).frame(height: 48)
                    .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
                        model.wrappedValue.showErrors && model.wrappedValue.titleMissing ? Theme.Colors.destructive : Theme.Colors.inputBorder))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Description (optional)").font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                TextEditor(text: model.details).font(AppFont.jakarta(15)).scrollContentBackground(.hidden)
                    .frame(minHeight: 90).padding(10).background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
            }
        }
        .padding(16).dashboardCard(radius: 16)
    }

    private func categoryCard(_ model: Bindable<UploadFilesViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
            FlowLayout(spacing: 8) {
                ForEach(FileCategory.allCases) { category in
                    let on = model.wrappedValue.category == category
                    Button { model.wrappedValue.category = category } label: {
                        Text(category.title).font(AppFont.jakarta(14, .bold))
                            .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink700)
                            .padding(.horizontal, 14).frame(height: 38)
                            .background(on ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                            .overlay(Capsule().strokeBorder(on ? .clear : Theme.Colors.border))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func audienceCard(_ model: Bindable<UploadFilesViewModel>) -> some View {
        let vm = model.wrappedValue
        let error = vm.showErrors && vm.audienceMissing
        return VStack(alignment: .leading, spacing: 12) {
            Text("Audience").font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
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

    private func settingsCard(_ model: Bindable<UploadFilesViewModel>) -> some View {
        let vm = model.wrappedValue
        return VStack(alignment: .leading, spacing: 14) {
            labelled("Folder") { FormDropdown(value: vm.folder, options: vm.folderOptions) { model.wrappedValue.folder = $0 } }
            labelled("Available until") {
                Button { isPickingExpiry = true } label: {
                    HStack {
                        Text(vm.expiryText).font(AppFont.jakarta(15, .semibold)).foregroundStyle(Theme.Colors.ink900)
                        Spacer(minLength: 0)
                        Image(systemName: "calendar").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
                    }
                    .padding(.horizontal, 14).frame(height: 48).background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
                }
                .buttonStyle(.plain)
            }
            Toggle(isOn: model.downloadAllowed) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Allow download").font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink900)
                    Text("Off = receivers can view online only.").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
            }
            .tint(Theme.Colors.blue600)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
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

    private func labelled<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bottomBar(_ model: UploadFilesViewModel) -> some View {
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
                Label("Publish", systemImage: "paperplane.fill").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 50).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.white)
    }
}

// MARK: - Expiry sheet

private struct FileExpirySheet: View {
    @Binding var date: Date?
    @Environment(\.dismiss) private var dismiss
    private let firstWeekday = 4, daysInMonth = 31, today = 7
    @State private var selectedDay = 31
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Available until").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
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
            PrimaryButton(title: "Done · \(selectedDay) Oct 2026") {
                var c = DateComponents(); c.year = 2026; c.month = 10; c.day = selectedDay; c.hour = 23; c.minute = 59
                date = Calendar.current.date(from: c); dismiss()
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.Colors.white.ignoresSafeArea()).presentationDetents([.large])
    }
}

// MARK: - Preview

private struct UploadPreviewSheet: View {
    let model: UploadFilesViewModel
    let onPublish: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "eye").font(.system(size: 13, weight: .bold))
                    Text("This is how \(model.recipientsText) of \(model.classLabel) · \(model.section) will see it in Campus → Files.")
                        .font(AppFont.jakarta(13, .bold))
                }
                .foregroundStyle(Theme.Colors.white).padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.blue700, in: .rect(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        NoticeAuthorRow(name: "Principal's office", role: model.classLabel, time: "Today, 11:12 AM")
                        StatusBadge(text: model.category.title, tone: .amber, weight: .bold)
                    }
                    Text(model.title.isEmpty ? String(localized: "Untitled") : model.title)
                        .font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    if !model.details.isEmpty {
                        Text(model.details).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700).fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(model.files) { file in
                        HStack(spacing: 12) {
                            FileKindTile(kind: file.kind, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.name).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900).lineLimit(1)
                                HStack(spacing: 6) { StatusBadge(text: file.typeLabel, tone: file.kind.chipTone, weight: .bold)
                                    Text(file.sizeText).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500) }
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.down.to.line").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.blue600)
                        }
                        .padding(10).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
                    }
                    Text("Available until \(model.expiryText)").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
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

private struct FilesPublishedView: View {
    let model: UploadFilesViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack { Spacer()
                Button(action: onClose) { Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.ink700)
                    .frame(width: 40, height: 40).background(Theme.Colors.surfaceMuted, in: Circle()) }.buttonStyle(.plain)
            }.padding(.horizontal, 16).padding(.top, 8)
            Spacer()
            Image(systemName: "checkmark").font(.system(size: 40, weight: .bold)).foregroundStyle(Theme.Colors.green600)
                .frame(width: 96, height: 96).background(Theme.Colors.green50, in: Circle())
            Text("Files published").font(AppFont.jakarta(24, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text("\(model.files.count) files shared with \(model.recipientsText)")
                .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink900).multilineTextAlignment(.center)
            Text(model.audienceSummary).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center).padding(.horizontal, 24)
            VStack(alignment: .leading, spacing: 10) {
                infoLine("bell", "Push notification sent now")
                infoLine("message", "SMS sent to parents")
                infoLine("folder", "Saved in folder \(model.folder) · visible until \(model.expiryText)")
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14)).padding(.horizontal, 16)
            Spacer()
            VStack(spacing: 10) {
                PrimaryButton(title: "View files") { onClose() }
                Button { onClose() } label: {
                    Label("Upload more", systemImage: "plus").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                }.buttonStyle(.plain)
                PoweredByFooter()
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private func infoLine(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.ink500).frame(width: 18)
            Text(text).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    NavigationStack { UploadFilesView() }.environment(AppRouter()).environment(AppDependencies.previewZero)
}
