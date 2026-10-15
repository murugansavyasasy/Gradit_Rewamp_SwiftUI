//
//  EventPublishedView.swift
//  Gradit
//
//  Success screens: Event published and Gallery published.
//  Design: 12 Events › Published, Gallery published.
//

import SwiftUI

struct EventPublishedView: View {
    let title: String
    let deadline: Date?
    var isScheduled = false
    let facts: [(String, String)]
    let onClose: () -> Void
    let onView: () -> Void
    let onCreateAnother: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                TopBarBackButton(systemImage: "xmark", accessibilityLabel: "Close and go to my events", action: onClose)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            ScrollView {
                VStack(spacing: 14) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(Theme.Colors.green600)
                        .frame(width: 96, height: 96)
                        .background(Theme.Colors.green50, in: Circle())
                        .background(Circle().fill(Color(hex: 0xF2FAF5)).padding(-12))
                        .padding(.top, 24)
                        .accessibilityHidden(true)
                    Text(isScheduled ? "Event scheduled" : "Event published")
                        .font(AppFont.jakarta(24, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .padding(.top, 12)
                        .accessibilityAddTraits(.isHeader)
                    Text(message)
                        .font(AppFont.jakarta(15)).foregroundStyle(Theme.Colors.ink700)
                        .multilineTextAlignment(.center).lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: 0) {
                        ForEach(Array(facts.enumerated()), id: \.offset) { index, fact in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(fact.0).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                                    .frame(width: 86, alignment: .leading)
                                Text(fact.1).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 12)
                            .overlay(alignment: .bottom) {
                                if index < facts.count - 1 { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 4)
                    .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 10) {
                EventBarButton(title: String(localized: "View event"), action: onView)
                EventBarButton(title: String(localized: "Create another"), systemImage: "plus", style: .outline, action: onCreateAnother)
                PoweredByFooter()
            }
            .padding(.horizontal, 24).padding(.bottom, 8)
        }
        .background(Theme.Colors.white.ignoresSafeArea())
    }

    private var message: String {
        if let deadline {
            return String(localized: "“\(title)” is live. Invitees can RSVP until \(EventFormat.day(deadline)).")
        }
        return String(localized: "“\(title)” is live for everyone you invited.")
    }
}

struct GalleryPublishedView: View {
    let gallery: EventGallery
    let recipientsLine: String
    let pushSent: Bool
    let onClose: () -> Void
    let onAddMore: () -> Void
    let onViewGallery: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                TopBarBackButton(systemImage: "xmark", accessibilityLabel: "Close, go to the event", action: onClose)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            ScrollView {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.Colors.green600)
                        .frame(width: 76, height: 76)
                        .background(Theme.Colors.green50, in: Circle())
                        .accessibilityHidden(true)
                    Text(gallery.publishedAt.map { $0 > .now } == true ? "Gallery scheduled" : "Gallery published")
                        .font(AppFont.jakarta(22, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .accessibilityAddTraits(.isHeader)
                    Text(gallery.displayTitle).font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink700)
                    HStack(spacing: 8) {
                        stat("\(gallery.photoCount)", String(localized: "Photos"), Theme.Colors.blue50, Theme.Colors.blue700)
                        stat("\(gallery.videoCount)", String(localized: "Videos"), Theme.Colors.chipGrey, Theme.Colors.ink900)
                        stat(EventFormat.count(gallery.audienceCount), String(localized: "People"), Theme.Colors.green50, Theme.Colors.green700)
                    }
                    Text(recipientsLine)
                        .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 6) {
                        if pushSent {
                            Label(String(localized: "Push sent: “Photos from \(gallery.eventTitle) are now available”"), systemImage: "bell")
                        }
                        Label(gallery.allowDownload ? String(localized: "Download allowed") : String(localized: "View only, download off"),
                              systemImage: "arrow.down.to.line")
                        if let cover = gallery.cover {
                            Label(String(localized: "Cover: \(cover.caption.isEmpty ? String(localized: "first photo") : cover.caption)"),
                                  systemImage: "star")
                        }
                    }
                    .font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Theme.Colors.surfaceMuted, in: .rect(cornerRadius: 12))
                }
                .padding(.horizontal, 20).padding(.vertical, 28)
                .frame(maxWidth: .infinity)
                .dashboardCard(radius: 20)
                .padding(.horizontal, 16)
                PoweredByFooter().padding(.top, 8)
            }
            .scrollIndicators(.hidden)

            EventBottomBar {
                EventBarButton(title: String(localized: "Add more"), systemImage: "plus", style: .outline, action: onAddMore)
                EventBarButton(title: String(localized: "View gallery"), systemImage: "photo.on.rectangle", action: onViewGallery)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
    }

    private func stat(_ value: String, _ label: String, _ background: Color, _ foreground: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(AppFont.jakarta(24, .heavy))
            Text(label).font(AppFont.jakarta(12, .bold))
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(background, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Event published") {
    EventPublishedView(title: "Cyber security awareness workshop", deadline: .now.addingTimeInterval(86_400 * 14),
                       facts: [("Audience", "109 invited · 100 students, 9 staff"), ("Venue", "Seminar hall, Block A")],
                       onClose: {}, onView: {}, onCreateAnother: {})
}
