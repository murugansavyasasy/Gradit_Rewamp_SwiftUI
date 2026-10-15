//
//  UserRole+UI.swift
//  Gradit
//

import SwiftUI

extension UserRole {
    var title: String {
        switch self {
        case .parent: String(localized: "Parent / Guardian")
        case .student: String(localized: "Student")
        case .faculty: String(localized: "Faculty / Staff")
        case .management: String(localized: "Management / Principal")
        }
    }

    var summary: String {
        switch self {
        case .parent: String(localized: "Follow your child’s attendance, marks, fees and bus")
        case .student: String(localized: "Homework, exams, timetable and messages")
        case .faculty: String(localized: "Mark attendance, share homework, reply to parents")
        case .management: String(localized: "Attendance reports, notices and staff overview")
        }
    }

    /// Used in "Continue as …".
    var shortName: String {
        switch self {
        case .parent: String(localized: "parent")
        case .student: String(localized: "student")
        case .faculty: String(localized: "faculty")
        case .management: String(localized: "principal")
        }
    }

    var systemImage: String {
        switch self {
        case .parent: "person.2"
        case .student: "graduationcap"
        case .faculty: "book"
        case .management: "building.columns"
        }
    }

    var tint: Color {
        switch self {
        case .parent: Theme.Colors.blue600
        case .student, .management: Theme.Colors.green600
        case .faculty: Theme.Colors.warning
        }
    }

    var tintBackground: Color {
        switch self {
        case .parent: Theme.Colors.blue50
        case .student, .management: Theme.Colors.green50
        case .faculty: Theme.Colors.warningBackground
        }
    }
}
