//
//  AppLanguage.swift
//  Gradit
//

import Foundation

/// Languages offered on the Login › Choose language sheet.
/// Stored with `@AppStorage(AppLanguage.storageKey)`.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case hindi = "hi"
    case tamil = "ta"
    case telugu = "te"
    case kannada = "kn"
    case malayalam = "ml"
    case marathi = "mr"
    case bengali = "bn"

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .english: "English"
        case .hindi: "हिन्दी"
        case .tamil: "தமிழ்"
        case .telugu: "తెలుగు"
        case .kannada: "ಕನ್ನಡ"
        case .malayalam: "മലയാളം"
        case .marathi: "मराठी"
        case .bengali: "বাংলা"
        }
    }

    var englishName: String {
        switch self {
        case .english: "English"
        case .hindi: "Hindi"
        case .tamil: "Tamil"
        case .telugu: "Telugu"
        case .kannada: "Kannada"
        case .malayalam: "Malayalam"
        case .marathi: "Marathi"
        case .bengali: "Bengali"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }
}
