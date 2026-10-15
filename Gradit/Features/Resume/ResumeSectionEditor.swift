//
//  ResumeSectionEditor.swift
//  Gradit
//
//  Per-section editing sheets for the Resume Builder (student only).
//

import SwiftUI

struct ResumeSectionEditor: View {
    @Bindable var model: ResumeViewModel
    let section: ResumeSection

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch section {
                    case .personal: personal
                    case .summary: summary
                    case .skills: ResumeTagEditor(title: "Skills", placeholder: "Add a skill", tags: $model.resume.skills)
                    case .languages: ResumeTagEditor(title: "Languages", placeholder: "Add a language", tags: $model.resume.languages)
                    case .education: ResumeEntryEditor(entries: $model.resume.education, labels: .education)
                    case .experience: ResumeEntryEditor(entries: $model.resume.experience, labels: .experience)
                    case .projects: ResumeEntryEditor(entries: $model.resume.projects, labels: .projects)
                    case .certifications: ResumeEntryEditor(entries: $model.resume.certifications, labels: .certifications)
                    case .achievements: ResumeLineEditor(items: $model.resume.achievements)
                    case .links: ResumeLinkEditor(links: $model.resume.links)
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
            .navigationTitle(section.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(AppFont.jakarta(16, .bold))
                }
            }
        }
    }

    // MARK: - Personal

    private var personal: some View {
        VStack(alignment: .leading, spacing: 14) {
            ResumeField(title: "Full name", placeholder: "e.g. Aarav Sharma", text: $model.resume.personal.fullName)
            ResumeField(title: "Headline", placeholder: "e.g. Final-year B.E. CSE · Aspiring Software Engineer", text: $model.resume.personal.headline)
            ResumeField(title: "Email", placeholder: "you@college.edu", text: $model.resume.personal.email, keyboard: .emailAddress)
            ResumeField(title: "Phone", placeholder: "+91 …", text: $model.resume.personal.phone, keyboard: .phonePad)
            ResumeField(title: "Location", placeholder: "City, State", text: $model.resume.personal.location)
        }
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Professional summary").font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink500)
            TextEditor(text: $model.resume.summary)
                .font(AppFont.jakarta(15))
                .foregroundStyle(Theme.Colors.ink900)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160, alignment: .topLeading)
                .padding(10)
                .dashboardCard(radius: 14)
            Text("2–4 sentences about your strengths and what you're looking for.")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
        }
    }
}

// MARK: - Field

struct ResumeField: View {
    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink500)
            TextField(placeholder, text: $text, axis: .vertical)
                .font(AppFont.jakarta(15))
                .foregroundStyle(Theme.Colors.ink900)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .padding(.horizontal, 12).padding(.vertical, 12)
                .dashboardCard(radius: 12)
        }
    }
}

// MARK: - Tag editor (skills / languages)

struct ResumeTagEditor: View {
    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey
    @Binding var tags: [String]
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField(placeholder, text: $draft)
                    .font(AppFont.jakarta(15)).foregroundStyle(Theme.Colors.ink900)
                    .submitLabel(.done).onSubmit(add)
                    .padding(.horizontal, 12).padding(.vertical, 12).dashboardCard(radius: 12)
                Button(action: add) {
                    Image(systemName: "plus").font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(width: 44, height: 44).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if tags.isEmpty {
                Text("Nothing added yet.").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 6) {
                            Text(tag).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.blue700)
                            Button { tags.removeAll { $0 == tag } } label: {
                                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.Colors.blue700)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(Theme.Colors.blue50, in: Capsule())
                    }
                }
            }
        }
    }

    private func add() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { draft = ""; return }
        tags.append(trimmed)
        draft = ""
    }
}

// MARK: - Entry editor (education / experience / projects / certifications)

struct ResumeEntryEditor: View {
    struct Labels {
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
        let dateRange: LocalizedStringKey
        let detail: LocalizedStringKey
        let addButton: LocalizedStringKey

        static let education = Labels(title: "Degree / qualification", subtitle: "Institution",
                                      dateRange: "Years (e.g. 2022 – 2026)", detail: "CGPA / highlights", addButton: "Add education")
        static let experience = Labels(title: "Role / title", subtitle: "Company",
                                       dateRange: "Dates (e.g. Jun 2025 – Aug 2025)", detail: "What you did", addButton: "Add experience")
        static let projects = Labels(title: "Project name", subtitle: "Tech stack",
                                     dateRange: "Year", detail: "Description", addButton: "Add project")
        static let certifications = Labels(title: "Certificate", subtitle: "Issuer",
                                           dateRange: "Year", detail: "Notes (optional)", addButton: "Add certification")
    }

    @Binding var entries: [ResumeEntry]
    let labels: Labels

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach($entries) { $entry in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Entry \(index(of: entry) + 1)").font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink500)
                        Spacer()
                        Button { entries.removeAll { $0.id == entry.id } } label: {
                            Image(systemName: "trash").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.Colors.red700)
                        }
                        .buttonStyle(.plain).accessibilityLabel("Delete entry")
                    }
                    ResumeField(title: labels.title, placeholder: labels.title, text: $entry.title)
                    ResumeField(title: labels.subtitle, placeholder: labels.subtitle, text: $entry.subtitle)
                    ResumeField(title: labels.dateRange, placeholder: labels.dateRange, text: $entry.dateRange)
                    ResumeField(title: labels.detail, placeholder: labels.detail, text: $entry.detail)
                }
                .padding(14).dashboardCard(radius: 16)
            }
            Button { entries.append(.blank()) } label: {
                Label(labels.addButton, systemImage: "plus.circle.fill")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.blue600, lineWidth: 1.5))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private func index(of entry: ResumeEntry) -> Int {
        entries.firstIndex { $0.id == entry.id } ?? 0
    }
}

// MARK: - Line editor (achievements)

struct ResumeLineEditor: View {
    @Binding var items: [String]
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("Add an achievement", text: $draft, axis: .vertical)
                    .font(AppFont.jakarta(15)).foregroundStyle(Theme.Colors.ink900)
                    .padding(.horizontal, 12).padding(.vertical, 12).dashboardCard(radius: 12)
                Button(action: add) {
                    Image(systemName: "plus").font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(width: 44, height: 44).background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if items.isEmpty {
                Text("Nothing added yet.").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { pair in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "trophy.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.amber800).padding(.top, 3)
                        Text(pair.element).font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink900)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button { items.remove(at: pair.offset) } label: {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundStyle(Theme.Colors.ink300)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12).dashboardCard(radius: 14)
                }
            }
        }
    }

    private func add() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(trimmed)
        draft = ""
    }
}

// MARK: - Link editor

struct ResumeLinkEditor: View {
    @Binding var links: [ResumeLink]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach($links) { $link in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Link").font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink500)
                        Spacer()
                        Button { links.removeAll { $0.id == link.id } } label: {
                            Image(systemName: "trash").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.Colors.red700)
                        }
                        .buttonStyle(.plain).accessibilityLabel("Delete link")
                    }
                    ResumeField(title: "Label", placeholder: "e.g. GitHub", text: $link.label)
                    ResumeField(title: "URL", placeholder: "github.com/username", text: $link.url, keyboard: .URL)
                }
                .padding(14).dashboardCard(radius: 16)
            }
            Button { links.append(.blank()) } label: {
                Label("Add link", systemImage: "plus.circle.fill")
                    .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.blue600)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.blue600, lineWidth: 1.5))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }
}
