//
//  ResumePreviewView.swift
//  Gradit
//
//  A formatted, read-only render of the resume with a share action.
//

import SwiftUI

struct ResumePreviewView: View {
    let resume: Resume
    @Environment(\.dismiss) private var dismiss

    private var template: ResumeTemplate { ResumeTemplate.from(resume.template) }
    private var accent: Color { Color(hex: template.accentHex) }
    private var accentSoft: Color { Color(hex: template.softHex) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heading
                    if !resume.summary.isEmpty { block("Summary") { paragraph(resume.summary) } }
                    if !resume.skills.isEmpty { block("Skills") { chips(resume.skills) } }
                    entryBlock("Education", resume.education)
                    entryBlock("Experience & Internships", resume.experience)
                    entryBlock("Projects", resume.projects)
                    entryBlock("Certifications", resume.certifications)
                    if !resume.achievements.isEmpty {
                        block("Achievements") {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(resume.achievements.enumerated()), id: \.offset) { pair in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•").font(AppFont.jakarta(14, .heavy)).foregroundStyle(accent)
                                        Text(pair.element).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700)
                                    }
                                }
                            }
                        }
                    }
                    if !resume.languages.isEmpty { block("Languages") { chips(resume.languages) } }
                    if !resume.links.isEmpty {
                        block("Links") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(resume.links) { link in
                                    Text("\(link.label): \(link.url)").font(AppFont.jakarta(13, .semibold)).foregroundStyle(accent)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.white)
            }
            .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: plainText) {
                        Label("Share", systemImage: "square.and.arrow.up").font(AppFont.jakarta(16, .bold))
                    }
                }
            }
        }
    }

    // MARK: - Heading

    private var heading: some View {
        let centered = template == .classic
        return VStack(alignment: centered ? .center : .leading, spacing: 6) {
            Text(resume.personal.fullName.isEmpty ? "Your Name" : resume.personal.fullName)
                .font(AppFont.jakarta(26, .heavy)).foregroundStyle(Theme.Colors.ink900)
            if !resume.personal.headline.isEmpty {
                Text(resume.personal.headline).font(AppFont.jakarta(14, .semibold)).foregroundStyle(accent)
            }
            let contacts = [resume.personal.email, resume.personal.phone, resume.personal.location].filter { !$0.isEmpty }
            if !contacts.isEmpty {
                Text(contacts.joined(separator: "  ·  ")).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    .multilineTextAlignment(centered ? .center : .leading)
            }
            Rectangle().fill(accent).frame(height: 2).padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func entryBlock(_ title: String, _ entries: [ResumeEntry]) -> some View {
        if !entries.isEmpty {
            block(title) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(entry.title).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                                Spacer(minLength: 8)
                                if !entry.dateRange.isEmpty {
                                    Text(entry.dateRange).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink500)
                                }
                            }
                            if !entry.subtitle.isEmpty {
                                Text(entry.subtitle).font(AppFont.jakarta(13, .semibold)).foregroundStyle(accent)
                            }
                            if !entry.detail.isEmpty {
                                Text(entry.detail).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
                            }
                        }
                    }
                }
            }
        }
    }

    private func block<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(AppFont.jakarta(12, .heavy)).foregroundStyle(accent).tracking(0.5)
            content()
        }
    }

    private func paragraph(_ text: String) -> some View {
        Text(text).font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700).fixedSize(horizontal: false, vertical: true)
    }

    private func chips(_ items: [String]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item).font(AppFont.jakarta(13, .semibold)).foregroundStyle(accent)
                    .padding(.horizontal, 10).padding(.vertical, 6).background(accentSoft, in: Capsule())
            }
        }
    }

    // MARK: - Plain-text export

    private var plainText: String {
        var lines: [String] = []
        let p = resume.personal
        lines.append(p.fullName)
        if !p.headline.isEmpty { lines.append(p.headline) }
        let contacts = [p.email, p.phone, p.location].filter { !$0.isEmpty }
        if !contacts.isEmpty { lines.append(contacts.joined(separator: " · ")) }

        func section(_ title: String, _ body: [String]) {
            guard !body.isEmpty else { return }
            lines.append("")
            lines.append(title.uppercased())
            lines.append(contentsOf: body)
        }

        if !resume.summary.isEmpty { section("Summary", [resume.summary]) }
        section("Skills", resume.skills.isEmpty ? [] : [resume.skills.joined(separator: ", ")])
        func entries(_ list: [ResumeEntry]) -> [String] {
            list.map { e in
                var s = e.title
                if !e.subtitle.isEmpty { s += " — \(e.subtitle)" }
                if !e.dateRange.isEmpty { s += " (\(e.dateRange))" }
                if !e.detail.isEmpty { s += "\n  \(e.detail)" }
                return s
            }
        }
        section("Education", entries(resume.education))
        section("Experience & Internships", entries(resume.experience))
        section("Projects", entries(resume.projects))
        section("Certifications", entries(resume.certifications))
        section("Achievements", resume.achievements.map { "• \($0)" })
        section("Languages", resume.languages.isEmpty ? [] : [resume.languages.joined(separator: ", ")])
        section("Links", resume.links.map { "\($0.label): \($0.url)" })
        return lines.joined(separator: "\n")
    }
}

#Preview {
    ResumePreviewView(resume: MockResumeService.full)
}
