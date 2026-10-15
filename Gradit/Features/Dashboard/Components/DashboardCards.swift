//
//  DashboardCards.swift
//  Gradit
//
//  Cards reused across role dashboards.
//

import SwiftUI

// MARK: - Prompt card (Free periods · Sports Day · Swap request)

struct PromptCard: View {
    enum Accessory { case chevron, button(String) }

    let systemImage: String
    var iconForeground: Color = Theme.Colors.blue600
    var iconBackground: Color = Theme.Colors.blue50
    var badgeCount: Int?
    var badgeColor: Color = Theme.Colors.error
    let title: String
    let subtitle: String
    var background: Color = Theme.Colors.white
    var border: Color = Theme.Colors.blueBorder
    var accessory: Accessory = .chevron
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconTile(systemImage: systemImage, size: 44, foreground: iconForeground, background: iconBackground)
                    .overlay(alignment: .topTrailing) {
                        if let badgeCount, badgeCount > 0 {
                            CountBubble(count: badgeCount, color: badgeColor)
                                .offset(x: 6, y: -6)
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.jakarta(15, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text(subtitle)
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink700)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                switch accessory {
                case .chevron:
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink900)
                case .button(let label):
                    Text(label)
                        .font(AppFont.jakarta(13, .bold))
                        .foregroundStyle(Theme.Colors.white)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(background: background, border: border, borderWidth: 1.5)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Attendance ring (Parent / Student)

struct AttendanceRingCard: View {
    let percent: Double
    let caption: String
    let headline: String
    var detail: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Theme.Colors.blue100, lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: min(max(percent / 100, 0), 1))
                        .stroke(Theme.Colors.blue600, style: StrokeStyle(lineWidth: 7))
                        .rotationEffect(.degrees(-90))
                    Text(DashboardFormat.percent(percent.rounded()))
                        .font(AppFont.jakarta(15, .heavy))
                        .foregroundStyle(Theme.Colors.blue700)
                }
                .frame(width: 57, height: 57)
                .padding(3.5)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(caption)
                        .font(AppFont.jakarta(12, .bold))
                        .foregroundStyle(Theme.Colors.ink500)
                    Text(headline)
                        .font(AppFont.jakarta(15, .bold))
                        .foregroundStyle(Theme.Colors.ink900)
                    if let detail {
                        Text(detail)
                            .font(AppFont.jakarta(12))
                            .foregroundStyle(Theme.Colors.ink500)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(radius: 18)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(DashboardFormat.percent(percent)) attendance. \(headline). \(detail ?? "")")
    }
}

// MARK: - Classes today (Parent / Student)

struct ClassesTodayCard: View {
    let title: String
    let periods: [ClassPeriod]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(AppFont.jakarta(16, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Timetable")
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                    }
                    .font(AppFont.jakarta(13, .bold))
                    .foregroundStyle(Theme.Colors.blue600)
                }

                ForEach(periods) { period in
                    ClassPeriodRow(period: period)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(radius: 18)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct ClassPeriodRow: View {
    let period: ClassPeriod

    private var isNow: Bool { period.timing == .now }

    var body: some View {
        HStack(spacing: 12) {
            Text(period.period)
                .font(AppFont.jakarta(13, .heavy))
                .foregroundStyle(isNow ? Theme.Colors.white : Theme.Colors.blue700)
                .frame(width: 40, height: 40)
                .background(isNow ? Theme.Colors.blue600 : Theme.Colors.blue50, in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(period.timeRange) · \(period.room)")
                    .font(AppFont.jakarta(12, .bold))
                    .foregroundStyle(Theme.Colors.ink700)
                Text(period.subject)
                    .font(AppFont.jakarta(14, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                if let detail = period.detail {
                    Text(detail)
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                switch period.timing {
                case .now: StatusBadge(text: String(localized: "Now"), tone: .blueSolid, weight: .heavy)
                case .next: StatusBadge(text: String(localized: "Next"), tone: .blueSoft, weight: .heavy)
                case .later, .done: EmptyView()
                }
                switch period.change {
                case .swapped: StatusBadge(text: String(localized: "Swapped"), tone: .blueMid, weight: .heavy)
                case .changed: StatusBadge(text: String(localized: "Changed"), tone: .amber, weight: .heavy)
                case .none: EmptyView()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isNow ? Theme.Colors.blue50 : Theme.Colors.white, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(borderColor, lineWidth: isNow ? 2 : 1.5)
        }
        .accessibilityElement(children: .combine)
    }

    private var borderColor: Color {
        if isNow { return Theme.Colors.blue600 }
        return period.change == .changed ? Theme.Colors.amberBorder : Theme.Colors.line
    }
}

// MARK: - Horizontal strips (Events · Assignments)

struct HorizontalCardStrip<Item: Identifiable, Card: View>: View {
    let items: [Item]
    @ViewBuilder let card: (Item) -> Card

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(items) { item in
                    card(item)
                }
            }
            .padding(.bottom, 2)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollClipDisabled()
        .padding(.horizontal, -16)
    }
}

struct EventCard: View {
    let event: EventSummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                StatusBadge(text: DashboardFormat.eventDate(event.date), tone: .blueSolid)
                Text(event.title)
                    .font(AppFont.jakarta(14, .bold))
                    .foregroundStyle(Theme.Colors.ink900)
                    .lineLimit(2)
                Text(event.location)
                    .font(AppFont.jakarta(12))
                    .foregroundStyle(Theme.Colors.ink500)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(width: 184, alignment: .leading)
            .dashboardCard()
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
    }
}

struct AssignmentCard: View {
    let assignment: AssignmentSummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                StatusBadge(text: assignment.subject, tone: .blueSoft)
                Text(assignment.title)
                    .font(AppFont.jakarta(14, .bold))
                    .foregroundStyle(Theme.Colors.ink900)
                    .lineLimit(2)
                StatusBadge(
                    text: DashboardFormat.dueLabel(assignment.dueDate),
                    tone: DashboardFormat.isDueSoon(assignment.dueDate) ? .amber : .blueSoft
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(width: 200, alignment: .leading)
            .dashboardCard()
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Lists

/// White card with divider-separated rows.
struct DividedListCard<Item: Identifiable, Row: View>: View {
    let items: [Item]
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                row(item)
                if index < items.count - 1 {
                    Rectangle()
                        .fill(Theme.Colors.divider)
                        .frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 14)
        .dashboardCard()
    }
}

/// Icon + title + subtitle + chevron row (Notice board, Recent notifications).
struct NoticeRow: View {
    let notice: NoticeSummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconTile(systemImage: (notice.kind ?? .notice).systemImage)
                VStack(alignment: .leading, spacing: 2) {
                    Text(notice.title)
                        .font(AppFont.jakarta(14, .bold))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text(notice.subtitle)
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink500)
            }
            .padding(.vertical, 8)
            .frame(minHeight: 60)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

extension NoticeKind {
    var systemImage: String {
        switch self {
        case .notice: "megaphone"
        case .exam: "doc.text"
        case .fee: "creditcard"
        case .assignment: "tray.and.arrow.down"
        case .meeting: "person.3"
        case .event: "calendar"
        }
    }
}

// MARK: - Chat preview

struct ChatPreviewCard: View {
    let chat: ChatPreview
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                InitialsAvatar(initials: DashboardGreeting.initials(chat.senderName))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(chat.senderName)
                            .font(AppFont.jakarta(14, .bold))
                            .foregroundStyle(Theme.Colors.ink900)
                        if let role = chat.senderRole {
                            Text("(\(role))")
                                .font(AppFont.jakarta(14, .semibold))
                                .foregroundStyle(Theme.Colors.ink500)
                        }
                    }
                    .lineLimit(1)
                    Text(chat.message)
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink700)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(DashboardFormat.time(chat.sentAt))
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(AppFont.jakarta(12, .heavy))
                            .foregroundStyle(Theme.Colors.white)
                            .padding(.horizontal, 6)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(Theme.Colors.blue600, in: Capsule())
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .dashboardCard()
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(chat.unreadCount > 0 ? "\(chat.unreadCount) unread" : "")
    }
}

// MARK: - Sponsored

struct SponsoredBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Text("Ad")
                .font(AppFont.jakarta(12, .bold))
                .foregroundStyle(Theme.Colors.ink700)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Theme.Colors.white, in: .rect(cornerRadius: 6))
            Text(message)
                .font(AppFont.jakarta(13, .semibold))
                .foregroundStyle(Theme.Colors.blue700)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.Colors.blue50, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.Colors.blueBorderLight, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sponsored. \(message)")
    }
}
