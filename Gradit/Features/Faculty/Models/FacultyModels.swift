//
//  FacultyModels.swift
//  Gradit
//
//  Payloads for the Faculty module: the staff faculty directory (management /
//  faculty) and the student / parent "my teachers by semester" view.
//  Design: facultyModul.pdf.
//

import SwiftUI

// MARK: - Shared

nonisolated enum FacultyPresence: String, Codable, Sendable {
    case present, onLeave, absent, notPunchedIn

    var title: String {
        switch self {
        case .present: String(localized: "Present")
        case .onLeave: String(localized: "On leave")
        case .absent: String(localized: "Absent")
        case .notPunchedIn: String(localized: "Not punched in")
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FacultyPresence(rawValue: raw) ?? .present
    }
}

nonisolated enum FacultyRole: String, Codable, Sendable {
    case none, headOfDept, classTeacher, classMentor

    var title: String {
        switch self {
        case .none: ""
        case .headOfDept: String(localized: "Head of dept")
        case .classTeacher: String(localized: "Class teacher")
        case .classMentor: String(localized: "Class mentor")
        }
    }

    var systemImage: String {
        switch self {
        case .headOfDept: "person.badge.shield.checkmark"
        case .classTeacher, .classMentor: "star"
        case .none: ""
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FacultyRole(rawValue: raw) ?? .none
    }
}

// MARK: - Staff directory

nonisolated struct FacultyMember: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let designation: String          // "Professor and Head"
    let department: String
    let stream: String
    let subjects: String             // "Tamil Literature, Sangam Poetry"
    let role: FacultyRole
    let presence: FacultyPresence
    let presenceDetail: String       // "Present · 08:56 AM" / "On sick leave (approved)"
}

nonisolated struct FacultyStream: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let facultyCount: Int
    let departmentCount: Int
}

nonisolated struct FacultyDepartmentOption: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let facultyCount: Int
}

nonisolated struct FacultyDeptGroup: Codable, Identifiable, Hashable, Sendable {
    var id: String { department }
    let department: String
    let presentToday: Int
    let members: [FacultyMember]
    var total: Int { members.count }
}

nonisolated struct FacultyDivisionGroup: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let divisionLabel: String        // "B.Sc CS · Sem 1 · Division A"
    let classTeacher: String
    let members: [FacultyMember]
    var total: Int { members.count }
}

nonisolated struct FacultyDirectory: Codable, Sendable {
    let totalFaculty: Int
    let present: Int
    let absentLeave: Int
    let freePeriods: Int
    let summaryText: String          // "102 faculty in all streams · 18 departments"
    let departmentGroups: [FacultyDeptGroup]
    let divisionGroups: [FacultyDivisionGroup]
    let allFaculty: [FacultyMember]
}

nonisolated struct FacultyDeptSummary: Codable, Sendable {
    let department: String
    let stream: String
    let hodName: String
    let hodDesignation: String
    let hodDetail: String            // "Present · 08:58 AM"
    let faculty: Int
    let present: Int
    let absent: Int
    let divisions: [String]
}

// MARK: - Staff faculty profile

nonisolated struct ProfileSubject: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let subject: String
    let classLabel: String           // "B.Sc CS · Sem 5 · Division A"
    let perWeek: Int
    let isClassTeacher: Bool
}

nonisolated struct AbsenceFreePeriod: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let period: String               // "P1"
    let classLabel: String           // "B.E. CSE · Sem 5 B"
    let allocation: String           // "Allocated to Mr. Arul Doss" / "Unallocated"
}

nonisolated struct FacultyProfile: Codable, Sendable {
    let id: String
    let name: String
    let designation: String
    let role: FacultyRole
    let employeeID: String
    let department: String
    let stream: String
    let qualification: String
    let experience: String
    let phone: String
    let todayDateText: String        // "Wed, 07 Oct"
    let presence: FacultyPresence
    let presenceDetail: String       // "Punched in at 08:47 AM · fingerprint, Main block"
    let periodsPerWeek: Int
    let subjects: [ProfileSubject]
    let absenceFreePeriods: [AbsenceFreePeriod]   // only when on leave
    /// Division options for "Assign as class teacher".
    let divisionOptions: [ClassTeacherOption]
}

nonisolated struct ClassTeacherOption: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let divisionLabel: String        // "B.Sc CS · Sem 3 · Division B"
    let currentTeacher: String       // "Current: Ms. Lakshmi Priya Srinivasan" / "Already class teacher"
    let isCurrent: Bool
}

// MARK: - Free periods today

nonisolated struct AbsentStaff: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let detail: String               // "IT · not punched in by 09:15 AM"
    let periods: String              // "2 periods"
}

nonisolated enum AllocationState: String, Codable, Sendable {
    case allocated, unallocated
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AllocationState(rawValue: raw) ?? .unallocated
    }
}

nonisolated struct FreePeriod: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let period: String               // "P1"
    let time: String                 // "09:00 – 09:50 AM"
    let subject: String
    let classLabel: String
    let absentTeacher: String
    var allocation: AllocationState
    var allocatedTo: String?
    let inProgress: Bool
    let ended: Bool
}

nonisolated struct FreePeriodsDay: Codable, Sendable {
    let dateText: String             // "Wed, 07 Oct · from staff punch-in"
    let staffAbsent: Int
    let freePeriods: Int
    let unallocated: Int
    let absentStaff: [AbsentStaff]
    let noteText: String?
    var periods: [FreePeriod]
}

// MARK: - Learner (student / parent)

nonisolated enum SemesterState: String, Codable, Sendable {
    case done, current, next, upcoming
    var title: String {
        switch self {
        case .done: String(localized: "Done")
        case .current: String(localized: "Current")
        case .next: String(localized: "Next")
        case .upcoming: String(localized: "Upcoming")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SemesterState(rawValue: raw) ?? .done
    }
}

nonisolated struct FacultyChild: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let classLabel: String           // "B.E. CSE · Sem 5 A"
}

nonisolated struct SemesterOption: Codable, Identifiable, Hashable, Sendable {
    let id: Int                      // semester number
    let label: String                // "Sem 5"
    let state: SemesterState
}

nonisolated enum SubjectKind: String, Codable, Sendable {
    case theory, lab, activity
    var title: String {
        switch self {
        case .theory: String(localized: "Theory")
        case .lab: String(localized: "Lab")
        case .activity: String(localized: "Activity")
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SubjectKind(rawValue: raw) ?? .theory
    }
}

nonisolated struct LearnerTeacherSubject: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let kind: SubjectKind
    let perWeek: Int
}

nonisolated struct LearnerTeacher: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let designation: String
    let role: FacultyRole
    let subjects: [LearnerTeacherSubject]
    let awayNote: String?            // "Away today · P3 and P5 are free periods"
    var totalPerWeek: Int { subjects.reduce(0) { $0 + $1.perWeek } }
}

nonisolated struct SemesterFaculty: Codable, Sendable {
    let classLabel: String           // "B.E. CSE · Sem 5 · Division A"
    let termText: String             // "Odd semester 2026-27 · Jul – Nov 2026"
    let state: SemesterState
    let assigned: Bool
    let classTeacher: LearnerTeacher?
    let classTeacherHours: String?   // "Parent hours Thu, 03:05 – 03:55 PM"
    let teacherCount: Int
    let subjectCount: Int
    let periodsPerWeek: Int
    let teachers: [LearnerTeacher]
}

nonisolated struct LearnerProfileSubject: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let subject: String
    let kind: SubjectKind
    let perWeek: Int
    let when: String                 // "Mon P1 · Tue P3 · Wed P1 · Thu P2 · Fri P3 · Sat P3"
}

nonisolated struct LearnerFacultyProfile: Codable, Sendable {
    let id: String
    let name: String
    let designation: String          // "Professor · CSE"
    let role: FacultyRole
    let department: String
    let qualification: String
    let experience: String
    let alsoTaughtText: String       // "Only this semester" / "Sem 4"
    let teachesHeading: String       // "Teaches Aarav in Sem 5"
    let subjects: [LearnerProfileSubject]
    let parentHours: String          // "Thu, 03:05 – 03:55 PM"
    let cabin: String                // "Cabin B-210"
    let onLeaveNote: String?         // "On leave today · Wed 07 Oct" + substitute
}
