//
//  CourseModels.swift
//  Gradit
//
//  Payloads for the student/parent Course Details module. Design: courseDetails.pdf.
//

import SwiftUI

// MARK: - Semester status

nonisolated enum SemesterStatus: String, Codable, Sendable {
    case completed, current, upcoming
    var title: String {
        switch self {
        case .completed: String(localized: "Completed")
        case .current: String(localized: "Current")
        case .upcoming: String(localized: "Upcoming")
        }
    }
    var systemImage: String {
        switch self {
        case .completed: "checkmark"
        case .current: "smallcircle.filled.circle"
        case .upcoming: "clock"
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SemesterStatus(rawValue: raw) ?? .upcoming
    }
}

nonisolated struct SemesterProgress: Codable, Identifiable, Hashable, Sendable {
    let number: Int
    var id: Int { number }
    let label: String                 // "Sem 1"
    let status: SemesterStatus
}

// MARK: - Overview

nonisolated struct CourseOverview: Codable, Sendable {
    let programName: String           // "B.E. Computer Science and Engineering"
    let studentName: String
    let regNo: String
    let stream: String
    let department: String
    let academicYear: String          // "2026–27"
    let yearSemester: String          // "Year 3 · Semester 5"
    let division: String
    let duration: String              // "4 years · 8 semesters"
    let regulation: String            // "Regulation 2021 · Anna University"
    let totalCredits: Int
    let creditsEarned: Int
    let creditsEarnedNote: String     // "8 pending from Sem 3"
    let subjectsThisSemester: Int
    let subjectsNote: String          // "22 credits in Sem 5"
    let classTeacher: String
    let classTeacherSem: String       // "Semester 5"
    let completedCount: Int
    let totalSemesters: Int
    let semesters: [SemesterProgress]
}

// MARK: - Subjects

nonisolated enum SubjectType: String, Codable, Sendable {
    case theory, practical, elective
    var title: String {
        switch self {
        case .theory: String(localized: "Theory")
        case .practical: String(localized: "Practical")
        case .elective: String(localized: "Elective")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SubjectType(rawValue: raw) ?? .theory
    }
}

nonisolated struct CourseSubject: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let code: String                  // "CS3492"
    let type: SubjectType
    let name: String
    let credits: Int
    let intMarks: Int
    let extMarks: Int
    let teacher: String?              // nil = "To be assigned"
}

nonisolated struct CourseFacultyItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let subjectCode: String
    let subjectName: String
    let teacherId: String
    let teacherName: String
    let designation: String           // "Professor · CSE"
}

nonisolated struct SemesterBlock: Codable, Identifiable, Hashable, Sendable {
    let semester: Int
    var id: Int { semester }
    let label: String                 // "Semester 5"
    let term: String                  // "Jul – Nov 2026 · Year 3"
    let status: SemesterStatus
    let electiveWarning: String?      // "Aarav hasn't chosen Professional Elective II yet…"
    let subjects: [CourseSubject]
    let faculty: [CourseFacultyItem]
}

// MARK: - Syllabus

nonisolated struct SyllabusDoc: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let semesterLabel: String         // "Semester 5 syllabus · current"
    let meta: String                  // "R2021 · v3.2 · updated 12 Jun 2026 · PDF"
    let uploaded: Bool
}

// MARK: - Bundle

nonisolated struct CourseBundle: Codable, Sendable {
    let overview: CourseOverview
    let semesters: [SemesterBlock]
    let syllabus: [SyllabusDoc]
}

// MARK: - Subject detail

nonisolated enum SubjectStatusKind: String, Codable, Sendable {
    case current, completed, arrear
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SubjectStatusKind(rawValue: raw) ?? .current
    }
}

nonisolated struct CourseOutcome: Codable, Identifiable, Hashable, Sendable {
    let code: String                  // "CO1"
    var id: String { code }
    let text: String
}

nonisolated struct CourseUnit: Codable, Identifiable, Hashable, Sendable {
    let number: Int
    var id: Int { number }
    let title: String
    let detail: String?               // topics line
    let hours: String                 // "15 h"
}

nonisolated struct SubjectDetail: Codable, Sendable {
    let code: String
    let type: SubjectType
    let name: String
    let credits: Int
    let semester: Int
    let intMarks: Int
    let extMarks: Int
    let teacher: String
    let teacherRole: String           // "Professor · CSE"
    let studentName: String           // "Aarav"
    let statusKind: SubjectStatusKind
    // current
    let attendancePercent: Int?
    let attendanceNote: String?       // "Above 75% minimum"
    let internalMarks: String?        // "31 / 40"
    let internalBreakdown: String?    // "IA 1: 22 / 25\nAssignments: 9 / 10"
    // completed / arrear
    let resultText: String?           // "Passed · Grade O" / "Arrear"
    let resultNote: String?           // "Semester 4 · Dec 2025 – Apr 2026" / "Re-exam in Nov 2026"
    let creditsEarnedText: String?    // "4 of 4" / "0 of 4"
    let creditsEarnedNote: String?    // "Completed" / "Earned after passing the re-exam"
    let objectives: [String]
    let outcomes: [CourseOutcome]
    let units: [CourseUnit]
    let objectivesInSyllabusNote: String?  // when objectives are only in the syllabus PDF
}
