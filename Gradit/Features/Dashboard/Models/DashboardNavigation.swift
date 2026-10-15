//
//  DashboardNavigation.swift
//  Gradit
//
//  Tabs, menu items and feature destinations for each role, taken from the
//  design's BottomNav and the Home menus.
//

import Foundation

/// Every screen a dashboard can open. Screens not built yet show `FeaturePlaceholderView`.
enum DashboardFeature: String, Hashable, CaseIterable, Identifiable {
    case discussionBoard, textMessage, voiceMessage, attendance, assignment, files, noticeBoard
    case events, faculty, courseDetails, categoryCreditPoints, semCreditPoints, examApplication
    case feeDetails, resumeBuilder, placementEvents, placementTraining, markYourAttendance
    case timetable, exams, reports, notifications, search, attendanceReport, freePeriods
    case eventMedia, swapRequest, messages, academics, leaveRequests, raiseConcern

    var id: String { rawValue }

    var title: String {
        switch self {
        case .discussionBoard: String(localized: "Discussion Board")
        case .textMessage: String(localized: "Text Msg")
        case .voiceMessage: String(localized: "Voice Msg")
        case .attendance: String(localized: "Attendance")
        case .assignment: String(localized: "Assignment")
        case .files: String(localized: "Files")
        case .noticeBoard: String(localized: "Notice Board")
        case .events: String(localized: "Events")
        case .faculty: String(localized: "Faculty")
        case .courseDetails: String(localized: "Course Details")
        case .categoryCreditPoints: String(localized: "Category Credit Points")
        case .semCreditPoints: String(localized: "Sem Credit Points")
        case .examApplication: String(localized: "Exam Application Details")
        case .feeDetails: String(localized: "Fee Details")
        case .resumeBuilder: String(localized: "Resume Builder")
        case .placementEvents: String(localized: "Placement Events")
        case .placementTraining: String(localized: "Placement Training")
        case .markYourAttendance: String(localized: "Mark Your Attendance")
        case .timetable: String(localized: "Timetable")
        case .exams: String(localized: "Exams")
        case .reports: String(localized: "Reports")
        case .notifications: String(localized: "Notifications")
        case .search: String(localized: "Search")
        case .attendanceReport: String(localized: "Attendance Report")
        case .freePeriods: String(localized: "Free Periods")
        case .eventMedia: String(localized: "Add Event Media")
        case .swapRequest: String(localized: "Swap Request")
        case .messages: String(localized: "Messages")
        case .academics: String(localized: "Academics")
        case .leaveRequests: String(localized: "Leave Requests")
        case .raiseConcern: String(localized: "Raise a Concern")
        }
    }

    var systemImage: String {
        switch self {
        case .discussionBoard: "bubble.left.and.bubble.right"
        case .textMessage: "text.bubble"
        case .voiceMessage: "mic"
        case .attendance: "calendar.badge.checkmark"
        case .assignment: "book.closed"
        case .files: "folder"
        case .noticeBoard: "megaphone"
        case .events: "calendar"
        case .faculty: "person.2"
        case .courseDetails: "graduationcap"
        case .categoryCreditPoints: "rosette"
        case .semCreditPoints: "chart.bar"
        case .examApplication: "doc.text"
        case .feeDetails: "creditcard"
        case .resumeBuilder: "doc.richtext"
        case .placementEvents: "briefcase"
        case .placementTraining: "target"
        case .markYourAttendance: "person.badge.clock"
        case .timetable: "clock"
        case .exams: "list.clipboard"
        case .reports: "chart.line.uptrend.xyaxis"
        case .notifications: "bell"
        case .search: "magnifyingglass"
        case .attendanceReport: "chart.bar.doc.horizontal"
        case .freePeriods: "clock.badge.exclamationmark"
        case .eventMedia: "photo.on.rectangle"
        case .swapRequest: "arrow.left.arrow.right"
        case .messages: "bubble.left"
        case .academics: "book"
        case .leaveRequests: "calendar.badge.minus"
        case .raiseConcern: "flag"
        }
    }
}

/// A tile in a dashboard menu. The label can differ from the feature title (e.g. "Message").
struct QuickAction: Identifiable, Hashable {
    let feature: DashboardFeature
    let title: String

    init(_ feature: DashboardFeature, title: String? = nil) {
        self.feature = feature
        self.title = title ?? feature.title
    }

    var id: DashboardFeature { feature }
}

/// Menus exactly as ordered in the design.
enum DashboardMenus {
    static let management: [QuickAction] = [
        QuickAction(.discussionBoard), QuickAction(.textMessage, title: String(localized: "Message")),
        QuickAction(.attendance), QuickAction(.assignment), QuickAction(.files),
        QuickAction(.noticeBoard), QuickAction(.events), QuickAction(.faculty),
        QuickAction(.markYourAttendance), QuickAction(.timetable),
    ]

    static let faculty: [QuickAction] = [
        QuickAction(.discussionBoard),
        QuickAction(.textMessage, title: String(localized: "Message")),
        QuickAction(.attendance), QuickAction(.assignment),
        QuickAction(.noticeBoard, title: String(localized: "Notices")),
        QuickAction(.events), QuickAction(.exams), QuickAction(.reports),
    ]

    /// Parent and Student share the same quick access list.
    static let learner: [QuickAction] = [
        QuickAction(.discussionBoard), QuickAction(.textMessage, title: String(localized: "Message")),
        QuickAction(.attendance), QuickAction(.assignment), QuickAction(.files),
        QuickAction(.noticeBoard), QuickAction(.events), QuickAction(.faculty),
        QuickAction(.courseDetails), QuickAction(.semCreditPoints, title: String(localized: "Credit Points")),
        QuickAction(.examApplication), QuickAction(.feeDetails), QuickAction(.resumeBuilder),
        QuickAction(.placementEvents), QuickAction(.placementTraining),
    ]
}

/// Bottom navigation tabs.
enum DashboardTab: String, Hashable, CaseIterable, Identifiable {
    case home, attendance, messages, notices, profile
    case academics, campus, chat, me

    var id: String { rawValue }

    static func tabs(for role: UserRole) -> [DashboardTab] {
        switch role {
        case .management, .faculty: [.home, .attendance, .messages, .notices, .profile]
        case .parent, .student: [.home, .attendance, .notices, .chat, .me]
        }
    }

    var title: String {
        switch self {
        case .home: String(localized: "Home")
        case .attendance: String(localized: "Attendance")
        case .messages: String(localized: "Messages")
        case .notices: String(localized: "Notices")
        case .profile: String(localized: "Profile")
        case .academics: String(localized: "Academics")
        case .campus: String(localized: "Campus")
        case .chat: String(localized: "Discussion")
        case .me: String(localized: "Me")
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .attendance: "calendar.badge.checkmark"
        case .messages: "bubble.left"
        case .chat: "bubble.left.and.bubble.right"
        case .notices: "megaphone"
        case .profile, .me: "person"
        case .academics: "book"
        case .campus: "building.columns"
        }
    }

    /// Feature shown as the tab's root until its real screen is built.
    var placeholderFeature: DashboardFeature {
        switch self {
        case .home: .notifications
        case .attendance: .attendanceReport
        case .messages, .chat: .messages
        case .notices: .noticeBoard
        case .academics: .academics
        case .campus: .events
        case .profile, .me: .notifications
        }
    }
}
