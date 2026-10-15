//
//  QuickAccessGrid.swift
//  Gradit
//

import SwiftUI

struct QuickAccessGrid: View {
    let actions: [QuickAction]
    var columns = 4
    var title: String?
    var collapsedCount: Int?
    let onSelect: (QuickAction) -> Void

    @State private var isExpanded = false

    private var canCollapse: Bool {
        guard let collapsedCount else { return false }
        return actions.count > collapsedCount
    }

    private var visibleActions: [QuickAction] {
        guard canCollapse, !isExpanded, let collapsedCount else { return actions }
        return Array(actions.prefix(collapsedCount - 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(AppFont.jakarta(13, .heavy))
                    .tracking(0.5)
                    .foregroundStyle(Theme.Colors.ink700)
                    .padding(.horizontal, 8)
                    .accessibilityAddTraits(.isHeader)
            }

            CenteredGrid(columns: columns, spacing: 4, rowSpacing: 4) {
                ForEach(visibleActions) { action in
                    QuickActionTile(title: action.title, systemImage: action.feature.systemImage, minHeight: columns == 3 ? 84 : 0) {
                        onSelect(action)
                    }
                }
                if canCollapse {
                    QuickActionTile(
                        title: isExpanded ? String(localized: "Less") : String(localized: "More"),
                        systemImage: isExpanded ? "chevron.up" : "square.grid.2x2"
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
                    }
                    .accessibilityHint(isExpanded ? "Shows fewer shortcuts" : "Shows all shortcuts")
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, title == nil ? 14 : 12)
        .padding(.bottom, title == nil ? 10 : 8)
        .frame(maxWidth: .infinity)
        .dashboardCard(radius: 18)
    }
}

struct QuickActionTile: View {
    let title: String
    let systemImage: String
    var minHeight: CGFloat = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                IconTile(systemImage: systemImage, size: 48, radius: 14)
                Text(title)
                    .font(AppFont.jakarta(12, .semibold))
                    .foregroundStyle(Theme.Colors.ink900)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .top)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            QuickAccessGrid(actions: DashboardMenus.learner, collapsedCount: 8) { _ in }
            QuickAccessGrid(actions: DashboardMenus.management, columns: 3, title: "MENU") { _ in }
        }
        .padding()
    }
    .background(Theme.Colors.surfaceMuted)
}
