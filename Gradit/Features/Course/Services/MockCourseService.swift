//
//  MockCourseService.swift
//  Gradit
//
//  In-memory course data used in DEBUG, previews and tests. Mirrors courseDetails.pdf.
//

import Foundation

final class MockCourseService: CourseServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    func children() async throws -> [FacultyChild] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "aarav", name: "Aarav R.", classLabel: "B.E. CSE · Sem 5 A"),
            .init(id: "diya", name: "Diya R.", classLabel: "B.Tech IT · Sem 3 B"),
        ]
    }

    func course(childID: String?) async throws -> CourseBundle {
        try await Task.sleep(for: latency)
        let isDiya = childID == "diya"

        let overview = CourseOverview(
            programName: isDiya ? "B.Tech Information Technology" : "B.E. Computer Science and Engineering",
            studentName: isDiya ? "Diya R." : "Aarav R.", regNo: isDiya ? "2125061032" : "2124051005",
            stream: "Engineering", department: isDiya ? "Information Technology" : "Computer Science and Engineering",
            academicYear: "2026–27", yearSemester: isDiya ? "Year 2 · Semester 3" : "Year 3 · Semester 5",
            division: isDiya ? "Division B" : "Division A", duration: "4 years · 8 semesters",
            regulation: "Regulation 2021 · Anna University",
            totalCredits: 165, creditsEarned: isDiya ? 45 : 80,
            creditsEarnedNote: isDiya ? "Semesters 1 and 2" : "8 pending from Sem 3",
            subjectsThisSemester: isDiya ? 7 : 8, subjectsNote: isDiya ? "19 credits in Sem 3" : "22 credits in Sem 5",
            classTeacher: isDiya ? "Prof. Anand V." : "Dr. Meena Krishnan", classTeacherSem: isDiya ? "Semester 3" : "Semester 5",
            completedCount: isDiya ? 2 : 4, totalSemesters: 8,
            semesters: Self.progress(current: isDiya ? 3 : 5))

        return CourseBundle(overview: overview, semesters: Self.semesters(current: isDiya ? 3 : 5), syllabus: Self.syllabus)
    }

    func subjectDetail(childID: String?, code: String) async throws -> SubjectDetail {
        try await Task.sleep(for: latency)
        switch code {
        case "CS3481": // Practical, current
            return SubjectDetail(code: "CS3481", type: .practical, name: "Database Management Systems Lab",
                                 credits: 2, semester: 5, intMarks: 60, extMarks: 40,
                                 teacher: "Dr. Meena Krishnan", teacherRole: "Professor · CSE", studentName: "Aarav",
                                 statusKind: .current, attendancePercent: 94, attendanceNote: "Above 75% minimum",
                                 internalMarks: "52 / 60", internalBreakdown: "records and lab tests",
                                 resultText: nil, resultNote: nil, creditsEarnedText: nil, creditsEarnedNote: nil,
                                 objectives: [], outcomes: [],
                                 units: [
                                    CourseUnit(number: 1, title: "Exercises 1–4 · DDL, DML and constraints", detail: "Create tables · Insert, update, delete · Keys", hours: "15 h"),
                                    CourseUnit(number: 2, title: "Exercises 5–8 · queries and views", detail: nil, hours: "15 h"),
                                 ],
                                 objectivesInSyllabusNote: "The objectives and course outcomes for Database Management Systems Lab are in the syllabus PDF under Attachments.")
        case "CS3401": // Completed (passed)
            return SubjectDetail(code: "CS3401", type: .theory, name: "Algorithms", credits: 4, semester: 4,
                                 intMarks: 40, extMarks: 60, teacher: "Dr. Lakshmi Sundar", teacherRole: "Associate Professor · CSE",
                                 studentName: "Aarav", statusKind: .completed, attendancePercent: nil, attendanceNote: nil,
                                 internalMarks: nil, internalBreakdown: nil,
                                 resultText: "Passed · Grade O", resultNote: "Semester 4 · Dec 2025 – Apr 2026",
                                 creditsEarnedText: "4 of 4", creditsEarnedNote: "Completed",
                                 objectives: [], outcomes: [],
                                 units: [
                                    CourseUnit(number: 1, title: "Introduction and analysis", detail: "Asymptotic notation · Recurrences · Brute force", hours: "12 h"),
                                    CourseUnit(number: 2, title: "Graph algorithms", detail: nil, hours: "12 h"),
                                    CourseUnit(number: 3, title: "Algorithm design techniques", detail: nil, hours: "12 h"),
                                 ],
                                 objectivesInSyllabusNote: "The objectives and course outcomes for Algorithms are in the syllabus PDF under Attachments.")
        case "MA3354": // Arrear
            return SubjectDetail(code: "MA3354", type: .theory, name: "Discrete Mathematics", credits: 4, semester: 3,
                                 intMarks: 40, extMarks: 60, teacher: "Prof. Rajan K.", teacherRole: "Assistant Professor · Science and Humanities",
                                 studentName: "Aarav", statusKind: .arrear, attendancePercent: nil, attendanceNote: nil,
                                 internalMarks: nil, internalBreakdown: nil,
                                 resultText: "Arrear", resultNote: "Re-exam in Nov 2026",
                                 creditsEarnedText: "0 of 4", creditsEarnedNote: "Earned after passing the re-exam",
                                 objectives: [], outcomes: [],
                                 units: [
                                    CourseUnit(number: 1, title: "Logic and proofs", detail: "The topics for this unit are in the syllabus PDF below.", hours: "12 h"),
                                    CourseUnit(number: 2, title: "Combinatorics", detail: nil, hours: "12 h"),
                                 ],
                                 objectivesInSyllabusNote: "The objectives and course outcomes for Discrete Mathematics are in the syllabus PDF under Attachments.")
        default: // CS3492 DBMS, current with full objectives/COs
            return SubjectDetail(code: "CS3492", type: .theory, name: "Database Management Systems", credits: 3, semester: 5,
                                 intMarks: 40, extMarks: 60, teacher: "Dr. Meena Krishnan", teacherRole: "Professor · CSE",
                                 studentName: "Aarav", statusKind: .current, attendancePercent: 91, attendanceNote: "Above 75% minimum",
                                 internalMarks: "31 / 40", internalBreakdown: "IA 1: 22 / 25\nAssignments: 9 / 10",
                                 resultText: nil, resultNote: nil, creditsEarnedText: nil, creditsEarnedNote: nil,
                                 objectives: [
                                    "Understand relational data models and SQL",
                                    "Design normalised databases from requirements",
                                    "Learn how transactions and recovery keep data safe",
                                 ],
                                 outcomes: [
                                    CourseOutcome(code: "CO1", text: "Write SQL queries for real data"),
                                    CourseOutcome(code: "CO2", text: "Draw ER diagrams and normalise tables to BCNF"),
                                    CourseOutcome(code: "CO3", text: "Explain locking, deadlocks and recovery"),
                                    CourseOutcome(code: "CO4", text: "Compare relational and NoSQL stores"),
                                 ],
                                 units: [
                                    CourseUnit(number: 1, title: "Relational model and SQL", detail: "ER model · Keys · SELECT, joins, aggregation", hours: "9 h"),
                                    CourseUnit(number: 2, title: "Normalisation", detail: "Functional dependencies · 1NF–BCNF", hours: "9 h"),
                                    CourseUnit(number: 3, title: "Transactions and recovery", detail: nil, hours: "9 h"),
                                 ],
                                 objectivesInSyllabusNote: nil)
        }
    }

    // MARK: - Builders

    private static func progress(current: Int) -> [SemesterProgress] {
        (1...8).map { n in
            let status: SemesterStatus = n < current ? .completed : (n == current ? .current : .upcoming)
            return SemesterProgress(number: n, label: "Sem \(n)", status: status)
        }
    }

    private static func semesters(current: Int) -> [SemesterBlock] {
        (1...8).map { n in
            let status: SemesterStatus = n < current ? .completed : (n == current ? .current : .upcoming)
            return SemesterBlock(semester: n, label: "Semester \(n)", term: term(n),
                                 status: status, electiveWarning: n == 5 ? electiveWarning : nil,
                                 subjects: subjects(for: n), faculty: faculty(for: n))
        }
    }

    private static let electiveWarning = "Aarav hasn't chosen Professional Elective II yet. Choose it on the college web portal by Fri, 16 Oct."

    private static func term(_ n: Int) -> String {
        switch n {
        case 4: "Dec 2025 – Apr 2026 · Year 2"
        case 5: "Jul – Nov 2026 · Year 3"
        case 6: "Dec 2026 – Apr 2027 · Year 3"
        default: "Year \((n + 1) / 2)"
        }
    }

    private static func subjects(for sem: Int) -> [CourseSubject] {
        switch sem {
        case 5:
            [
                CourseSubject(id: "s1", code: "CS3492", type: .theory, name: "Database Management Systems", credits: 3, intMarks: 40, extMarks: 60, teacher: "Dr. Meena Krishnan"),
                CourseSubject(id: "s2", code: "CS3451", type: .theory, name: "Operating Systems", credits: 3, intMarks: 40, extMarks: 60, teacher: "Prof. Karthik Raman"),
                CourseSubject(id: "s3", code: "CS3591", type: .theory, name: "Computer Networks", credits: 3, intMarks: 40, extMarks: 60, teacher: "Dr. Lakshmi Sundar"),
                CourseSubject(id: "s4", code: "CS3481", type: .practical, name: "Database Management Systems Lab", credits: 2, intMarks: 60, extMarks: 40, teacher: "Dr. Meena Krishnan"),
                CourseSubject(id: "s5", code: "PE2", type: .elective, name: "Professional Elective II", credits: 3, intMarks: 40, extMarks: 60, teacher: nil),
            ]
        case 4:
            [
                CourseSubject(id: "s1", code: "CS3401", type: .theory, name: "Algorithms", credits: 4, intMarks: 40, extMarks: 60, teacher: "Dr. Lakshmi Sundar"),
                CourseSubject(id: "s2", code: "CS3402", type: .theory, name: "Computer Architecture", credits: 3, intMarks: 40, extMarks: 60, teacher: "Prof. Vignesh Prabhu"),
                CourseSubject(id: "s3", code: "EC3401", type: .theory, name: "Microprocessors and Microcontrollers", credits: 4, intMarks: 40, extMarks: 60, teacher: "Dr. Gopinath N."),
            ]
        case 6:
            [
                CourseSubject(id: "s1", code: "CCS356", type: .theory, name: "Object Oriented Software Engineering", credits: 3, intMarks: 40, extMarks: 60, teacher: nil),
                CourseSubject(id: "s2", code: "CS3691", type: .theory, name: "Embedded Systems and IoT", credits: 4, intMarks: 40, extMarks: 60, teacher: nil),
                CourseSubject(id: "s3", code: "PE3", type: .elective, name: "Professional Elective III", credits: 3, intMarks: 40, extMarks: 60, teacher: nil),
            ]
        case 3:
            [
                CourseSubject(id: "s1", code: "MA3354", type: .theory, name: "Discrete Mathematics", credits: 4, intMarks: 40, extMarks: 60, teacher: "Prof. Rajan K."),
                CourseSubject(id: "s2", code: "CS3351", type: .theory, name: "Digital Principles and Computer Organization", credits: 4, intMarks: 40, extMarks: 60, teacher: "Dr. Suresh B."),
            ]
        default:
            [
                CourseSubject(id: "s1", code: "HS\(sem)01", type: .theory, name: "Foundation course \(sem)", credits: 3, intMarks: 40, extMarks: 60, teacher: "Staff"),
            ]
        }
    }

    private static func faculty(for sem: Int) -> [CourseFacultyItem] {
        subjects(for: sem).compactMap { subject in
            guard let teacher = subject.teacher else { return nil }
            return CourseFacultyItem(id: subject.id, subjectCode: subject.code, subjectName: subject.name,
                                     teacherId: "meena", teacherName: teacher, designation: "Professor · CSE")
        }
    }

    private static let syllabus: [SyllabusDoc] = [
        .init(id: "y5", semesterLabel: "Semester 5 syllabus · current", meta: "R2021 · v3.2 · updated 12 Jun 2026 · PDF", uploaded: true),
        .init(id: "y4", semesterLabel: "Semester 4 syllabus", meta: "R2021 · v2.0 · updated 05 Dec 2025 · PDF", uploaded: true),
        .init(id: "y3", semesterLabel: "Semester 3 syllabus", meta: "R2021 · v2.0 · updated 01 Jul 2025 · PDF", uploaded: true),
        .init(id: "y2", semesterLabel: "Semester 2 syllabus", meta: "R2021 · v1.4 · updated 20 Dec 2024 · PDF", uploaded: true),
        .init(id: "y1", semesterLabel: "Semester 1 syllabus", meta: "R2021 · v1.4 · updated 02 Aug 2024 · PDF", uploaded: true),
    ]
}
