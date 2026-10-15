//
//  DashboardFormatting.swift
//  Gradit
//

import SwiftUI

enum DashboardGreeting {
    private static let honorifics: Set<String> = ["dr", "dr.", "prof", "prof.", "mr", "mr.", "mrs", "mrs.", "ms", "ms."]

    /// "Good morning, Dr. Suresh"
    static func text(name: String, date: Date = .now, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        let salutation: String
        switch hour {
        case ..<12: salutation = String(localized: "Good morning")
        case ..<17: salutation = String(localized: "Good afternoon")
        default: salutation = String(localized: "Good evening")
        }
        let short = shortName(name)
        return short.isEmpty ? salutation : "\(salutation), \(short)"
    }

    /// "Rajesh Sharma" → "Rajesh", "Dr. Suresh Kumar" → "Dr. Suresh"
    static func shortName(_ fullName: String) -> String {
        let parts = fullName.split(separator: " ").map(String.init)
        guard let first = parts.first else { return "" }
        if honorifics.contains(first.lowercased()), parts.count > 1 {
            return "\(first) \(parts[1])"
        }
        return first
    }

    /// "Dr. Meena Iyer" → "MI"
    static func initials(_ fullName: String) -> String {
        let parts = fullName
            .split(separator: " ")
            .map(String.init)
            .filter { !honorifics.contains($0.lowercased()) && !$0.hasPrefix("(") }
        let letters = [parts.first, parts.count > 1 ? parts.last : nil].compactMap { $0?.first }
        return String(letters).uppercased()
    }
}

enum DashboardFormat {
    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }

    private static let dayMonth = formatter("d MMM")
    private static let weekdayDayMonth = formatter("EEE, d MMM")
    private static let timeFormatter = formatter("HH:mm")

    /// "9 OCT"
    static func eventDate(_ date: Date) -> String { dayMonth.string(from: date).uppercased() }

    /// "15 Oct"
    static func shortDate(_ date: Date) -> String { dayMonth.string(from: date) }

    /// "10:24"
    static func time(_ date: Date) -> String { timeFormatter.string(from: date) }

    /// "Due today" / "Due Thu, 8 Oct"
    static func dueLabel(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return String(localized: "Due today") }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return String(localized: "Due tomorrow")
        }
        return String(localized: "Due \(weekdayDayMonth.string(from: date))")
    }

    static func isDueSoon(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.isDate(date, inSameDayAs: now) || date < now
    }

    /// "₹24,500"
    static func currency(_ amount: Decimal, code: String) -> String {
        amount.formatted(
            .currency(code: code)
                .precision(.fractionLength(0))
                .locale(Locale(identifier: code == "INR" ? "en_IN" : "en_US"))
        )
    }

    /// "87.3%" / "92%"
    static func percent(_ value: Double) -> String {
        value.rounded() == value
            ? "\(Int(value))%"
            : String(format: "%.1f%%", value)
    }
}

extension UserRole {
    /// Badge next to the greeting.
    var badgeTitle: String {
        switch self {
        case .parent: String(localized: "Parent")
        case .student: String(localized: "Student")
        case .faculty: String(localized: "Teacher")
        case .management: String(localized: "Principal")
        }
    }

    var badgeColor: Color {
        switch self {
        case .parent: Theme.Colors.blue600
        case .student: Theme.Colors.ink900
        case .faculty: Theme.Colors.green700
        case .management: Theme.Colors.amber800
        }
    }
}
