//
//  DashboardPrimitives.swift
//  Gradit
//
//  Small building blocks shared by every dashboard: cards, badges, avatars,
//  icon tiles and a centred grid layout.
//

import SwiftUI

// MARK: - Card

extension View {
    /// White rounded card with a 1 pt hairline border (design: `border: 1px solid #E4E8EF`).
    func dashboardCard(
        radius: CGFloat = Theme.Radius.card,
        background: Color = Theme.Colors.white,
        border: Color = Theme.Colors.line,
        borderWidth: CGFloat = 1
    ) -> some View {
        self
            .background(background, in: .rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(border, lineWidth: borderWidth)
            }
    }
}

// MARK: - Badge

struct StatusBadge: View {
    enum Tone {
        case blueSolid, blueSoft, blueMid, amber, green, red, neutral, dark

        var foreground: Color {
            switch self {
            case .blueSolid, .dark: Theme.Colors.white
            case .blueSoft: Theme.Colors.blue700
            case .blueMid: Theme.Colors.blue800
            case .amber: Theme.Colors.amber800
            case .green: Theme.Colors.green700
            case .red: Theme.Colors.red700
            case .neutral: Theme.Colors.ink700
            }
        }

        var background: Color {
            switch self {
            case .blueSolid: Theme.Colors.blue600
            case .blueSoft: Theme.Colors.blue50
            case .blueMid: Theme.Colors.blue100
            case .amber: Theme.Colors.warningBackground
            case .green: Theme.Colors.green50
            case .red: Theme.Colors.errorBackground
            case .neutral: Theme.Colors.surfaceMuted
            case .dark: Theme.Colors.ink900
            }
        }
    }

    let text: String
    var tone: Tone = .blueSoft
    var systemImage: String?
    var weight: Font.Weight = .bold

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .heavy))
            }
            Text(text)
                .lineLimit(1)
        }
        .font(AppFont.jakarta(12, weight))
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(tone.background, in: Capsule())
        .fixedSize()
    }
}

// MARK: - Avatar & icon tile

struct InitialsAvatar: View {
    let initials: String
    var size: CGFloat = 44
    var foreground: Color = Theme.Colors.blue700
    var background: Color = Theme.Colors.blue100

    var body: some View {
        Text(initials)
            .font(AppFont.jakarta(size * 0.32, .heavy))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(background, in: Circle())
            .accessibilityHidden(true)
    }
}

struct IconTile: View {
    let systemImage: String
    var size: CGFloat = 40
    var radius: CGFloat = 12
    var foreground: Color = Theme.Colors.blue600
    var background: Color = Theme.Colors.blue50

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.46, weight: .medium))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(background, in: .rect(cornerRadius: radius))
            .accessibilityHidden(true)
    }
}

/// Small count bubble pinned to the top-right of an icon (design: red/amber "3").
struct CountBubble: View {
    let count: Int
    var color: Color = Theme.Colors.error

    var body: some View {
        Text("\(count)")
            .font(AppFont.jakarta(12, .heavy))
            .foregroundStyle(Theme.Colors.white)
            .padding(.horizontal, 6)
            .frame(minWidth: 22, minHeight: 22)
            .background(color, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.Colors.white, lineWidth: 2))
            .accessibilityHidden(true)
    }
}

// MARK: - Centered grid

/// Fixed-column grid whose last, partial row is centred (design: `flex-wrap; justify-content: center`).
struct CenteredGrid: Layout {
    var columns: Int
    var spacing: CGFloat = 4
    var rowSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 358
        let heights = rowHeights(subviews: subviews, itemWidth: itemWidth(for: width))
        let height = heights.reduce(0, +) + rowSpacing * CGFloat(max(heights.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let itemWidth = itemWidth(for: bounds.width)
        let heights = rowHeights(subviews: subviews, itemWidth: itemWidth)
        var y = bounds.minY

        for (row, start) in stride(from: 0, to: subviews.count, by: columns).enumerated() {
            let end = min(start + columns, subviews.count)
            let count = end - start
            let rowWidth = CGFloat(count) * itemWidth + CGFloat(max(count - 1, 0)) * spacing
            var x = bounds.minX + (bounds.width - rowWidth) / 2

            for index in start..<end {
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: itemWidth, height: heights[row])
                )
                x += itemWidth + spacing
            }
            y += heights[row] + rowSpacing
        }
    }

    private func itemWidth(for width: CGFloat) -> CGFloat {
        max(0, (width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
    }

    private func rowHeights(subviews: Subviews, itemWidth: CGFloat) -> [CGFloat] {
        stride(from: 0, to: subviews.count, by: columns).map { start in
            let end = min(start + columns, subviews.count)
            return (start..<end)
                .map { subviews[$0].sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height }
                .max() ?? 0
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            StatusBadge(text: "Now", tone: .blueSolid)
            StatusBadge(text: "Swapped", tone: .blueMid)
            StatusBadge(text: "Changed", tone: .amber)
            StatusBadge(text: "Low", tone: .red, systemImage: "arrow.down")
        }
        HStack {
            InitialsAvatar(initials: "MI")
            IconTile(systemImage: "megaphone")
            CountBubble(count: 3)
        }
    }
    .padding()
}
