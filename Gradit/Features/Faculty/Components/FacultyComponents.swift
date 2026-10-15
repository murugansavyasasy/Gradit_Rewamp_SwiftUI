//
//  FacultyComponents.swift
//  Gradit
//
//  Shared building blocks for the Faculty module. Design: facultyModul.pdf.
//

import SwiftUI

extension FacultyPresence {
    var tone: StatusBadge.Tone {
        switch self {
        case .present: .green
        case .onLeave: .amber
        case .absent: .red
        case .notPunchedIn: .neutral
        }
    }
    var dotColor: Color {
        switch self {
        case .present: Theme.Colors.green600
        case .onLeave: Theme.Colors.amber800
        case .absent: Theme.Colors.destructive
        case .notPunchedIn: Theme.Colors.ink300
        }
    }
}

extension SubjectKind {
    var tone: StatusBadge.Tone {
        switch self {
        case .theory: .blueSoft
        case .lab: .green
        case .activity: .amber
        }
    }
}

/// Small role pill: "Head of dept" / "Class teacher".
struct FacultyRoleChip: View {
    let role: FacultyRole

    var body: some View {
        if role != .none {
            HStack(spacing: 4) {
                Image(systemName: role.systemImage).font(.system(size: 9, weight: .heavy))
                Text(role.title).font(AppFont.jakarta(11, .heavy))
            }
            .foregroundStyle(role == .headOfDept ? Theme.Colors.blue700 : Theme.Colors.green700)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(role == .headOfDept ? Theme.Colors.blue50 : Theme.Colors.green50, in: Capsule())
        }
    }
}

/// One faculty row used across the directory lists.
struct FacultyMemberRow: View {
    let member: FacultyMember
    var showsChevron = true

    var body: some View {
        HStack(spacing: 12) {
            InitialsAvatar(initials: DashboardGreeting.initials(member.name), size: 44,
                           foreground: Theme.Colors.blue700, background: Theme.Colors.blue100)
            VStack(alignment: .leading, spacing: 3) {
                Text(member.name).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                if member.role != .none { FacultyRoleChip(role: member.role) }
                Text(member.designation).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink700)
                Text(member.subjects).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Circle().fill(member.presence.dotColor).frame(width: 7, height: 7)
                    Text(member.presenceDetail)
                        .font(AppFont.jakarta(12, .semibold))
                        .foregroundStyle(member.presence == .present ? Theme.Colors.green700 : Theme.Colors.ink500)
                }
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.chevron)
            }
        }
        .padding(14).contentShape(.rect)
    }
}

/// A "Dr. Meena Krishnan  ·  Subject chips" teacher row for the learner view.
struct LearnerTeacherRow: View {
    let teacher: LearnerTeacher
    var onMessage: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                InitialsAvatar(initials: DashboardGreeting.initials(teacher.name), size: 42,
                               foreground: Theme.Colors.blue700, background: Theme.Colors.blue100)
                VStack(alignment: .leading, spacing: 2) {
                    Text(teacher.name).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    HStack(spacing: 6) {
                        Text(teacher.designation).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                        if teacher.role != .none {
                            Text("· \(teacher.role.title)").font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.green700)
                        }
                    }
                }
                Spacer(minLength: 0)
                if let onMessage {
                    Button(action: onMessage) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.Colors.blue600)
                            .frame(width: 36, height: 36).background(Theme.Colors.blue50, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Message \(teacher.name)")
                }
            }
            ForEach(teacher.subjects) { subject in
                HStack(spacing: 8) {
                    Text(subject.name).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink900)
                    StatusBadge(text: subject.kind.title, tone: subject.kind.tone)
                    Spacer(minLength: 0)
                    Text("\(subject.perWeek) / week").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
            }
            if let note = teacher.awayNote {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.exclamationmark").font(.system(size: 11, weight: .bold))
                    Text(note).font(AppFont.jakarta(12, .semibold))
                }
                .foregroundStyle(Theme.Colors.amber800)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.warningBackground, in: .rect(cornerRadius: 10))
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
    }
}
