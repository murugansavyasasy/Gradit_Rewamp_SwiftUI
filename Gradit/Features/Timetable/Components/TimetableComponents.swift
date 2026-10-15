//
//  TimetableComponents.swift
//  Gradit
//
//  Shared building blocks for the Timetable module: day strip, weekly grid and
//  period cards. Design: timetableModule.pdf.
//

import SwiftUI

// MARK: - Cell state styling

extension CellState {
    var cellForeground: Color {
        switch self {
        case .clash: Theme.Colors.destructive
        case .edited, .substitute: Theme.Colors.amber800
        case .free: Theme.Colors.amber800
        case .empty: Theme.Colors.ink300
        default: Theme.Colors.blue700
        }
    }
    var cellBackground: Color {
        switch self {
        case .clash: Theme.Colors.errorBackground
        case .edited, .substitute, .free: Theme.Colors.warningBackground
        case .empty: Theme.Colors.surfaceMuted
        default: Theme.Colors.blue50
        }
    }
    var marker: String? {
        switch self {
        case .swapped: "arrow.left.arrow.right"
        case .substitute, .free: "star.fill"
        case .edited: "pencil"
        default: nil
        }
    }
}

// MARK: - Day strip

/// Horizontal day selector: weekday over date, today ringed, selected filled.
struct TimetableDayStrip<Day: Identifiable>: View {
    let days: [Day]
    let weekday: (Day) -> String
    let date: (Day) -> String
    let isToday: (Day) -> Bool
    let isSelected: (Day) -> Bool
    let onSelect: (Day) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(days) { day in
                let selected = isSelected(day)
                Button { onSelect(day) } label: {
                    VStack(spacing: 2) {
                        Text(weekday(day)).font(AppFont.jakarta(11, .semibold))
                            .foregroundStyle(selected ? Theme.Colors.white.opacity(0.9) : Theme.Colors.ink500)
                        Text(date(day)).font(AppFont.jakarta(16, .heavy))
                            .foregroundStyle(selected ? Theme.Colors.white : Theme.Colors.ink900)
                        if isToday(day) {
                            Text("Today").font(AppFont.jakarta(8, .bold))
                                .foregroundStyle(selected ? Theme.Colors.white.opacity(0.9) : Theme.Colors.blue600)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(selected ? Theme.Colors.blue600 : Theme.Colors.white, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(selected ? .clear : (isToday(day) ? Theme.Colors.blue600 : Theme.Colors.line),
                                      lineWidth: isToday(day) && !selected ? 1.5 : 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Weekly grid

struct TimetableWeekGrid: View {
    let grid: TimetableGrid
    var selectedDay: String?
    var showsDetail = false              // zoom: show teacher initials + room
    var onTapCell: ((TimetableCell) -> Void)?

    var body: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            GridRow {
                Color.clear.frame(width: 38, height: 22)
                ForEach(grid.days, id: \.self) { day in
                    Text(day).font(AppFont.jakarta(12, .bold))
                        .foregroundStyle(day == selectedDay ? Theme.Colors.blue700 : Theme.Colors.ink500)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(grid.periods) { period in
                GridRow {
                    VStack(spacing: 1) {
                        Text(period.id).font(AppFont.jakarta(11, .heavy)).foregroundStyle(Theme.Colors.ink700)
                        Text(period.shortStart).font(AppFont.jakarta(9)).foregroundStyle(Theme.Colors.ink500)
                    }
                    .frame(width: 38)
                    ForEach(grid.days, id: \.self) { day in
                        cellView(grid.cell(day: day, period: period.id), isSelectedDay: day == selectedDay)
                    }
                }
                if let label = period.breakAfter {
                    GridRow {
                        Text(label).font(AppFont.jakarta(10, .semibold)).foregroundStyle(Theme.Colors.ink500)
                            .frame(maxWidth: .infinity).padding(.vertical, 3)
                            .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 6))
                            .gridCellColumns(grid.days.count + 1)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(_ cell: TimetableCell?, isSelectedDay: Bool) -> some View {
        let state = cell?.state ?? .empty
        Button { if let cell { onTapCell?(cell) } } label: {
            VStack(spacing: 1) {
                if let code = cell?.subjectCode {
                    HStack(spacing: 2) {
                        Text(code).font(AppFont.jakarta(showsDetail ? 11 : 12, .heavy))
                        if let marker = state.marker {
                            Image(systemName: marker).font(.system(size: 7, weight: .heavy))
                        }
                    }
                    if showsDetail, let initials = cell?.teacherInitials {
                        Text(initials).font(AppFont.jakarta(9, .semibold))
                        Text(cell?.room ?? "").font(AppFont.jakarta(8)).foregroundStyle(Theme.Colors.ink500)
                    }
                    if state == .clash { Text("Clash").font(AppFont.jakarta(7, .bold)) }
                    if state == .free { Text("Free").font(AppFont.jakarta(7, .bold)) }
                } else {
                    Text("—").font(AppFont.jakarta(13, .bold))
                }
            }
            .foregroundStyle(state.cellForeground)
            .frame(maxWidth: .infinity).frame(height: showsDetail ? 52 : 44)
            .background(state.cellBackground, in: .rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(state == .clash ? Theme.Colors.destructive : (isSelectedDay ? Theme.Colors.blueBorderLight : .clear),
                              lineWidth: state == .clash ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .disabled(onTapCell == nil)
    }
}

// MARK: - Period card (day views)

struct TimetablePeriodCard: View {
    let period: String
    let time: String
    let title: String
    let subtitle: String
    var statusText: String?
    var statusTone: StatusBadge.Tone = .blueSoft
    var note: String?
    var noteIsChange = true
    var highlighted = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 2) {
                Text(period).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.blue700)
            }
            .frame(width: 38, height: 38).background(Theme.Colors.blue50, in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(time).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink500)
                Text(title).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                if let note {
                    Text(note)
                        .font(AppFont.jakarta(12, .semibold))
                        .foregroundStyle(noteIsChange ? Theme.Colors.amber800 : Theme.Colors.green700)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if let statusText {
                StatusBadge(text: statusText, tone: statusTone, weight: .heavy)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16, border: highlighted ? Theme.Colors.blue600 : Theme.Colors.line,
                       borderWidth: highlighted ? 1.5 : 1)
    }
}
