//
//  NoticeComponents.swift
//  Gradit
//
//  Shared building blocks for the Notice Board module. Design: NoticeBoard.pdf.
//

import SwiftUI

extension NoticeCategory {
    var tone: StatusBadge.Tone {
        switch self {
        case .general: .neutral
        case .academic: .blueSoft
        case .exam: .amber
        case .fees: .blueMid
        case .holiday: .blueSoft
        case .event: .green
        case .urgent: .red
        }
    }
    var isUrgent: Bool { self == .urgent }
}

extension NoticeStatus {
    var tone: StatusBadge.Tone {
        switch self {
        case .published: .green
        case .scheduled: .blueSoft
        case .draft: .neutral
        case .expired: .neutral
        }
    }
}

/// A category tag; URGENT renders as a filled red pill with an icon.
struct NoticeCategoryChip: View {
    let category: NoticeCategory

    var body: some View {
        if category.isUrgent {
            StatusBadge(text: category.title.uppercased(), tone: .red, systemImage: "exclamationmark.circle", weight: .heavy)
        } else {
            StatusBadge(text: category.title, tone: category.tone, weight: .bold)
        }
    }
}

/// Blue "📍 Pinned" chip.
struct PinnedChip: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin").font(.system(size: 9, weight: .heavy))
            Text("Pinned").font(AppFont.jakarta(12, .bold))
        }
        .foregroundStyle(Theme.Colors.blue700)
        .padding(.horizontal, 9).padding(.vertical, 3)
        .background(Theme.Colors.blue50, in: Capsule())
    }
}

/// Author avatar + name · role + time.
struct NoticeAuthorRow: View {
    let name: String
    let role: String
    var time: String?

    var body: some View {
        HStack(spacing: 10) {
            InitialsAvatar(initials: DashboardGreeting.initials(name), size: 36,
                           foreground: Theme.Colors.green700, background: Theme.Colors.green50)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(name) · \(role)").font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink900)
                if let time { Text(time).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500) }
            }
            Spacer(minLength: 0)
        }
    }
}
