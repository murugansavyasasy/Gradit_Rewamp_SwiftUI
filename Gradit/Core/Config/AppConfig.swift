//
//  AppConfig.swift
//  Gradit
//

import Foundation

enum AppConfig {
    #if DEBUG
    static let environment = "development"
    static let baseURL = URL(string: "https://dev-api.example.com")!
    /// Runs the app against in-memory mock services until the backend is ready.
    static let useMockServices = true
    #else
    static let environment = "production"
    static let baseURL = URL(string: "https://api.example.com")!
    static let useMockServices = false
    #endif

    // College / legal — replace the placeholders.
    static let collegeName = "University College of Engineering, Chennai"
    static let collegeOfficePhone = "[PHONE NUMBER]"
    static let termsURL = URL(string: "https://example.com/terms")!
    static let privacyURL = URL(string: "https://example.com/privacy")!

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
