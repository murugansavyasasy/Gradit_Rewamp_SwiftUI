//
//  MockNoticeService.swift
//  Gradit
//
//  In-memory notice data used in DEBUG, previews and tests. Mirrors NoticeBoard.pdf.
//

import Foundation

final class MockNoticeService: NoticeServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    // MARK: - Admin

    func notices() async throws -> [NoticeItem] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "n1", title: "Mid-semester model exams – timetable", status: .published, category: .exam,
                  pinned: true, audienceText: "B.E. CSE Sem 5 A, B · Students, Parents",
                  dateText: "Published Today, 02:30 PM", attachmentCount: 2, readCount: 0, totalCount: 198),
            .init(id: "n2", title: "Internal Assessment 2 – hall tickets and timetable", status: .published, category: .exam,
                  pinned: true, audienceText: "B.E. CSE Sem 5 A, B · Students, Parents",
                  dateText: "Published Today, 09:00 AM", attachmentCount: 2, readCount: 150, totalCount: 198),
            .init(id: "n3", title: "College closed on 8 Oct due to heavy rain", status: .published, category: .holiday,
                  pinned: true, audienceText: "All students, parents and staff",
                  dateText: "Published Today, 07:30 AM", attachmentCount: 0, readCount: 420, totalCount: 480),
            .init(id: "n4", title: "Placement drive: Zoho registration closes 10 Oct", status: .published, category: .event,
                  pinned: false, audienceText: "Final & pre-final year · Students",
                  dateText: "Published 06 Oct, 11:00 AM", attachmentCount: 1, readCount: 88, totalCount: 140),
            .init(id: "n5", title: "Fee payment reminder – semester 5", status: .published, category: .fees,
                  pinned: false, audienceText: "B.E. CSE Sem 5 · Students, Parents",
                  dateText: "Published 05 Oct, 10:00 AM", attachmentCount: 0, readCount: 160, totalCount: 198),
            .init(id: "n6", title: "Guest lecture: AI in healthcare", status: .scheduled, category: .academic,
                  pinned: false, audienceText: "B.E. CSE Sem 5, 7 · Students",
                  dateText: "Scheduled 14 Oct, 08:00 AM", attachmentCount: 1, readCount: 0, totalCount: 220),
            .init(id: "n7", title: "Library overdue books – clear before exams", status: .draft, category: .general,
                  pinned: false, audienceText: "Not set yet",
                  dateText: "Draft · edited 06 Oct", attachmentCount: 0, readCount: 0, totalCount: 0),
            .init(id: "n8", title: "Techfest '26 – call for papers", status: .expired, category: .event,
                  pinned: false, audienceText: "All students · CSE",
                  dateText: "Expired 05 Oct 2026", attachmentCount: 1, readCount: 300, totalCount: 480),
        ]
    }

    func notice(id: String) async throws -> NoticeDetail {
        try await Task.sleep(for: latency)
        if id == "n2" {
            return NoticeDetail(
                id: id, title: "Internal Assessment 2 – hall tickets and timetable", status: .published,
                category: .exam, pinned: true, authorName: "Dr. Suresh Kumar", authorRole: "Principal",
                audienceText: "198 recipients · B.E. CSE Sem 5 A, B · Students, Parents",
                publishedText: "Wed, 07 Oct 2026 · 09:00 AM · by you",
                expiresText: "Fri, 16 Oct 2026 · pinned until then", notifiedBy: "Push and SMS",
                message: "Internal Assessment 2 for all B.E. CSE Sem 5 students will be held from Mon, 12 Oct to Fri, 16 Oct 2026.\n\nHall tickets are mandatory. Students without a hall ticket will not be allowed into the exam hall.\n\n• Download your hall ticket from the student portal before Sat, 10 Oct.\n• Report to your exam hall 15 minutes before the start time.\n• Bring your college ID card and a blue or black pen.\n\nThe timetable and seating plan are attached.",
                attachments: [
                    AssignmentAttachment(id: "f1", name: "IA2_hall_tickets.pdf", kind: .pdf, detail: "PDF · 320 KB"),
                    AssignmentAttachment(id: "f2", name: "IA2_timetable.pdf", kind: .pdf, detail: "PDF · 210 KB"),
                ],
                readCount: 150, totalCount: 198)
        }
        return NoticeDetail(
            id: id, title: "Mid-semester model exams – timetable", status: .published, category: .exam, pinned: true,
            authorName: "Dr. Suresh Kumar", authorRole: "Principal",
            audienceText: "198 recipients · B.E. CSE Sem 5 A, B · Students, Parents",
            publishedText: "Wed, 07 Oct 2026 · 02:30 PM · by you",
            expiresText: "Mon, 26 Oct 2026 · pinned until then", notifiedBy: "Push and SMS",
            message: "Model exams for B.E. CSE Sem 5 (Sections A and B) start on Monday, 26 Oct 2026.\n\nStudents must have at least 75% attendance to sit the model exams.\n\n• Exams run from 10:00 AM to 01:00 PM.\n• Carry your hall ticket and ID card.\n• No electronic devices in the exam hall.",
            attachments: [AssignmentAttachment(id: "f1", name: "Model_exam_timetable.pdf", kind: .pdf, detail: "PDF · 420 KB")],
            readCount: 0, totalCount: 198)
    }

    func publish(_ draft: NoticeDraft) async throws {
        try await Task.sleep(for: latency)
    }

    // MARK: - Reader

    func readerNotices(studentID: String?) async throws -> [ReaderNotice] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "n3", title: "College closed on 8 Oct due to heavy rain",
                  preview: "Following the IMD red alert for Chennai, the college will remain closed on Thursday, 8 Oct. Online classes will run…",
                  category: .holiday, pinned: true, isNew: true, isUnread: true, isExpired: false,
                  authorName: "Dr. Suresh Kumar", authorRole: "Principal", timeText: "Today, 07:30 AM",
                  attachmentCount: 0, section: "PINNED"),
            .init(id: "n2", title: "Internal Assessment 2 – hall tickets and timetable",
                  preview: "IA2 for all Sem 5 students runs from 12 to 16 Oct. Download your hall ticket from the student portal…",
                  category: .exam, pinned: true, isNew: true, isUnread: true, isExpired: false,
                  authorName: "Dr. Suresh Kumar", authorRole: "Principal", timeText: "Today, 09:00 AM",
                  attachmentCount: 2, section: "PINNED"),
            .init(id: "n4", title: "Placement drive: Zoho registration closes 10 Oct",
                  preview: "Final-year and pre-final-year CSE and IT students can register for the Zoho placement drive before 10 Oct.",
                  category: .event, pinned: false, isNew: true, isUnread: true, isExpired: false,
                  authorName: "Prakash V.", authorRole: "HoD · CSE", timeText: "Today, 11:00 AM",
                  attachmentCount: 1, section: "TODAY"),
            .init(id: "n5", title: "Fee payment reminder – semester 5",
                  preview: "The last date to pay the semester 5 tuition fee without a late charge is Fri, 10 Oct 2026.",
                  category: .fees, pinned: false, isNew: false, isUnread: false, isExpired: false,
                  authorName: "Accounts office", authorRole: "Administration", timeText: "05 Oct, 10:00 AM",
                  attachmentCount: 0, section: "EARLIER"),
            .init(id: "n8", title: "Techfest '26 – call for papers",
                  preview: "Submit abstracts for the national-level technical symposium Techfest '26 by Monday, 5 Oct 2026.",
                  category: .event, pinned: false, isNew: false, isUnread: false, isExpired: true,
                  authorName: "Dr. Prakash V.", authorRole: "HoD · CSE", timeText: "28 Sep, 03:00 PM",
                  attachmentCount: 1, section: "EARLIER"),
        ]
    }

    func readerNotice(id: String, studentID: String?) async throws -> NoticeDetail {
        try await Task.sleep(for: latency)
        switch id {
        case "n3":
            return NoticeDetail(
                id: id, title: "College closed on 8 Oct due to heavy rain", status: .published, category: .holiday,
                pinned: true, authorName: "Dr. Suresh Kumar", authorRole: "Principal", audienceText: "",
                publishedText: "Wed, 07 Oct 2026 · 07:30 AM", expiresText: nil, notifiedBy: "Push and SMS",
                message: "Following the IMD red alert for Chennai, the college will remain closed on Thursday, 8 Oct 2026.\n\nOnline classes will run as per the regular timetable.\n\nCollege buses will not operate. Hostel students should stay inside the campus.",
                attachments: [], readCount: 0, totalCount: 0)
        case "n8":
            return NoticeDetail(
                id: id, title: "Techfest '26 – call for papers", status: .expired, category: .event, pinned: false,
                authorName: "Dr. Prakash V.", authorRole: "HoD · CSE", audienceText: "",
                publishedText: "Mon, 28 Sep 2026 · 03:00 PM", expiresText: "Expired on 05 Oct 2026. Kept here for reference.",
                notifiedBy: "Push", message: "Submit abstracts for the national-level technical symposium Techfest '26 by Monday, 5 Oct 2026.\n\n• Teams of up to 3 students\n• Best paper in each track wins ₹5,000",
                attachments: [AssignmentAttachment(id: "f1", name: "Techfest26_brochure.pdf", kind: .pdf, detail: "PDF · 1.4 MB")],
                readCount: 0, totalCount: 0)
        default:
            return try await notice(id: id)
        }
    }

    func markRead(id: String, read: Bool) async throws {
        try await Task.sleep(for: latency)
    }
}
