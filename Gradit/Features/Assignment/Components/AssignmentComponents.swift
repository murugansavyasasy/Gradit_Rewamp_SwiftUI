//
//  AssignmentComponents.swift
//  Gradit
//
//  Shared building blocks for the Assignment module: header bar, subject chip,
//  status badges, attachment rows and the filter dropdown. Design: assignment.pdf.
//

import SwiftUI

// MARK: - Header

/// Back button + bold title with an optional subtitle (e.g. "Dr. Meena Krishnan · CSE").
struct AssignmentTopBar: View {
    let title: String
    var subtitle: String?
    var showsBack = true
    var onBack: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            if showsBack, let onBack {
                TopBarBackButton(action: onBack)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.jakarta(subtitle == nil ? 20 : 22, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.jakarta(13))
                        .foregroundStyle(Theme.Colors.ink500)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
    }
}

// MARK: - Chips & badges

/// Blue subject tag (e.g. "DBMS").
struct SubjectChip: View {
    let subject: String

    var body: some View {
        Text(subject)
            .font(AppFont.jakarta(12, .heavy))
            .foregroundStyle(Theme.Colors.blue700)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Theme.Colors.blue50, in: Capsule())
    }
}

extension FacultyAssignmentStatus {
    var tone: StatusBadge.Tone {
        switch self {
        case .active: .green
        case .pastDue: .red
        case .draft: .neutral
        case .scheduled: .blueSoft
        }
    }
}

extension LearnerAssignmentStatus {
    var tone: StatusBadge.Tone {
        switch self {
        case .pending: .amber
        case .submitted: .blueSoft
        case .graded: .green
        case .overdue: .red
        }
    }
}

// MARK: - Attachment row

extension AttachmentKind {
    var tint: Color {
        switch self {
        case .pdf: Theme.Colors.destructive
        case .image: Theme.Colors.green700
        case .document: Theme.Colors.blue600
        case .voice: Theme.Colors.amber800
        }
    }

    var tintBackground: Color {
        switch self {
        case .pdf: Theme.Colors.errorBackground
        case .image: Theme.Colors.green50
        case .document: Theme.Colors.blue50
        case .voice: Theme.Colors.warningBackground
        }
    }
}

/// A file row with a kind icon, name, detail and trailing actions (view/download or remove).
struct AttachmentRow: View {
    let attachment: AssignmentAttachment
    var showsActions = true
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemImage: attachment.kind.systemImage, size: 40,
                     foreground: attachment.kind.tint, background: attachment.kind.tintBackground)
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.name)
                    .font(AppFont.jakarta(14, .bold))
                    .foregroundStyle(Theme.Colors.ink900)
                    .lineLimit(1)
                Text(attachment.detail)
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            Spacer(minLength: 0)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.Colors.destructive)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(attachment.name)")
            } else if showsActions {
                squareAction(systemImage: "eye", label: "View \(attachment.name)")
                squareAction(systemImage: "arrow.down.to.line", label: "Download \(attachment.name)")
            }
        }
        .padding(10)
        .dashboardCard(radius: 12)
    }

    private func squareAction(systemImage: String, label: LocalizedStringKey) -> some View {
        Button {} label: {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.blue600)
                .frame(width: 36, height: 36)
                .background(Theme.Colors.blue50, in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Dropdown

/// Labelled dropdown pill (e.g. "Class: All ⌄") backed by a Menu.
struct AssignmentDropdown: View {
    var label: String?
    let value: String
    let options: [String]
    let onSelect: (String) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { onSelect(option) }
            }
        } label: {
            HStack(spacing: 6) {
                if let label {
                    Text("\(label):").font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                }
                Text(value)
                    .font(AppFont.jakarta(13, .bold))
                    .foregroundStyle(Theme.Colors.ink900)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.horizontal, 12).frame(height: 38)
            .background(Theme.Colors.white, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.Colors.border))
        }
        .buttonStyle(.plain)
    }
}

/// A full-width form dropdown used on the Create screen.
struct FormDropdown: View {
    let value: String
    let options: [String]
    var isError = false
    let onSelect: (String) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { onSelect(option) }
            }
        } label: {
            HStack {
                Text(value)
                    .font(AppFont.jakarta(15, .semibold))
                    .foregroundStyle(Theme.Colors.ink900)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.horizontal, 14).frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isError ? Theme.Colors.destructive : Theme.Colors.inputBorder))
        }
        .buttonStyle(.plain)
    }
}
