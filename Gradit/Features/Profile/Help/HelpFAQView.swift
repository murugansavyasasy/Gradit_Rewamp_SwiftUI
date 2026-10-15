//
//  HelpFAQView.swift
//  Gradit
//
//  Design: 01 Common › Profile and Settings › FAQs and help.
//  Questions are app help copy from the design; move them to a CMS/API when one exists.
//

import SwiftUI

struct HelpFAQView: View {
    @Environment(ProfileStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL

    private enum Category: String, CaseIterable, Identifiable {
        case all, account, fees, attendance, messages
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: String(localized: "All")
            case .account: String(localized: "Account")
            case .fees: String(localized: "Fees")
            case .attendance: String(localized: "Attendance")
            case .messages: String(localized: "Messages")
            }
        }
    }

    private struct FAQ: Identifiable {
        let id: Int
        let category: Category
        let question: String
        let answer: String
    }

    private let faqs: [FAQ] = [
        FAQ(id: 0, category: .account, question: String(localized: "How do I reset my password?"),
            answer: String(localized: "On the sign-in screen tap “Forgot password?”, choose SMS or email, enter the 6-digit code and set a new password.")),
        FAQ(id: 1, category: .account, question: String(localized: "Can I see more than one child in the app?"),
            answer: String(localized: "Yes. Every student linked to your mobile number appears in the student switcher on Home. Tap it to switch.")),
        FAQ(id: 2, category: .fees, question: String(localized: "My fee payment isn’t showing as paid"),
            answer: String(localized: "Online payments update within a few minutes. For bank transfer or DD, upload the payment proof under Fees; the accounts office verifies it, usually within 2 working days.")),
        FAQ(id: 3, category: .attendance, question: String(localized: "Attendance is marked wrong — what should I do?"),
            answer: String(localized: "Open Raise a concern, choose Attendance and mention the date and subject. Your class mentor will review it.")),
        FAQ(id: 4, category: .messages, question: String(localized: "Can I reply to a voice message?"),
            answer: String(localized: "Yes. Open the conversation and hold the microphone button to record a reply, or type a text message.")),
        FAQ(id: 5, category: .account, question: String(localized: "How do I turn on Face ID or fingerprint sign-in?"),
            answer: String(localized: "Sign in once with your password on this phone. Quick sign-in turns on automatically, and you can switch it off in Profile › Notification settings.")),
    ]

    @State private var query = ""
    @State private var category: Category = .all
    @State private var expandedID: Int? = 0

    private var visible: [FAQ] {
        let q = query.trimmed.lowercased()
        return faqs.filter { faq in
            (category == .all || faq.category == category)
                && (q.isEmpty || faq.question.lowercased().contains(q) || faq.answer.lowercased().contains(q))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.Colors.ink500)
                    TextField("Search questions", text: $query)
                        .font(AppFont.jakarta(15))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 14))

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(Category.allCases) { item in
                            let isOn = item == category
                            Button(item.title) {
                                category = item
                                expandedID = nil
                            }
                            .font(AppFont.jakarta(13, isOn ? .bold : .semibold))
                            .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
                            .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isOn ? [.isSelected] : [])
                        }
                    }
                }
                .scrollIndicators(.hidden)

                if visible.isEmpty {
                    Text("No questions match “\(query.trimmed)”.")
                        .font(AppFont.jakarta(14))
                        .foregroundStyle(Theme.Colors.ink500)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    VStack(spacing: 8) {
                        ForEach(visible) { faq in
                            faqRow(faq)
                        }
                    }
                }

                helpCard
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Colors.white.ignoresSafeArea())
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeOut(duration: 0.2), value: expandedID)
        .animation(.easeOut(duration: 0.2), value: category)
    }

    private func faqRow(_ faq: FAQ) -> some View {
        let isOpen = expandedID == faq.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                expandedID = isOpen ? nil : faq.id
            } label: {
                HStack(spacing: 12) {
                    Text(faq.question)
                        .font(AppFont.jakarta(14, .bold))
                        .foregroundStyle(Theme.Colors.ink900)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 10)
                    Spacer(minLength: 0)
                    Image(systemName: isOpen ? "minus" : "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isOpen ? Theme.Colors.white : Theme.Colors.ink700)
                        .frame(width: 28, height: 28)
                        .background(isOpen ? Theme.Colors.blue600 : Theme.Colors.surfaceMuted, in: Circle())
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 52)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")

            if isOpen {
                Text(faq.answer)
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink700)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            }
        }
        .background(isOpen ? Color(hex: 0xF7F9FE) : Theme.Colors.white, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isOpen ? Theme.Colors.blueBorderLight : Theme.Colors.line)
        }
    }

    private var helpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Still need help?")
                    .font(AppFont.jakarta(15, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                Text("Our office replies within 2 working days.")
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink700)
            }
            HStack(spacing: 10) {
                Button {
                    // Management raises it as a message; families use Raise a concern.
                    router.push(.feature(store.role == .management || store.role == .faculty ? .messages : .raiseConcern))
                } label: {
                    Text("Raise a concern")
                        .font(AppFont.jakarta(14, .bold))
                        .foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())

                Button {
                    if let url = officePhoneURL { openURL(url) }
                } label: {
                    Label("Call office", systemImage: "phone")
                        .font(AppFont.jakarta(14, .bold))
                        .foregroundStyle(Theme.Colors.blue700)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(officePhoneURL == nil)
                .opacity(officePhoneURL == nil ? 0.5 : 1)
            }
        }
        .padding(16)
        .background(Theme.Colors.blue50, in: .rect(cornerRadius: 18))
    }

    /// Nil while `AppConfig.collegeOfficePhone` is still a placeholder.
    private var officePhoneURL: URL? {
        let digits = AppConfig.collegeOfficePhone.filter { $0.isNumber || $0 == "+" }
        guard digits.count >= 6 else { return nil }
        return URL(string: "tel:\(digits)")
    }
}

#Preview {
    NavigationStack { HelpFAQView() }
        .environment(ProfileStore(role: .parent, service: MockProfileService()))
        .environment(AppRouter())
}
