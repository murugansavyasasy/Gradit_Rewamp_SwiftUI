//
//  ResumeBuilderView.swift
//  Gradit
//
//  Student / parent Resume Builder: completeness overview, template picker and
//  per-section editors (student) with a live preview and share.
//

import SwiftUI

struct ResumeBuilderView: View {
    let role: UserRole

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model: ResumeViewModel?
    @State private var editingSection: ResumeSection?
    @State private var showPreview = false
    @State private var showTemplatePicker = false

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
            if model == nil { model = ResumeViewModel(role: role, service: dependencies.resumeService) }
            await model?.load()
        }
        .sheet(item: $editingSection) { section in
            if let model {
                ResumeSectionEditor(model: model, section: section)
            }
        }
        .sheet(isPresented: $showPreview) {
            if let model {
                ResumePreviewView(resume: model.resume)
            }
        }
        .sheet(isPresented: $showTemplatePicker) {
            if let model {
                ResumeTemplatePickerView(model: model)
            }
        }
        .alert("Resume saved", isPresented: Binding(get: { model?.didSave ?? false },
                                                    set: { if !$0 { model?.didSave = false } })) {
            Button("OK", role: .cancel) { model?.didSave = false }
        } message: {
            Text("Your resume has been saved. You can keep editing or share it any time.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            if isPresented { TopBarBackButton { dismiss() } }
            VStack(alignment: .leading, spacing: 2) {
                Text("Resume Builder").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Text(subtitle).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
            }
            Spacer(minLength: 0)
            Button { showPreview = true } label: {
                Image(systemName: "eye").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink700).frame(width: 40, height: 40).dashboardCard(radius: 12)
            }
            .buttonStyle(.plain).accessibilityLabel("Preview resume")
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }

    private var subtitle: String {
        if let model, model.isParent, let name = model.selectedChildName { return "\(name)'s resume" }
        return String(localized: "Build, preview and share your resume")
    }

    private func childSwitcher(_ model: ResumeViewModel) -> some View {
        HStack(spacing: 10) {
            ForEach(model.children) { child in
                let on = model.selectedChildID == child.id
                Button { model.selectChild(child.id) } label: {
                    HStack(spacing: 10) {
                        InitialsAvatar(initials: DashboardGreeting.initials(child.name), size: 36,
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

    // MARK: - Content

    @ViewBuilder
    private func content(_ model: ResumeViewModel) -> some View {
        if model.isLoading, !model.isLoaded {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = model.errorMessage, !model.isLoaded {
            errorState(error, model: model)
        } else {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        progressCard(model)
                        if model.isEditable { templatePicker(model) }
                        sectionList(model)
                        PoweredByFooter().padding(.top, 4)
                    }
                    .padding(16).padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                .refreshable { model.reload() }
                bottomBar(model)
            }
        }
    }

    private func errorState(_ error: String, model: ResumeViewModel) -> some View {
        VStack(spacing: 10) {
            IconTile(systemImage: "wifi.exclamationmark", size: 64, radius: 20, foreground: Theme.Colors.destructive, background: Theme.Colors.errorBackground)
            Text("Couldn't load resume").font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Text(error).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500).multilineTextAlignment(.center)
            Button("Try again") { model.reload() }.font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                .padding(.horizontal, 20).frame(height: 48).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12)).buttonStyle(PressableButtonStyle())
        }
        .padding(28).frame(maxWidth: .infinity).dashboardCard(radius: 18).padding(16).frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Progress card

    private func progressCard(_ model: ResumeViewModel) -> some View {
        let r = model.resume
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Resume strength").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.white.opacity(0.85))
                    Text(strengthLabel(r.percent)).font(AppFont.jakarta(26, .heavy)).foregroundStyle(Theme.Colors.white)
                    Text("\(r.completedCount) of \(ResumeSection.allCases.count) sections added")
                        .font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                ring(percent: r.percent)
            }
            HStack(spacing: 6) {
                Image(systemName: "sparkles").font(.system(size: 11, weight: .bold))
                Text(model.isEditable ? "Tap a section below to add or edit details" : "Showing the latest saved resume")
                    .font(AppFont.jakarta(12, .semibold))
            }
            .foregroundStyle(Theme.Colors.white)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.white.opacity(0.15), in: .rect(cornerRadius: 12))
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.blue700, in: .rect(cornerRadius: 18))
    }

    private func strengthLabel(_ percent: Int) -> String {
        switch percent {
        case 100: String(localized: "Complete · 100%")
        case 70...: String(localized: "Strong · \(percent)%")
        case 40...: String(localized: "Getting there · \(percent)%")
        default: String(localized: "Just started · \(percent)%")
        }
    }

    private func ring(percent: Int) -> some View {
        ZStack {
            Circle().stroke(Theme.Colors.white.opacity(0.25), lineWidth: 8)
            Circle().trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(Theme.Colors.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(percent)%").font(AppFont.jakarta(18, .heavy)).foregroundStyle(Theme.Colors.white)
        }
        .frame(width: 78, height: 78)
    }

    // MARK: - Template picker

    private func templatePicker(_ model: ResumeViewModel) -> some View {
        let template = ResumeTemplate.from(model.resume.template)
        let accent = Color(hex: template.accentHex)
        return Button { showTemplatePicker = true } label: {
            HStack(spacing: 12) {
                TemplateThumbnail(template: template)
                    .scaleEffect(0.62).frame(width: 68, height: 94)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Template").font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.ink500)
                    Text(template.title).font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(template.tagline).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
                }
                Spacer(minLength: 0)
                Text("Change").font(AppFont.jakarta(13, .bold)).foregroundStyle(accent)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.ink300)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section list

    private func sectionList(_ model: ResumeViewModel) -> some View {
        VStack(spacing: 10) {
            ForEach(ResumeSection.allCases) { section in
                sectionRow(model, section: section)
            }
        }
    }

    private func sectionRow(_ model: ResumeViewModel, section: ResumeSection) -> some View {
        let done = model.resume.isDone(section)
        return Button {
            guard model.isEditable else { return }
            editingSection = section
        } label: {
            HStack(spacing: 12) {
                IconTile(systemImage: section.systemImage, size: 42,
                         foreground: done ? Theme.Colors.green700 : Theme.Colors.blue600,
                         background: done ? Theme.Colors.green50 : Theme.Colors.blue50)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(section.title).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        if section.required && !done {
                            Text("Required").font(AppFont.jakarta(10, .heavy)).foregroundStyle(Theme.Colors.amber800)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theme.Colors.warningBackground, in: Capsule())
                        }
                    }
                    Text(model.resume.status(section)).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500).lineLimit(1)
                }
                Spacer(minLength: 0)
                if done {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.Colors.green600)
                } else if model.isEditable {
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Colors.ink300)
                }
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
        }
        .buttonStyle(.plain)
        .disabled(!model.isEditable)
    }

    // MARK: - Bottom bar

    private func bottomBar(_ model: ResumeViewModel) -> some View {
        HStack(spacing: 12) {
            if model.isEditable {
                Button { showPreview = true } label: {
                    Label("Preview", systemImage: "eye").font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
                        .frame(maxWidth: .infinity, minHeight: 52).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.blue600, lineWidth: 1.5))
                }
                .buttonStyle(PressableButtonStyle())
                PrimaryButton(title: "Save resume", isLoading: model.isSaving) {
                    Task { await model.save() }
                }
            } else {
                PrimaryButton(title: "Preview & share") { showPreview = true }
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12).background(Theme.Colors.white)
    }
}

#Preview("Student") {
    NavigationStack { ResumeBuilderView(role: .student) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}

#Preview("Parent") {
    NavigationStack { ResumeBuilderView(role: .parent) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
