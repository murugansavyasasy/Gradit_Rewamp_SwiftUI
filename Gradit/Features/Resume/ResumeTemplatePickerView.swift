//
//  ResumeTemplatePickerView.swift
//  Gradit
//
//  Full-screen template chooser for the Resume Builder: each template is shown
//  as a visual thumbnail with its name, tagline and highlights.
//

import SwiftUI

struct ResumeTemplatePickerView: View {
    @Bindable var model: ResumeViewModel
    @Environment(\.dismiss) private var dismiss

    private var selected: ResumeTemplate { ResumeTemplate.from(model.resume.template) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Pick a style for your resume. You can change it any time — your details stay the same.")
                            .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink500)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(ResumeTemplate.allCases) { template in
                            card(template)
                        }
                    }
                    .padding(16).padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                bottomBar
            }
            .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
            .navigationTitle("Choose a template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func card(_ template: ResumeTemplate) -> some View {
        let on = selected == template
        let accent = Color(hex: template.accentHex)
        return Button {
            model.resume.template = template.rawValue
        } label: {
            HStack(alignment: .top, spacing: 14) {
                TemplateThumbnail(template: template)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(template.title).font(AppFont.jakarta(17, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        if on {
                            Text("Selected").font(AppFont.jakarta(10, .heavy)).foregroundStyle(Theme.Colors.white)
                                .padding(.horizontal, 8).padding(.vertical, 3).background(accent, in: Capsule())
                        }
                    }
                    Text(template.tagline).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                        .fixedSize(horizontal: false, vertical: true)
                    FlowLayout(spacing: 6) {
                        ForEach(template.highlights, id: \.self) { tag in
                            Text(tag).font(AppFont.jakarta(11, .semibold)).foregroundStyle(accent)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color(hex: template.softHex), in: Capsule())
                        }
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(on ? accent : Theme.Colors.ink300)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(radius: 18, border: on ? accent : Theme.Colors.line, borderWidth: on ? 2 : 1)
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        PrimaryButton(title: "Use \(selected.title)") { dismiss() }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
            .background(Theme.Colors.white)
    }
}

// MARK: - Thumbnail

/// A small stylised mock of the resume layout for each template.
struct TemplateThumbnail: View {
    let template: ResumeTemplate

    private var accent: Color { Color(hex: template.accentHex) }
    private let width: CGFloat = 108
    private let height: CGFloat = 150

    var body: some View {
        content
            .frame(width: width, height: height)
            .background(Theme.Colors.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.Colors.line))
            .shadow(color: Color(hex: 0x101828, opacity: 0.06), radius: 3, y: 2)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        switch template {
        case .classic: classic
        case .modern: modern
        case .minimal: minimal
        }
    }

    // Centered header, divider rule, single column.
    private var classic: some View {
        VStack(spacing: 7) {
            VStack(spacing: 4) {
                bar(54, 7, accent)
                bar(40, 3, Theme.Colors.ink300)
            }
            .frame(maxWidth: .infinity)
            rule(accent)
            section(lines: 3)
            section(lines: 2)
        }
        .padding(10)
    }

    // Accent sidebar on the left, content on the right.
    private var modern: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Circle().fill(Theme.Colors.white.opacity(0.9)).frame(width: 18, height: 18)
                bar(26, 3, Theme.Colors.white.opacity(0.85))
                bar(20, 3, Theme.Colors.white.opacity(0.7))
                Spacer(minLength: 0)
                bar(24, 3, Theme.Colors.white.opacity(0.7))
                bar(18, 3, Theme.Colors.white.opacity(0.7))
            }
            .padding(8)
            .frame(width: 38)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(accent)
            VStack(alignment: .leading, spacing: 7) {
                bar(44, 7, accent)
                bar(30, 3, Theme.Colors.ink300)
                section(lines: 2, align: .leading)
                section(lines: 2, align: .leading)
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // Left-aligned, thin rules, airy spacing.
    private var minimal: some View {
        VStack(alignment: .leading, spacing: 11) {
            bar(50, 7, accent)
            bar(34, 3, Theme.Colors.ink300)
            rule(Theme.Colors.line)
            section(lines: 2, align: .leading)
            section(lines: 2, align: .leading)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: pieces

    private func section(lines: Int, align: HorizontalAlignment = .center) -> some View {
        VStack(alignment: align, spacing: 4) {
            bar(28, 4, accent.opacity(0.7))
            ForEach(0..<lines, id: \.self) { i in
                bar(i == lines - 1 ? 46 : 68, 3, Theme.Colors.ink300.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: align == .leading ? .leading : .center)
    }

    private func bar(_ w: CGFloat, _ h: CGFloat, _ color: Color) -> some View {
        Capsule().fill(color).frame(width: w, height: h)
    }

    private func rule(_ color: Color) -> some View {
        Rectangle().fill(color).frame(height: 1.5).frame(maxWidth: .infinity)
    }
}

#Preview {
    ResumeTemplatePickerView(model: {
        let m = ResumeViewModel(role: .student, service: MockResumeService(latency: .zero))
        m.resume = MockResumeService.full
        return m
    }())
}
