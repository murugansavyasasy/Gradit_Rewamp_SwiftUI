//
//  MockAssignmentService.swift
//  Gradit
//
//  In-memory assignment data used in DEBUG, previews and tests.
//  Numbers mirror assignment.pdf.
//

import Foundation

final class MockAssignmentService: AssignmentServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    // MARK: - Faculty

    func facultyAssignments() async throws -> [FacultyAssignment] {
        try await Task.sleep(for: latency)
        return [
            FacultyAssignment(
                id: "a1", title: "Transactions and concurrency control – case study",
                subject: "DBMS", classLabel: "B.E. CSE · Sem 5 A", status: .active,
                primaryLabel: String(localized: "Posted"), primaryText: "Today, 10:20 AM",
                dueText: "Fri, 16 Oct · 11:59 PM", submittedCount: 0, totalCount: 58, note: nil),
            FacultyAssignment(
                id: "a2", title: "Indexing and B+ trees problem set",
                subject: "DBMS", classLabel: "B.E. CSE · Sem 5 A", status: .draft,
                primaryLabel: String(localized: "Draft"), primaryText: "Edited 06 Oct",
                dueText: "Tue, 20 Oct · 11:59 PM", submittedCount: nil, totalCount: 58,
                note: String(localized: "Not visible to students yet")),
            FacultyAssignment(
                id: "a3", title: "Stored procedures and triggers lab",
                subject: "DBMS Lab", classLabel: "B.E. CSE · Sem 5 B", status: .scheduled,
                primaryLabel: String(localized: "Scheduled"), primaryText: "Sends 14 Oct, 08:00 AM",
                dueText: "Fri, 23 Oct · 11:59 PM", submittedCount: nil, totalCount: 42, note: nil),
            FacultyAssignment(
                id: "a4", title: "Normalization worksheet – 3NF and BCNF",
                subject: "DBMS", classLabel: "B.E. CSE · Sem 5 B", status: .pastDue,
                primaryLabel: String(localized: "Posted"), primaryText: "28 Sep 2026",
                dueText: "Mon, 05 Oct · 11:59 PM", submittedCount: 30, totalCount: 42, note: nil),
            FacultyAssignment(
                id: "a5", title: "ER modelling mini project",
                subject: "DBMS", classLabel: "B.E. CSE · Sem 5 A", status: .active,
                primaryLabel: String(localized: "Posted"), primaryText: "02 Oct, 09:00 AM",
                dueText: "Thu, 22 Oct · 11:59 PM", submittedCount: 18, totalCount: 58, note: nil),
            FacultyAssignment(
                id: "a6", title: "SQL joins – lab record",
                subject: "DBMS Lab", classLabel: "B.E. CSE · Sem 5 B", status: .pastDue,
                primaryLabel: String(localized: "Posted"), primaryText: "29 Sep 2026",
                dueText: "Fri, 09 Oct · 04:00 PM", submittedCount: 38, totalCount: 42, note: nil),
            FacultyAssignment(
                id: "a7", title: "Relational algebra practice",
                subject: "DBMS", classLabel: "B.E. CSE · Sem 5 A", status: .active,
                primaryLabel: String(localized: "Posted"), primaryText: "04 Oct, 11:00 AM",
                dueText: "Mon, 19 Oct · 11:59 PM", submittedCount: 9, totalCount: 58, note: nil),
            FacultyAssignment(
                id: "a8", title: "Query optimisation reading response",
                subject: "DBMS", classLabel: "B.E. CSE · Sem 5 A", status: .pastDue,
                primaryLabel: String(localized: "Posted"), primaryText: "20 Sep 2026",
                dueText: "Wed, 30 Sep · 11:59 PM", submittedCount: 55, totalCount: 58, note: nil),
        ]
    }

    func assignmentDetail(id: String) async throws -> AssignmentDetail {
        try await Task.sleep(for: latency)
        if id == "a1" {
            return AssignmentDetail(
                id: "a1", title: "Transactions and concurrency control – case study",
                subject: "DBMS", status: .active,
                dueText: "Fri, 16 Oct 2026 · 11:59 PM", dueNote: String(localized: "in 9 days"),
                recipientsText: "All 58 students · B.E. CSE · Sem 5 A",
                maxMarks: 20, postedText: String(localized: "posted today, 10:20 AM"),
                description: "Read the railway reservation case study. Identify two schedules that cause lost updates, then show how two-phase locking prevents them. Answer in 2–3 pages.",
                attachments: [
                    AssignmentAttachment(id: "f1", name: "Case_study_brief.pdf", kind: .pdf, detail: "PDF · 1.2 MB"),
                    AssignmentAttachment(id: "f2", name: "Rubric.docx", kind: .document, detail: "Document · 85 KB"),
                    AssignmentAttachment(id: "f3", name: "Marking_scheme.m4a", kind: .voice, detail: "Voice note · 0:48"),
                ],
                submittedCount: 0, notSubmittedCount: 58, lateCount: 0, gradedCount: 0,
                students: Self.roster(maxMarks: 20, allPending: true))
        }
        // Default: the past-due "Normalization worksheet" detail (p11).
        return AssignmentDetail(
            id: id, title: "Normalization worksheet – 3NF and BCNF",
            subject: "DBMS", status: .pastDue,
            dueText: "Mon, 05 Oct 2026 · 11:59 PM",
            dueNote: String(localized: "2 days ago · late submissions open"),
            recipientsText: "All 42 students · B.E. CSE · Sem 5 B",
            maxMarks: 20, postedText: String(localized: "posted 28 Sep 2026"),
            description: "Normalize the three relations in the worksheet up to BCNF. For each step, list the functional dependencies and explain which normal form is violated.",
            attachments: [
                AssignmentAttachment(id: "f1", name: "Normalization_worksheet.pdf", kind: .pdf, detail: "PDF · 1.2 MB"),
                AssignmentAttachment(id: "f2", name: "FD_examples.png", kind: .image, detail: "Image · 640 KB"),
            ],
            submittedCount: 30, notSubmittedCount: 12, lateCount: 4, gradedCount: 18,
            students: Self.roster(maxMarks: 20, allPending: false))
    }

    func classStudents(department: String, yearSem: String, section: String) async throws -> [AssignmentSubmission] {
        try await Task.sleep(for: latency)
        return Self.roster(maxMarks: 20, allPending: true)
    }

    func saveGrade(assignmentID: String, submissionID: String, marks: Int, comment: String) async throws {
        try await Task.sleep(for: latency)
    }

    func publish(_ draft: NewAssignmentDraft) async throws {
        try await Task.sleep(for: latency)
    }

    private static func roster(maxMarks: Int, allPending: Bool) -> [AssignmentSubmission] {
        let people: [(String, String)] = [
            ("Aakash M.", "2024503101"), ("Deepak K.", "2024503012"), ("Indhu R.", "2024503021"),
            ("Mukesh P.", "2024503033"), ("Pavithra R.", "2024503036"), ("Rahul Kumar", "2024503039"),
            ("Sneha Nair", "2024503046"), ("Surya P.", "2024503049"), ("Vishal B.", "2024503058"),
            ("Yamini S.", "2024503061"),
        ]
        return people.enumerated().map { index, person in
            let state: SubmissionState = allPending
                ? .notSubmitted
                : (index < 3 ? .graded : (index < 6 ? .toGrade : (index == 6 ? .late : .notSubmitted)))
            let submitted: String? = {
                switch state {
                case .graded, .toGrade: "Submitted on time · 04 Oct, 09:42 PM"
                case .late: "Submitted late · 06 Oct, 08:10 AM"
                case .notSubmitted: nil
                }
            }()
            let files: [AssignmentAttachment] = state == .notSubmitted ? [] : [
                AssignmentAttachment(id: "s\(index)a", name: "Normalization_\(person.0.split(separator: " ").first ?? "work").pdf", kind: .pdf, detail: "PDF · 1.8 MB"),
                AssignmentAttachment(id: "s\(index)b", name: "Bonus_4NF.jpg", kind: .image, detail: "Image · 920 KB"),
            ]
            return AssignmentSubmission(
                id: "sub\(index)", studentName: person.0, registerNo: person.1,
                classLabel: "Sem 5 B", state: state, submittedText: submitted,
                files: files,
                comment: state == .notSubmitted ? nil : "Ma'am, I attempted the bonus question on 4NF as well.",
                marks: state == .graded ? 17 : nil, maxMarks: maxMarks)
        }
    }

    // MARK: - Learner

    func learnerAssignments(studentID: String?) async throws -> [LearnerAssignment] {
        try await Task.sleep(for: latency)
        return [
            LearnerAssignment(id: "a4", title: "Normalization worksheet – 3NF and BCNF",
                              subject: "DBMS", teacher: "Dr. Meena Krishnan", status: .pending,
                              dueText: "Thu, 08 Oct · 11:59 PM", dueChip: String(localized: "Due tomorrow"),
                              dueChipIsUrgent: true, attachmentCount: 2),
            LearnerAssignment(id: "a9", title: "CPU scheduling problems – FCFS, SJF and Round Robin",
                              subject: "Operating Systems", teacher: "Prof. Karthik Raman", status: .pending,
                              dueText: "Mon, 12 Oct · 05:00 PM", dueChip: String(localized: "Due in 5 days"),
                              dueChipIsUrgent: false, attachmentCount: 1),
            LearnerAssignment(id: "a10", title: "Subnetting exercise sheet",
                              subject: "Computer Networks", teacher: "Dr. Lakshmi Sundar", status: .pending,
                              dueText: "Wed, 14 Oct · 11:59 PM", dueChip: String(localized: "Due in 7 days"),
                              dueChipIsUrgent: false, attachmentCount: 0),
            LearnerAssignment(id: "a11", title: "SQL joins – lab record",
                              subject: "DBMS Lab", teacher: "Dr. Meena Krishnan", status: .submitted,
                              dueText: "Fri, 09 Oct · 04:00 PM", dueChip: String(localized: "Submitted"),
                              dueChipIsUrgent: false, attachmentCount: 1),
            LearnerAssignment(id: "a12", title: "Deadlock avoidance – Banker's algorithm",
                              subject: "Operating Systems", teacher: "Prof. Karthik Raman", status: .graded,
                              dueText: "Fri, 25 Sep · 05:00 PM", dueChip: String(localized: "18 / 20"),
                              dueChipIsUrgent: false, attachmentCount: 1),
            LearnerAssignment(id: "a14", title: "ER diagram for a library system",
                              subject: "DBMS", teacher: "Dr. Meena Krishnan", status: .graded,
                              dueText: "Tue, 23 Sep · 11:59 PM", dueChip: String(localized: "19 / 20"),
                              dueChipIsUrgent: false, attachmentCount: 1),
            LearnerAssignment(id: "a13", title: "DFA to regular expression conversions",
                              subject: "Theory of Computation", teacher: "Prof. Vignesh Prabhu", status: .overdue,
                              dueText: "Mon, 05 Oct · 11:59 PM", dueChip: String(localized: "2 days overdue"),
                              dueChipIsUrgent: true, attachmentCount: 1),
        ]
    }

    func learnerAssignmentDetail(id: String, studentID: String?) async throws -> LearnerAssignmentDetail {
        try await Task.sleep(for: latency)
        switch id {
        case "a13": // Overdue (p27)
            return LearnerAssignmentDetail(
                id: id, title: "DFA to regular expression conversions",
                subject: "Theory of Computation", status: .overdue,
                teacherName: "Prof. Vignesh Prabhu", teacherRole: "Theory of Computation",
                postedText: "28 Sep 2026", maxMarks: 10, dueText: "Mon, 05 Oct 2026 · 11:59 PM",
                lateAllowed: true, resubmissionAllowed: false,
                instructions: "Convert the four DFAs in the sheet to regular expressions using state elimination. Show every elimination step.",
                attachments: [AssignmentAttachment(id: "f1", name: "DFA_problem_sheet.pdf", kind: .pdf, detail: "PDF · 820 KB")],
                bannerText: String(localized: "This was due on Mon, 05 Oct at 11:59 PM. You can still submit, but it will be marked Late."),
                submittedText: nil, submissionFiles: [],
                marks: nil, gradePercent: nil, gradedByText: nil, feedback: nil)
        case "a11": // Submitted (p28)
            return LearnerAssignmentDetail(
                id: id, title: "SQL joins – lab record",
                subject: "DBMS Lab", status: .submitted,
                teacherName: "Dr. Meena Krishnan", teacherRole: "Class advisor · DBMS",
                postedText: "29 Sep 2026", maxMarks: 25, dueText: "Fri, 09 Oct 2026 · 04:00 PM",
                lateAllowed: false, resubmissionAllowed: true,
                instructions: "Record the queries and outputs for experiments 4 to 6 (inner, outer and self joins) on the college_db schema.",
                attachments: [AssignmentAttachment(id: "f1", name: "Lab_manual_ex4-6.pdf", kind: .pdf, detail: "PDF · 2.4 MB")],
                bannerText: String(localized: "Submitted on 04 Oct 2026, 06:20 PM · waiting for grade"),
                submittedText: "04 Oct 2026, 06:20 PM · waiting for grade",
                submissionFiles: [AssignmentAttachment(id: "sf1", name: "SQL_joins_record_Aarav.pdf", kind: .pdf, detail: "PDF · 3.1 MB")],
                marks: nil, gradePercent: nil, gradedByText: nil, feedback: nil)
        case "a12": // Graded (p29)
            return LearnerAssignmentDetail(
                id: id, title: "Deadlock avoidance – Banker's algorithm",
                subject: "Operating Systems", status: .graded,
                teacherName: "Prof. Karthik Raman", teacherRole: "Operating Systems",
                postedText: "18 Sep 2026", maxMarks: 20, dueText: "Fri, 25 Sep 2026 · 05:00 PM",
                lateAllowed: false, resubmissionAllowed: false,
                instructions: "Solve the three Banker's algorithm problems. Show the Need matrix and the safe sequence for each.",
                attachments: [AssignmentAttachment(id: "f1", name: "Bankers_problems.pdf", kind: .pdf, detail: "PDF · 540 KB")],
                bannerText: nil,
                submittedText: "24 Sep 2026, 03:10 PM",
                submissionFiles: [AssignmentAttachment(id: "sf1", name: "Bankers_Aarav.pdf", kind: .pdf, detail: "PDF · 1.1 MB")],
                marks: 18, gradePercent: 90, gradedByText: String(localized: "by Prof. Karthik Raman on 01 Oct 2026"),
                feedback: "Good work. Need matrices are correct and neatly shown. In problem 3, P2 can't run before P4 — recheck Available after P1 finishes. Keep it up!")
        default: // Pending (p26)
            return LearnerAssignmentDetail(
                id: id, title: "Normalization worksheet – 3NF and BCNF",
                subject: "DBMS", status: .pending,
                teacherName: "Dr. Meena Krishnan", teacherRole: "Class advisor · DBMS",
                postedText: "01 Oct 2026", maxMarks: 20, dueText: "Thu, 08 Oct 2026 · 11:59 PM",
                lateAllowed: true, resubmissionAllowed: true,
                instructions: "Normalize the three relations given in the worksheet up to BCNF. For each step, list the functional dependencies and explain which normal form is violated.\n\nWrite neatly or type it. Upload one PDF, or clear photos of every page in order.",
                attachments: [
                    AssignmentAttachment(id: "f1", name: "Normalization_worksheet.pdf", kind: .pdf, detail: "PDF · 1.2 MB"),
                    AssignmentAttachment(id: "f2", name: "FD_examples.png", kind: .image, detail: "Image · 640 KB"),
                ],
                bannerText: String(localized: "Due tomorrow · not submitted yet"),
                submittedText: nil, submissionFiles: [],
                marks: nil, gradePercent: nil, gradedByText: nil, feedback: nil)
        }
    }

    func submit(assignmentID: String, fileNames: [String], comment: String) async throws {
        try await Task.sleep(for: latency)
    }
}
