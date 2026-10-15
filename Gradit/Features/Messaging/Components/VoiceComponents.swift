//
//  VoiceComponents.swift
//  Gradit
//
//  Reusable voice-note UI: a bar waveform and the inline mini player used in
//  message cards. Shared by the inbox and the voice-message detail screen.
//

import SwiftUI

/// Bar waveform with a played/unplayed split driven by `progress` (0...1).
struct VoiceWaveform: View {
    var progress: Double = 0
    var activeColor: Color = Theme.Colors.blue600
    var inactiveColor: Color = Theme.Colors.blueBorderLight
    var height: CGFloat = 40

    private let bars: [CGFloat] = [8, 16, 24, 12, 28, 20, 10, 22, 32, 18, 12, 26, 16, 10,
                                   20, 30, 14, 22, 12, 24, 18, 28, 14, 20, 10, 16, 24, 12]

    var body: some View {
        GeometryReader { proxy in
            let playedWidth = proxy.size.width * progress
            HStack(spacing: 3) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, value in
                    Capsule().frame(height: value)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(inactiveColor)
            .overlay(alignment: .leading) {
                HStack(spacing: 3) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { _, value in
                        Capsule().frame(height: value)
                    }
                }
                .frame(width: proxy.size.width)
                .foregroundStyle(activeColor)
                .mask(alignment: .leading) {
                    Rectangle().frame(width: playedWidth)
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Non-interactive inline player shown on a voice message card; tapping the card opens detail.
struct MiniVoicePlayer: View {
    let duration: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "play.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.white)
                .frame(width: 36, height: 36)
                .background(Theme.Colors.blue600, in: Circle())
            Capsule()
                .fill(Theme.Colors.line)
                .frame(height: 4)
                .overlay(alignment: .leading) {
                    Capsule().fill(Theme.Colors.blue600).frame(width: 6)
                }
            Text(duration)
                .font(AppFont.jakarta(12, .bold))
                .foregroundStyle(Theme.Colors.ink500)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Voice note, \(duration). Open to play.")
    }
}

#Preview {
    VStack(spacing: 24) {
        VoiceWaveform(progress: 0.4)
        MiniVoicePlayer(duration: "0:12")
    }
    .padding()
}
