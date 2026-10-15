//
//  OnboardingSlide.swift
//  Gradit
//
//  The four intro pages and their illustrations, copied from the design.
//  The illustrations are static artwork (example content), not user data.
//

import SwiftUI

struct OnboardingSlide: Identifiable {
    enum Artwork { case voice, geoAttendance, resume, overview }

    let id: Int
    let tag: String
    let title: String
    let body: String
    let soft: Color
    let blob: Color
    let ink: Color
    let artwork: Artwork
    let accessibilityLabel: String

    @ViewBuilder
    var illustration: some View {
        switch artwork {
        case .voice: VoiceArtwork()
        case .geoAttendance: GeoAttendanceArtwork()
        case .resume: ResumeArtwork()
        case .overview: OverviewArtwork()
        }
    }

    static let all: [OnboardingSlide] = [
        OnboardingSlide(
            id: 0,
            tag: String(localized: "Voice communication"),
            title: String(localized: "Talk to every parent in one voice note"),
            body: String(localized: "Teachers record once and every parent hears it, with a transcript and a “Heard” receipt. Parents play it anytime and reply in a tap."),
            soft: Theme.Colors.blue50,
            blob: Color(hex: 0x2453D4, opacity: 0.08),
            ink: Theme.Colors.blue700,
            artwork: .voice,
            accessibilityLabel: String(localized: "A teacher recording an 18-second voice message to 62 parents, then a receipt saying it was heard by 48 of 62 parents, with a transcript in English and Tamil.")
        ),
        OnboardingSlide(
            id: 1,
            tag: String(localized: "Geo-fenced attendance"),
            title: String(localized: "Attendance verified on campus"),
            body: String(localized: "Staff check in with one tap, only inside the college geo-fence. No registers, no proxies, and the principal sees it live."),
            soft: Theme.Colors.green50,
            blob: Color(hex: 0x0F7A4A, opacity: 0.08),
            ink: Theme.Colors.green700,
            artwork: .geoAttendance,
            accessibilityLabel: String(localized: "A campus map with a green geo-fence and a pin inside it, and a card saying checked in at 08:52 AM, location verified, on time.")
        ),
        OnboardingSlide(
            id: 2,
            tag: String(localized: "Resume Builder"),
            title: String(localized: "Build a placement-ready resume"),
            body: String(localized: "Marks, projects and certificates from the college fill in automatically. Pick a template and download a PDF for placement drives."),
            soft: Theme.Colors.warningBackground,
            blob: Color(hex: 0xA15C07, opacity: 0.08),
            ink: Theme.Colors.amber800,
            artwork: .resume,
            accessibilityLabel: String(localized: "A student resume with skills and a project, and a bar showing the resume is 80 percent complete with a PDF download button.")
        ),
        OnboardingSlide(
            id: 3,
            tag: String(localized: "And everything else"),
            title: String(localized: "Your whole college, in one app"),
            body: String(localized: "Attendance, fees, files, events, marks and more — updated the moment the college posts them."),
            soft: Theme.Colors.blue50,
            blob: Color(hex: 0x2453D4, opacity: 0.08),
            ink: Theme.Colors.blue700,
            artwork: .overview,
            accessibilityLabel: String(localized: "Four cards for attendance, fee details, files and events.")
        ),
    ]
}

// MARK: - Shared card style

private extension View {
    func artworkCard(radius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Theme.Colors.white, in: .rect(cornerRadius: radius))
            .shadow(color: Color(hex: 0x101828, opacity: 0.12), radius: 14, y: 10)
    }
}

// MARK: - 1 · Voice

private struct VoiceArtwork: View {
    private let wave: [CGFloat] = [10, 18, 26, 14, 30, 22, 12, 24, 34, 20, 14, 26, 18, 10, 22, 30, 16, 12, 20, 14, 24, 18]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Circle().fill(Theme.Colors.error).frame(width: 10, height: 10)
                    Text("Recording · 0:18")
                        .font(AppFont.jakarta(13, .heavy))
                        .foregroundStyle(Theme.Colors.red700)
                    Spacer()
                    StatusBadge(text: "To 62 parents", tone: .blueSoft)
                }
                HStack(spacing: 3) {
                    ForEach(Array(wave.enumerated()), id: \.offset) { offset, height in
                        Capsule()
                            .fill(offset < 14 ? Theme.Colors.blue600 : Theme.Colors.blueBorderLight)
                            .frame(width: 4, height: height)
                    }
                }
                .frame(height: 44)
                HStack(spacing: 20) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink700)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().strokeBorder(Theme.Colors.border))
                    Image(systemName: "mic")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.Colors.white)
                        .frame(width: 60, height: 60)
                        .background(Theme.Colors.blue600, in: Circle())
                        .padding(6)
                        .background(Theme.Colors.blue100, in: Circle())
                    Image(systemName: "paperplane")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.white)
                        .frame(width: 40, height: 40)
                        .background(Theme.Colors.green600, in: Circle())
                }
            }
            .artworkCard()

            HStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.Colors.green700)
                    .frame(width: 36, height: 36)
                    .background(Theme.Colors.green50, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text("Heard by 48 of 62 parents")
                        .font(AppFont.jakarta(14, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text("Transcript sent in English and Tamil")
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
            }
            .artworkCard(radius: 18, padding: 11)
            .padding(.leading, 28)
        }
    }
}

// MARK: - 2 · Geo attendance

private struct GeoAttendanceArtwork: View {
    var body: some View {
        let gridColor = Theme.Colors.line
        VStack(spacing: 10) {
            ZStack {
                Canvas { context, size in
                    var path = Path()
                    stride(from: CGFloat(27.5), through: size.height, by: 28).forEach { y in
                        path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    stride(from: CGFloat(27.5), through: size.width, by: 28).forEach { x in
                        path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    context.stroke(path, with: .color(gridColor), lineWidth: 1)
                }
                .background(Theme.Colors.surfaceMuted)

                Circle()
                    .fill(Theme.Colors.green600.opacity(0.12))
                    .overlay(Circle().strokeBorder(Theme.Colors.green600, style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
                    .frame(width: 170, height: 170)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.Colors.white, Theme.Colors.green600)
                    .offset(y: -12)

                VStack {
                    HStack {
                        Text("UCE Chennai campus")
                            .font(AppFont.jakarta(12, .heavy))
                            .foregroundStyle(Theme.Colors.green700)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Theme.Colors.white, in: Capsule())
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Inside geo-fence")
                            .font(AppFont.jakarta(12, .heavy))
                            .foregroundStyle(Theme.Colors.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Theme.Colors.green600, in: Capsule())
                    }
                }
                .padding(12)
            }
            .frame(height: 200)
            .clipShape(.rect(cornerRadius: 20))
            .shadow(color: Color(hex: 0x101828, opacity: 0.12), radius: 14, y: 10)

            HStack(spacing: 12) {
                IconTile(systemImage: "mappin.and.ellipse", size: 44, foreground: Theme.Colors.green700, background: Theme.Colors.green50)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Checked in · 08:52 AM")
                        .font(AppFont.jakarta(15, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    Text("Admin block · location verified, 12 m")
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                Spacer(minLength: 0)
                StatusBadge(text: "On time", tone: .green, weight: .heavy)
            }
            .artworkCard(radius: 18, padding: 13)
        }
    }
}

// MARK: - 3 · Resume

private struct ResumeArtwork: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    InitialsAvatar(initials: "AR", size: 48, foreground: Theme.Colors.white, background: Theme.Colors.amber800)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Aarav R.")
                            .font(AppFont.jakarta(16, .heavy))
                            .foregroundStyle(Theme.Colors.ink900)
                        Text("B.E. CSE · UCE Chennai · CGPA 8.4")
                            .font(AppFont.jakarta(12))
                            .foregroundStyle(Theme.Colors.ink500)
                    }
                }
                Rectangle().fill(Theme.Colors.divider).frame(height: 1)
                Text("SKILLS")
                    .font(AppFont.jakarta(12, .heavy)).tracking(0.6)
                    .foregroundStyle(Theme.Colors.amber800)
                FlowLayout(spacing: 6) {
                    ForEach(["Python", "SQL", "React", "Cloud Computing"], id: \.self) { skill in
                        StatusBadge(text: skill, tone: .amber)
                    }
                }
                Text("PROJECT")
                    .font(AppFont.jakarta(12, .heavy)).tracking(0.6)
                    .foregroundStyle(Theme.Colors.amber800)
                Text("Smart attendance kiosk · Techfest ’26 best project")
                    .font(AppFont.jakarta(13))
                    .foregroundStyle(Theme.Colors.ink700)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .artworkCard()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Resume 80% complete")
                        .font(AppFont.jakarta(13, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                    GeometryReader { proxy in
                        Capsule().fill(Color(hex: 0xE9EDF3))
                            .overlay(alignment: .leading) {
                                Capsule().fill(Theme.Colors.amber800).frame(width: proxy.size.width * 0.8)
                            }
                    }
                    .frame(height: 6)
                }
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.to.line")
                    Text("PDF")
                }
                .font(AppFont.jakarta(13, .heavy))
                .foregroundStyle(Theme.Colors.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
            }
            .artworkCard(radius: 18, padding: 13)
            .padding(.leading, 28)
        }
    }
}

// MARK: - 4 · Overview

private struct OverviewArtwork: View {
    private struct Tile: Identifiable {
        let id: String
        let symbol: String
        let value: String
        let foreground: Color
        let background: Color
    }

    private let tiles: [Tile] = [
        Tile(id: "Attendance", symbol: "calendar.badge.checkmark", value: "92% this semester", foreground: Theme.Colors.blue700, background: Theme.Colors.blue50),
        Tile(id: "Fee Details", symbol: "creditcard", value: "₹24,500 due 15 Oct", foreground: Theme.Colors.amber800, background: Theme.Colors.warningBackground),
        Tile(id: "Files", symbol: "folder", value: "IA 2 timetable.pdf", foreground: Theme.Colors.red700, background: Theme.Colors.errorBackground),
        Tile(id: "Events", symbol: "calendar", value: "Sports Day photos", foreground: Theme.Colors.green700, background: Theme.Colors.green50),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(tiles) { tile in
                VStack(alignment: .leading, spacing: 8) {
                    IconTile(systemImage: tile.symbol, foreground: tile.foreground, background: tile.background)
                    Text(tile.id)
                        .font(AppFont.jakarta(12, .bold))
                        .foregroundStyle(Theme.Colors.ink500)
                    Text(tile.value)
                        .font(AppFont.jakarta(16, .heavy))
                        .foregroundStyle(Theme.Colors.ink900)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .artworkCard(radius: 18, padding: 14)
            }
        }
    }
}
