//
//  Theme.swift
//  Gradit
//

import SwiftUI

/// Tokens from the "College App — Mobile UI" design system (00 Design System › Foundations).
enum Theme {
    enum Colors {
        // Primary · Blue
        static let blue700 = Color(hex: 0x1B44B0)
        static let blue600 = Color(hex: 0x2453D4)
        static let blue500 = Color(hex: 0x4A74E6)
        static let blue100 = Color(hex: 0xDCE5FB)
        static let blue50 = Color(hex: 0xEFF3FD)

        // Secondary · Green
        static let green700 = Color(hex: 0x0B6B40)
        static let green600 = Color(hex: 0x0F7A4A)
        static let green100 = Color(hex: 0xCBEBD9)
        static let green50 = Color(hex: 0xE8F6EE)

        // Neutrals
        static let ink900 = Color(hex: 0x101828)
        static let ink700 = Color(hex: 0x344054)
        static let ink500 = Color(hex: 0x5B6577)
        static let ink300 = Color(hex: 0xC5CBD6)
        static let border = Color(hex: 0xD0D6E0)
        static let line = Color(hex: 0xE4E8EF)
        static let surfaceMuted = Color(hex: 0xF5F7FA)
        static let white = Color.white

        // Status
        static let warning = Color(hex: 0xA15C07)
        static let warningBackground = Color(hex: 0xFDF3E1)
        static let error = Color(hex: 0xC2352F)
        static let errorBackground = Color(hex: 0xFCECEB)

        // Dashboard accents
        static let blue800 = Color(hex: 0x173A9C)
        static let amber800 = Color(hex: 0x8A4E05)
        static let red700 = Color(hex: 0xA82C27)
        static let red800 = Color(hex: 0x7A2420)
        static let amberBorder = Color(hex: 0xE9C98F)
        static let blueBorder = Color(hex: 0x9DB1E8)
        static let blueBorderLight = Color(hex: 0xB7C6EF)
        static let divider = Color(hex: 0xEEF1F5)

        // Profile & Settings
        static let ink600 = Color(hex: 0x475467)
        static let cardBorder = Color(hex: 0xEAECF0)
        static let chevron = Color(hex: 0x98A2B3)
        static let inputBorder = Color(hex: 0xD0D5DD)
        static let destructive = Color(hex: 0xC8312A)
        static let destructiveStrong = Color(hex: 0xD2372F)

        // Semantic aliases
        static let accent = blue600
        static let background = white
        static let surface = surfaceMuted
        static let textPrimary = ink900
        static let textSecondary = ink700
        static let textTertiary = ink500
        static let success = green600
    }

    /// 8-pt grid.
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let s12: CGFloat = 12
        static let md: CGFloat = 16
        static let s20: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 8       // chip
        static let md: CGFloat = 12      // input
        static let button: CGFloat = 14
        static let card: CGFloat = 16
        static let lg: CGFloat = 20
        static let sheet: CGFloat = 24
        static let input: CGFloat = md
    }

    enum Typography {
        static let display = AppFont.jakarta(28, .heavy)      // 28/34 ExtraBold
        static let heading1 = AppFont.jakarta(22, .bold)      // 22/28 Bold
        static let heading2 = AppFont.jakarta(18, .bold)      // 18/24 Bold
        static let title = AppFont.jakarta(16, .semibold)     // 16/22 SemiBold
        static let body = AppFont.jakarta(15)                 // 15/22 Regular
        static let label = AppFont.jakarta(14, .semibold)
        static let small = AppFont.jakarta(13, .medium)       // 13/18 Medium
        static let caption = AppFont.jakarta(12, .bold)       // 12/16 Bold
        static let button = AppFont.jakarta(16, .bold)

        static let largeTitle = display
    }
}
