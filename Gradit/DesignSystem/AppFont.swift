//
//  AppFont.swift
//  Gradit
//

import SwiftUI
import CoreText
internal import os

/// Plus Jakarta Sans (variable font, bundled in Resources/Fonts).
/// Registered at runtime so no Info.plist `UIAppFonts` entry is needed.
enum AppFont {
    static let family = "Plus Jakarta Sans"

    static func registerFonts() {
        guard let url = Bundle.main.url(forResource: "PlusJakartaSans", withExtension: "ttf") else {
            AppLogger.ui.error("PlusJakartaSans.ttf is missing from the app bundle")
            return
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            // Fails harmlessly if the font is already registered (e.g. in previews).
            AppLogger.ui.debug("Font registration: \(String(describing: error?.takeRetainedValue()))")
        }
    }

    /// Scales with Dynamic Type relative to `.body`.
    static func jakarta(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(family, size: size).weight(weight)
    }
}
