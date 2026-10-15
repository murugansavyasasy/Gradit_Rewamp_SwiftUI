//
//  TimetableSetupView.swift
//  Gradit
//
//  Timetable setup · Step 1 of 2: class, working days and period structure.
//  Design: timetableModule.pdf p5–7.
//

import SwiftUI

struct TimetableSetupView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    @State private var classLabel = "B.E. CSE · Sem 5"
    @State private var section = "Section A"
    @State private var term = "Odd semester 2026–27 (Jul – Nov)"
    @State private var dayStartsAt = "09:00 AM"
    @State private var workingDays: Set<String> = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    @State private var isCopying = false

    private let allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Timetable setup"),
                             subtitle: String(localized: "Step 1 of 2 · Class and periods"), showsBack: true) { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    copyButton
                    classCard
                    workingDaysCard
                    periodStructureCard
                }
                .padding(16).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) { bottomBar }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isCopying) { CopyFromClassSheet().presentationDetents([.medium, .large]) }
    }

    private var copyButton: some View {
        Button { isCopying = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "doc.on.doc").font(.system(size: 16, weight: .semibold))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Copy from another class").font(AppFont.jakarta(14, .bold))
                    Text("Reuse periods (and subjects) from a published class")
                        .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colors.blue600)
            }
            .foregroundStyle(Theme.Colors.blue600)
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.blue50, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.blueBorderLight, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
        }
        .buttonStyle(.plain)
    }

    private var classCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                field("Class") { FormDropdown(value: classLabel, options: ["B.E. CSE · Sem 5", "B.E. CSE · Sem 3", "B.Tech IT · Sem 3"]) { classLabel = $0 } }
                field("Section") { FormDropdown(value: section, options: ["Section A", "Section B", "Section C"]) { section = $0 } }
            }
            field("Academic term") { FormDropdown(value: term, options: ["Odd semester 2026–27 (Jul – Nov)", "Even semester 2026–27 (Dec – Apr)"]) { term = $0 } }
            field("Effective from") {
                HStack {
                    Image(systemName: "calendar").foregroundStyle(Theme.Colors.ink500)
                    Text("Mon, 12 Oct 2026").font(AppFont.jakarta(15, .semibold)).foregroundStyle(Theme.Colors.ink900)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14).frame(height: 48)
                .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.inputBorder))
            }
        }
        .padding(16).dashboardCard(radius: 16)
    }

    private var workingDaysCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Working days").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            HStack(spacing: 8) {
                ForEach(allDays, id: \.self) { day in
                    let on = workingDays.contains(day)
                    Button {
                        if on { workingDays.remove(day) } else { workingDays.insert(day) }
                    } label: {
                        VStack(spacing: 4) {
                            Text(day).font(AppFont.jakarta(12, .bold))
                            Image(systemName: on ? "checkmark" : "xmark").font(.system(size: 9, weight: .heavy))
                        }
                        .foregroundStyle(on ? Theme.Colors.white : Theme.Colors.ink500)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(on ? Theme.Colors.blue600 : Theme.Colors.white, in: .rect(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(on ? .clear : Theme.Colors.border))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("\(workingDays.count) working days · Saturday is a half day (P1–P4)")
                .font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private var periodStructureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Period structure").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Text("7 periods a day").font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
            }
            field("Day starts at") { FormDropdown(value: dayStartsAt, options: ["08:30 AM", "09:00 AM", "09:30 AM"]) { dayStartsAt = $0 } }
            ForEach(MockTimetableService.periods.prefix(3)) { period in
                HStack(spacing: 10) {
                    Text(period.id).font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.blue700)
                        .frame(width: 32, height: 28).background(Theme.Colors.blue50, in: .rect(cornerRadius: 8))
                    Text(period.time).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                    Spacer(minLength: 0)
                    Image(systemName: "trash").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.Colors.destructive)
                }
                .padding(.vertical, 6)
            }
            Text("…and 4 more periods").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button("Save draft") { dismiss() }
                .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                .frame(maxWidth: .infinity, minHeight: 52)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
            Button { router.push(.timetable(.editor("new"))) } label: {
                Label("Next", systemImage: "chevron.right")
                    .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
        .background(Theme.Colors.white)
    }
}

// MARK: - Copy sheet

private struct CopyFromClassSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected = "B.E. CSE · Sem 5 · B"
    @State private var withSubjects = false

    private let classes: [(String, String)] = [
        ("B.E. CSE · Sem 5 · B", "Published · 7 periods · Mon–Sat"),
        ("B.E. CSE · Sem 3 · A", "Published · 7 periods · Mon–Sat"),
        ("B.Tech IT · Sem 3 · B", "Published · 7 periods · Mon–Fri"),
        ("B.E. ECE · Sem 5 · A", "Draft · 6 periods"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Copy from another class").font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 36, height: 36).background(Theme.Colors.surfaceMuted, in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(20)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(classes, id: \.0) { item in
                        let on = selected == item.0
                        Button { selected = item.0 } label: {
                            HStack(spacing: 12) {
                                Image(systemName: on ? "largecircle.fill.circle" : "circle")
                                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(on ? Theme.Colors.blue600 : Theme.Colors.ink300)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.0).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                                    Text(item.1).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(14).dashboardCard(radius: 14, border: on ? Theme.Colors.blue600 : Theme.Colors.line, borderWidth: on ? 1.5 : 1)
                        }
                        .buttonStyle(.plain)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What to copy").font(AppFont.jakarta(13, .semibold)).foregroundStyle(Theme.Colors.ink700)
                        HStack(spacing: 4) {
                            segment("Periods only", on: !withSubjects) { withSubjects = false }
                            segment("Periods + subjects", on: withSubjects) { withSubjects = true }
                        }
                        .padding(4).background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            Button { dismiss() } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(AppFont.jakarta(16, .bold)).foregroundStyle(Theme.Colors.white)
                    .frame(maxWidth: .infinity, minHeight: 52).background(Theme.Colors.blue600, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle()).padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private func segment(_ title: LocalizedStringKey, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(AppFont.jakarta(14, on ? .bold : .semibold))
                .foregroundStyle(on ? Theme.Colors.ink900 : Theme.Colors.ink500)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(on ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 9))
                .shadow(color: on ? Color(hex: 0x101828, opacity: 0.08) : .clear, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { TimetableSetupView() }
        .environment(AppRouter())
        .environment(AppDependencies.previewZero)
}
