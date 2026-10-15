//
//  RoleSelectView.swift
//  Gradit
//

import SwiftUI

/// Common › Sign in › Role selection. Shown when the account has more than one role.
struct RoleSelectView: View {
    let user: AuthUser

    @Environment(AuthSession.self) private var session
    @State private var role: UserRole
    @State private var collegeID: College.ID?

    init(user: AuthUser, preferredRole: UserRole?) {
        self.user = user
        let preferred = preferredRole.flatMap { user.roles.contains($0) ? $0 : nil }
        _role = State(initialValue: preferred ?? user.roles.first ?? .parent)
        _collegeID = State(initialValue: user.colleges.first?.id)
    }

    private var selectedCollege: College? {
        user.colleges.first { $0.id == collegeID }
    }

    var body: some View {
        AuthScaffold(spacing: 18) {
            header

            VStack(spacing: 12) {
                ForEach(user.roles) { item in
                    SelectionCard(
                        title: item.title,
                        subtitle: item.summary,
                        systemImage: item.systemImage,
                        isSelected: role == item,
                        indicator: .check,
                        iconForeground: item.tint,
                        iconBackground: item.tintBackground
                    ) {
                        role = item
                    }
                }
            }

            if !user.colleges.isEmpty {
                collegePicker
            }
        } bottom: {
            PrimaryButton(title: "Continue as \(role.shortName)") {
                session.selectRole(role, college: selectedCollege)
            }
            AuthLinkButton(title: "Use a different account") {
                Task { await session.signOut() }
            }
        }
        .sensoryFeedback(.selection, trigger: role)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Signed in as \(user.maskedPhone ?? user.name)")
                .textCase(.uppercase)
                .font(AppFont.jakarta(13, .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.Colors.blue600)
            Text("How are you using the app?")
                .font(Theme.Typography.display)
                .foregroundStyle(Theme.Colors.ink900)
                .accessibilityAddTraits(.isHeader)
            Text("Your account has more than one role. You can switch anytime from Profile.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.ink700)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Theme.Spacing.s20)
    }

    private var collegePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("College")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.ink700)

            Menu {
                Picker("College", selection: $collegeID) {
                    ForEach(user.colleges) { college in
                        Text(college.name).tag(Optional(college.id))
                    }
                }
            } label: {
                HStack {
                    Text(selectedCollege?.name ?? String(localized: "Select college"))
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.ink900)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Theme.Colors.white, in: .rect(cornerRadius: Theme.Radius.input))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.input).strokeBorder(Theme.Colors.border)
                }
            }
            .disabled(user.colleges.count < 2)
        }
    }
}

#Preview {
    RoleSelectView(user: MockAuthService.demoUser, preferredRole: nil)
        .environment(AuthSession.preview())
}
