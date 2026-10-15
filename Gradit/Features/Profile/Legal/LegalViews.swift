//
//  LegalViews.swift
//  Gradit
//
//  Design: 01 Common › Profile and Settings › Privacy policy and Terms.
//  Text is copied from the design, including its [PLACEHOLDER] / [REVIEW WITH LEGAL]
//  markers, so unfinished legal copy stays visible until it is replaced.
//

import SwiftUI

private struct LegalSection: Identifiable {
    let id: Int
    let title: String
    let body: String
}

// MARK: - Privacy policy

struct PrivacyPolicyView: View {
    @Environment(AppRouter.self) private var router
    @State private var expanded: Int? = 0

    private let sections: [LegalSection] = [
        LegalSection(id: 0, title: String(localized: "Information we collect"), body: String(localized: "Student and parent names, contact numbers, email, academic records (attendance, marks, homework), fee and payment details, and bus location while a trip is live. [REVIEW WITH LEGAL]")),
        LegalSection(id: 1, title: String(localized: "How we use it"), body: String(localized: "To show academic progress, send notices and reminders, process fee payments and help families reach faculty. [REVIEW WITH LEGAL]")),
        LegalSection(id: 2, title: String(localized: "Who can see your data"), body: String(localized: "Only you, linked parents or guardians, and authorised college staff. [REVIEW WITH LEGAL]")),
        LegalSection(id: 3, title: String(localized: "Storage & security"), body: String(localized: "[DESCRIBE WHERE DATA IS STORED, ENCRYPTION AND RETENTION PERIOD]")),
        LegalSection(id: 4, title: String(localized: "Your choices & rights"), body: String(localized: "You can update your profile, turn off notifications in Settings, and request a copy or correction of your data from the college office. [REVIEW WITH LEGAL]")),
        LegalSection(id: 5, title: String(localized: "Changes to this policy"), body: String(localized: "We will notify you in the app before any important change takes effect. [REVIEW WITH LEGAL]")),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    IconTile(systemImage: "checkmark.shield", size: 44, foreground: Theme.Colors.white, background: Theme.Colors.blue600)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your data stays with your college")
                            .font(AppFont.jakarta(15, .heavy))
                            .foregroundStyle(Theme.Colors.ink900)
                        Text("This summary explains what \(AppConfig.collegeName) collects through the app and why. Read the full policy below.")
                            .font(AppFont.jakarta(13))
                            .foregroundStyle(Theme.Colors.ink700)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Last updated [DATE] · Version [X.X]")
                            .font(AppFont.jakarta(12, .semibold))
                            .foregroundStyle(Theme.Colors.blue700)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.blue50, in: .rect(cornerRadius: 18))

                VStack(spacing: 0) {
                    ForEach(sections) { section in
                        accordionRow(section)
                        if section.id < sections.count - 1 {
                            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Colors.line))

                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundStyle(Theme.Colors.blue600)
                    Text("Questions? Write to our data officer at \(Text(verbatim: "[PRIVACY EMAIL]").bold().foregroundStyle(Theme.Colors.ink900))")
                        .font(AppFont.jakarta(13))
                        .foregroundStyle(Theme.Colors.ink700)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))
                .padding(.top, 6)

                AuthLinkButton(title: "Read Terms & conditions") {
                    router.push(.profile(.terms))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .navigationTitle("Privacy policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: AppConfig.privacyURL) {
                    Image(systemName: "arrow.down.to.line")
                }
                .accessibilityLabel("Download privacy policy")
            }
        }
        .animation(.easeOut(duration: 0.2), value: expanded)
    }

    private func accordionRow(_ section: LegalSection) -> some View {
        let isOpen = expanded == section.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                expanded = isOpen ? nil : section.id
            } label: {
                HStack(spacing: 12) {
                    Text("\(section.id + 1)")
                        .font(AppFont.jakarta(12, .heavy))
                        .foregroundStyle(Theme.Colors.blue700)
                        .frame(width: 26, height: 26)
                        .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 8))
                    Text(section.title)
                        .font(AppFont.jakarta(15, .bold))
                        .foregroundStyle(Theme.Colors.ink900)
                    Spacer(minLength: 0)
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 54)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")

            if isOpen {
                Text(section.body)
                    .font(AppFont.jakarta(14))
                    .foregroundStyle(Theme.Colors.ink700)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 52)
                    .padding(.trailing, 16)
                    .padding(.bottom, 14)
            }
        }
        .background(isOpen ? Color(hex: 0xF7F9FC) : Theme.Colors.white)
    }
}

// MARK: - Terms

struct TermsView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @AppStorage("legal.acceptedTermsVersion") private var acceptedVersion = ""
    @State private var agreed = true

    /// Bump when the terms text changes so people are asked to accept again.
    private static let termsVersion = "draft-1"

    private let clauses: [LegalSection] = [
        LegalSection(id: 0, title: String(localized: "Using the app"), body: String(localized: "The app is for students, parents and staff of \(AppConfig.collegeName). By signing in you accept these terms.")),
        LegalSection(id: 1, title: String(localized: "Your account"), body: String(localized: "Keep your password and OTPs private. You are responsible for activity on your account and should report misuse to the college office.")),
        LegalSection(id: 2, title: String(localized: "Respectful communication"), body: String(localized: "Messages, voice notes and concerns must be respectful and relate to college matters. Abusive content may be removed.")),
        LegalSection(id: 3, title: String(localized: "Fees & payments"), body: String(localized: "Fee amounts and due dates are set by the college. Payment proofs are verified by the accounts office before they are marked paid. [REVIEW WITH LEGAL]")),
        LegalSection(id: 4, title: String(localized: "Accuracy of information"), body: String(localized: "Attendance, marks and notices are published by the college. Raise a concern in the app if something looks wrong.")),
        LegalSection(id: 5, title: String(localized: "Changes & contact"), body: String(localized: "We may update these terms and will notify you in the app. Questions: [SUPPORT EMAIL]. [REVIEW WITH LEGAL]")),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Effective [DATE]")
                        .font(AppFont.jakarta(12, .bold))
                        .foregroundStyle(Theme.Colors.ink700)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.Colors.surfaceMuted, in: Capsule())
                    Spacer()
                    Text("About 4 min read")
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(clauses) { clause in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(clause.id + 1)")
                                .font(AppFont.jakarta(12, .heavy))
                                .foregroundStyle(Theme.Colors.blue700)
                                .frame(width: 26, height: 26)
                                .background(Theme.Colors.blue50, in: .rect(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(clause.title)
                                    .font(AppFont.jakarta(15, .bold))
                                    .foregroundStyle(Theme.Colors.ink900)
                                    .accessibilityAddTraits(.isHeader)
                                Text(clause.body)
                                    .font(AppFont.jakarta(13))
                                    .foregroundStyle(Theme.Colors.ink700)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(16)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.Colors.line))
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 14)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Toggle(isOn: $agreed) {
                    Text("I have read and agree to the Terms & conditions and the \(Text("Privacy policy").bold().foregroundStyle(Theme.Colors.blue600))")
                }
                .toggleStyle(CheckboxToggleStyle())

                PrimaryButton(title: "Accept & continue", isEnabled: agreed) {
                    acceptedVersion = Self.termsVersion
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(Theme.Colors.white)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
        .navigationTitle("Terms of service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Privacy") { router.push(.profile(.privacyPolicy)) }
                    .font(AppFont.jakarta(14, .bold))
            }
        }
    }
}

#Preview("Privacy") {
    NavigationStack { PrivacyPolicyView() }
        .environment(AppRouter())
}

#Preview("Terms") {
    NavigationStack { TermsView() }
        .environment(AppRouter())
}
