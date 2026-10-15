//
//  NoticeModels.swift
//  Gradit
//
//  Payloads for the Notice Board module: admin/faculty create & manage and the
//  student/parent reader views. Design: NoticeBoard.pdf.
//

import SwiftUI

// MARK: - Status & category

nonisolated enum NoticeStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case published, scheduled, draft, expired
    var id: String { rawValue }
    var title: String {
        switch self {
        case .published: String(localized: "Published")
        case .scheduled: String(localized: "Scheduled")
        case .draft: String(localized: "Draft")
        case .expired: String(localized: "Expired")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = NoticeStatus(rawValue: raw) ?? .published
    }
}

nonisolated enum NoticeCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case general, academic, exam, fees, holiday, event, urgent
    var id: String { rawValue }
    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .academic: String(localized: "Academic")
        case .exam: String(localized: "Exam")
        case .fees: String(localized: "Fees")
        case .holiday: String(localized: "Holiday")
        case .event: String(localized: "Event")
        case .urgent: String(localized: "Urgent")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = NoticeCategory(rawValue: raw) ?? .general
    }
}

// MARK: - Admin list

nonisolated struct NoticeItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let status: NoticeStatus
    let category: NoticeCategory
    let pinned: Bool
    let audienceText: String          // "B.E. CSE Sem 5 A, B · Students, Parents"
    let dateText: String              // "Published Today, 02:30 PM" / "Scheduled 14 Oct, 08:00 AM"
    let attachmentCount: Int
    let readCount: Int
    let totalCount: Int

    var progress: Double { totalCount > 0 ? Double(readCount) / Double(totalCount) : 0 }
    var progressPercentText: String { "\(Int((progress * 100).rounded()))%" }
}

// MARK: - Detail (admin + reader)

nonisolated struct NoticeDetail: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let status: NoticeStatus
    let category: NoticeCategory
    let pinned: Bool
    let authorName: String
    let authorRole: String            // "Principal" / "HoD · CSE"
    let audienceText: String
    let publishedText: String         // "Wed, 07 Oct 2026 · 02:30 PM · by you"
    let expiresText: String?          // "Mon, 26 Oct 2026 · pinned until then"
    let notifiedBy: String            // "Push and SMS"
    let message: String
    let attachments: [AssignmentAttachment]
    let readCount: Int
    let totalCount: Int

    var isExpired: Bool { status == .expired }
}

// MARK: - Reader list

nonisolated struct ReaderNotice: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let preview: String
    let category: NoticeCategory
    let pinned: Bool
    let isNew: Bool
    var isUnread: Bool
    let isExpired: Bool
    let authorName: String
    let authorRole: String
    let timeText: String              // "Today, 07:30 AM"
    let attachmentCount: Int
    let section: String               // "PINNED" / "TODAY" / "EARLIER"
}

// MARK: - Create

nonisolated struct NoticeDraft: Codable, Sendable {
    var title: String
    var message: String
    var category: NoticeCategory
    var highPriority: Bool
    var toStudents: Bool
    var toParents: Bool
    var toStaff: Bool
    var classLabel: String
    var section: String
    var attachmentNames: [String]
    var pinned: Bool
    var expiryText: String
    var scheduled: Bool
}
