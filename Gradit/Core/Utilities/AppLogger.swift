//
//  AppLogger.swift
//  Gradit
//

import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Gradit"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
