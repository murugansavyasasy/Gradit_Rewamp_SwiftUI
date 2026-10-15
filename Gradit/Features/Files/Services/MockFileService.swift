//
//  MockFileService.swift
//  Gradit
//
//  In-memory files data used in DEBUG, previews and tests. Mirrors filesModule.pdf.
//

import Foundation

final class MockFileService: FileServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    func files() async throws -> [SharedFile] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "f1", name: "Hostel rules 2026–27.pdf", kind: .pdf, typeLabel: "PDF", category: .circular,
                  sizeText: "1.2 MB", dateText: "Scheduled · Fri 09 Oct, 08:00 AM", status: .scheduled,
                  audienceText: "Hostel residents · Students, Parents", author: "Principal's office",
                  viewedCount: 0, totalCount: 0, isNew: false),
            .init(id: "f2", name: "IA 2 timetable and seating – Sem 5 A.pdf", kind: .pdf, typeLabel: "PDF", category: .circular,
                  sizeText: "640 KB", dateText: "Today, 09:40 AM", status: .published,
                  audienceText: "Sem 5 · Division A · Students, Parents", author: "Principal's office",
                  viewedCount: 74, totalCount: 117, isNew: true),
            .init(id: "f3", name: "DBMS Unit 3 – Normalisation notes.pdf", kind: .pdf, typeLabel: "PDF", category: .studyMaterial,
                  sizeText: "2.4 MB", dateText: "06 Oct 2026", status: .published,
                  audienceText: "Sem 5 · Division A, B · Students", author: "Dr. Meena Krishnan",
                  viewedCount: 102, totalCount: 120, isNew: false),
            .init(id: "f4", name: "Lab safety walkthrough.mp4", kind: .video, typeLabel: "Video · MP4", category: .studyMaterial,
                  sizeText: "86 MB", dateText: "05 Oct 2026", status: .published,
                  audienceText: "Sem 3 · All divisions · Students, Staff", author: "Dr. Meena Krishnan",
                  viewedCount: 210, totalCount: 310, isNew: false),
            .init(id: "f5", name: "Annual Day rehearsal – Main stage.jpg", kind: .image, typeLabel: "Image · JPG", category: .gallery,
                  sizeText: "3.1 MB", dateText: "05 Oct 2026", status: .published,
                  audienceText: "All · Students, Parents", author: "Cultural committee",
                  viewedCount: 1200, totalCount: 3880, isNew: false),
            .init(id: "f6", name: "Exam rules – IA 2.docx", kind: .document, typeLabel: "DOCX", category: .circular,
                  sizeText: "180 KB", dateText: "Today, 09:40 AM", status: .published,
                  audienceText: "Sem 5 · Division A · Students", author: "Principal's office",
                  viewedCount: 60, totalCount: 117, isNew: true),
            .init(id: "f7", name: "Placement orientation – Sem 5.pptx", kind: .document, typeLabel: "PPTX", category: .studyMaterial,
                  sizeText: "8.6 MB", dateText: "04 Oct 2026", status: .published,
                  audienceText: "Final year · Students", author: "Placement cell",
                  viewedCount: 88, totalCount: 140, isNew: false),
            .init(id: "f8", name: "Convocation_full.mov", kind: .video, typeLabel: "Video · MOV", category: .gallery,
                  sizeText: "412 MB", dateText: "28 Sep 2026", status: .published,
                  audienceText: "All · Students, Parents, Staff", author: "Media team",
                  viewedCount: 540, totalCount: 3880, isNew: false),
        ]
    }

    func fileDetail(id: String) async throws -> FileDetail {
        try await Task.sleep(for: latency)
        switch id {
        case "f4":
            return FileDetail(id: id, name: "Lab safety walkthrough", kind: .video, typeLabel: "Video · MP4",
                              category: .studyMaterial, folder: "Labs", sizeText: "86 MB", extraText: "04:32",
                              author: "Dr. Meena Krishnan", authorDate: "Dr. Meena Krishnan · 05 Oct 2026",
                              audienceText: "Sem 3 · All divisions · Students, Staff (310)",
                              scheduleText: "Published 05 Oct 2026, 10:00 AM", expiryText: "End of semester · 28 Nov 2026",
                              downloadAllowed: true,
                              description: "Lab_safety_walkthrough.mp4 · a short induction every Sem 3 student must watch before the first lab.",
                              viewedCount: 210, totalCount: 310)
        case "f5":
            return FileDetail(id: id, name: "Annual Day rehearsal – Main stage", kind: .image, typeLabel: "Image · JPG",
                              category: .gallery, folder: "Events 2026", sizeText: "3.1 MB", extraText: "4032 × 3024",
                              author: "Cultural committee", authorDate: "Cultural committee · 05 Oct 2026",
                              audienceText: "All · Students, Parents (3,880)",
                              scheduleText: "Published 05 Oct 2026, 04:15 PM", expiryText: "No expiry", downloadAllowed: true,
                              description: "Annual_Day_rehearsal_main_stage.jpg", viewedCount: 1200, totalCount: 3880)
        default:
            return FileDetail(id: id, name: "IA 2 timetable and seating – Sem 5 A", kind: .pdf, typeLabel: "PDF",
                              category: .circular, folder: "Exams", sizeText: "640 KB", extraText: "3 pages",
                              author: "Principal's office", authorDate: "Principal's office · Today, 09:40 AM",
                              audienceText: "B.E. CSE · Sem 5 · Division A · Students, Parents (117)",
                              scheduleText: "Published today, 09:40 AM", expiryText: "Sat 31 Oct 2026", downloadAllowed: true,
                              description: "IA 2 starts Mon 12 Oct. Please check your hall and seat number. Bring your ID card.",
                              viewedCount: 74, totalCount: 117)
        }
    }

    func folders() async throws -> [FileFolder] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "fo1", name: "Exams", fileCount: 2),
            .init(id: "fo2", name: "CSE · Sem 5", fileCount: 1),
            .init(id: "fo3", name: "Labs", fileCount: 1),
            .init(id: "fo4", name: "Events 2026", fileCount: 4),
            .init(id: "fo5", name: "Hostel", fileCount: 1),
            .init(id: "fo6", name: "Forms", fileCount: 2),
            .init(id: "fo7", name: "Syllabus", fileCount: 1),
            .init(id: "fo8", name: "Staff resources", fileCount: 1),
        ]
    }

    func publish(_ draft: UploadDraft) async throws {
        try await Task.sleep(for: latency)
    }

    func readerFiles(studentID: String?) async throws -> [SharedFile] {
        try await Task.sleep(for: latency)
        return try await files().filter { $0.status == .published }
    }

    func readerFileDetail(id: String, studentID: String?) async throws -> FileDetail {
        try await Task.sleep(for: latency)
        if id == "f3" {
            // View-only (downloads turned off).
            return FileDetail(id: id, name: "DBMS Unit 3 – Normalisation notes", kind: .pdf, typeLabel: "PDF",
                              category: .studyMaterial, folder: "CSE · Sem 5", sizeText: "2.4 MB", extraText: "18 pages",
                              author: "Dr. Meena Krishnan", authorDate: "Dr. Meena Krishnan · 06 Oct 2026",
                              audienceText: "Sem 5 · Division A, B · Students",
                              scheduleText: "Published 06 Oct 2026", expiryText: "No expiry", downloadAllowed: false,
                              description: "Read pages 1–12 before Thursday's class. View only: the teacher has turned off downloads.",
                              viewedCount: 102, totalCount: 120)
        }
        if id == "f7" {
            return FileDetail(id: id, name: "Placement orientation – Sem 5", kind: .document, typeLabel: "PPTX",
                              category: .studyMaterial, folder: "Staff resources", sizeText: "8.6 MB", extraText: "24 slides",
                              author: "Placement cell", authorDate: "Placement cell · 04 Oct 2026",
                              audienceText: "Final year · Students", scheduleText: "Published 04 Oct 2026",
                              expiryText: "No expiry", downloadAllowed: true,
                              description: "Slides from Friday's orientation: eligibility, companies visiting and the training calendar.",
                              viewedCount: 88, totalCount: 140)
        }
        return try await fileDetail(id: id)
    }
}
