//
//  FileModels.swift
//  Gradit
//
//  Payloads for the Files module: admin/faculty upload & manage and the
//  student/parent viewer. Design: filesModule.pdf.
//

import SwiftUI

// MARK: - Kind & category

nonisolated enum FileKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case image, pdf, document, video
    var id: String { rawValue }

    /// Tab label (plural).
    var tabTitle: String {
        switch self {
        case .image: String(localized: "Images")
        case .pdf: String(localized: "PDFs")
        case .document: String(localized: "Documents")
        case .video: String(localized: "Videos")
        }
    }
    /// Short type badge, e.g. "PDF", "Image", "Video", "DOCX" (overridden by `typeLabel`).
    var badge: String {
        switch self {
        case .image: "Image"
        case .pdf: "PDF"
        case .document: "Document"
        case .video: "Video"
        }
    }
    var systemImage: String {
        switch self {
        case .image: "photo.fill"
        case .pdf: "doc.fill"
        case .document: "doc.text.fill"
        case .video: "video.fill"
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FileKind(rawValue: raw) ?? .document
    }
}

nonisolated enum FileCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case circular, studyMaterial, syllabus, questionPaper, forms, gallery, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .circular: String(localized: "Circular")
        case .studyMaterial: String(localized: "Study material")
        case .syllabus: String(localized: "Syllabus")
        case .questionPaper: String(localized: "Question paper")
        case .forms: String(localized: "Forms")
        case .gallery: String(localized: "Gallery")
        case .other: String(localized: "Other")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FileCategory(rawValue: raw) ?? .other
    }
}

nonisolated enum FileStatus: String, Codable, Sendable {
    case published, scheduled, draft
    var title: String {
        switch self {
        case .published: String(localized: "Published")
        case .scheduled: String(localized: "Scheduled")
        case .draft: String(localized: "Draft")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FileStatus(rawValue: raw) ?? .published
    }
}

// MARK: - List item

nonisolated struct SharedFile: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String                  // "Hostel rules 2026–27.pdf"
    let kind: FileKind
    let typeLabel: String             // "PDF" / "DOCX" / "Image · JPG" / "Video · MP4"
    let category: FileCategory
    let sizeText: String              // "1.2 MB"
    let dateText: String              // "Fri 09 Oct, 08:00 AM" / "Today, 09:40 AM"
    let status: FileStatus
    let audienceText: String          // "Hostel residents · Students, Parents"
    let author: String                // "Principal's office"
    let viewedCount: Int
    let totalCount: Int
    let isNew: Bool                   // reader "New" badge

    var progress: Double { totalCount > 0 ? Double(viewedCount) / Double(totalCount) : 0 }
}

// MARK: - Detail

nonisolated struct FileDetail: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let kind: FileKind
    let typeLabel: String
    let category: FileCategory
    let folder: String
    let sizeText: String
    let extraText: String             // "3 pages" / "04:32" / "24 slides" / "4032 × 3024"
    let author: String
    let authorDate: String            // "Principal's office · Today, 09:40 AM"
    let audienceText: String
    let scheduleText: String          // "Published today, 09:40 AM"
    let expiryText: String            // "Sat 31 Oct 2026" / "No expiry" / "End of semester · 28 Nov 2026"
    let downloadAllowed: Bool
    let description: String
    let viewedCount: Int
    let totalCount: Int
}

// MARK: - Folders

nonisolated struct FileFolder: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    let fileCount: Int
}

// MARK: - Upload

nonisolated struct UploadDraft: Codable, Sendable {
    var fileNames: [String]
    var title: String
    var description: String
    var category: FileCategory
    var toStudents: Bool
    var toParents: Bool
    var toStaff: Bool
    var classLabel: String
    var section: String
    var folder: String
    var expiryText: String
    var downloadAllowed: Bool
}
