//
//  EventFormat.swift
//  Gradit
//
//  Date and number text used across the Events screens ("Sat, 24 Oct · 10:00 AM – 01:00 PM").
//

import Foundation

enum EventFormat {
    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }

    private static let weekdayDay = formatter("EEE, dd MMM")
    private static let weekdayDayYear = formatter("EEE, dd MMM yyyy")
    private static let dayMonth = formatter("dd MMM")
    private static let clock = formatter("hh:mm a")
    private static let shortWeekday = formatter("EEE")
    private static let monthShort = formatter("MMM")
    private static let monthYear = formatter("MMMM yyyy")
    private static let dayNumber = formatter("d")

    /// "Sat, 24 Oct"
    static func day(_ date: Date) -> String { weekdayDay.string(from: date) }

    /// "Sat, 24 Oct 2026"
    static func fullDay(_ date: Date) -> String { weekdayDayYear.string(from: date) }

    /// "24 Oct"
    static func shortDay(_ date: Date) -> String { dayMonth.string(from: date) }

    /// "10:00 AM"
    static func time(_ date: Date) -> String { clock.string(from: date) }

    /// "OCT"
    static func month(_ date: Date) -> String { monthShort.string(from: date).uppercased() }

    /// "October 2026"
    static func monthTitle(_ date: Date) -> String { monthYear.string(from: date) }

    /// "Fri"
    static func weekday(_ date: Date) -> String { shortWeekday.string(from: date) }

    /// "16"
    static func dayOfMonth(_ date: Date) -> String { dayNumber.string(from: date) }

    static func isMultiDay(start: Date, end: Date, calendar: Calendar = .current) -> Bool {
        !calendar.isDate(start, inSameDayAs: end)
    }

    /// "10:00 AM – 01:00 PM" / "All day"
    static func timeRange(start: Date, end: Date, isAllDay: Bool) -> String {
        isAllDay ? String(localized: "All day") : "\(time(start)) – \(time(end))"
    }

    /// Card line: "Today · 03:30 PM – 06:00 PM", "Sat, 24 Oct · 10:00 AM – 01:00 PM", "Mon, 19 Oct – Tue, 20 Oct".
    static func whenLine(start: Date, end: Date, isAllDay: Bool, now: Date = .now, calendar: Calendar = .current) -> String {
        if isMultiDay(start: start, end: end, calendar: calendar) {
            return "\(day(start)) – \(day(end))"
        }
        let dayText = calendar.isDate(start, inSameDayAs: now) ? String(localized: "Today") : day(start)
        return "\(dayText) · \(timeRange(start: start, end: end, isAllDay: isAllDay))"
    }

    /// Detail date line: "Sat, 24 Oct 2026" / "Mon, 19 Oct – Tue, 20 Oct".
    static func dateLine(start: Date, end: Date, calendar: Calendar = .current) -> String {
        isMultiDay(start: start, end: end, calendar: calendar) ? "\(day(start)) – \(day(end))" : fullDay(start)
    }

    /// "today, 02:45 PM" / "yesterday, 09:40 AM" / "06 Oct, 09:00 AM"
    static func stamp(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return String(localized: "today, \(time(date))") }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return String(localized: "yesterday, \(time(date))")
        }
        return "\(shortDay(date)), \(time(date))"
    }

    /// "Ended yesterday, 04:30 PM"
    static func endedLine(_ end: Date, now: Date = .now) -> String {
        String(localized: "Ended \(stamp(end, now: now))")
    }

    /// "2,683" in the Indian grouping used by the design.
    static func count(_ value: Int) -> String {
        value.formatted(.number.locale(Locale(identifier: "en_IN")))
    }

    /// "42 photos · 6 videos"
    static func mediaCount(photos: Int, videos: Int) -> String {
        let p = photos == 1 ? String(localized: "1 photo") : String(localized: "\(photos) photos")
        let v = videos == 1 ? String(localized: "1 video") : String(localized: "\(videos) videos")
        return "\(p) · \(v)"
    }

    /// "64%"
    static func percent(_ part: Int, of whole: Int) -> String {
        guard whole > 0 else { return "0%" }
        return "\(Int((Double(part) * 100 / Double(whole)).rounded()))%"
    }
}
