//
//  MockFacultyService.swift
//  Gradit
//
//  In-memory faculty data used in DEBUG, previews and tests. Mirrors facultyModul.pdf.
//

import Foundation

final class MockFacultyService: FacultyServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    // MARK: - Directory

    func directory(stream: String?, departments: [String], yearSem: String, division: String) async throws -> FacultyDirectory {
        try await Task.sleep(for: latency)

        let allStreams = (stream == nil || stream == "All streams")
        let members = Self.members(stream: allStreams ? nil : stream, departments: departments)
        let deptGroups = Self.groupByDepartment(members)
        let (total, present, absent, summary) = Self.headline(stream: stream, departments: departments)

        return FacultyDirectory(
            totalFaculty: total, present: present, absentLeave: absent, freePeriods: 6,
            summaryText: summary,
            departmentGroups: deptGroups,
            divisionGroups: Self.divisionGroups(from: members),
            allFaculty: members.sorted { $0.name < $1.name })
    }

    func streams() async throws -> [FacultyStream] {
        try await Task.sleep(for: latency)
        return [
            FacultyStream(id: "all", name: "All streams", facultyCount: 102, departmentCount: 18),
            FacultyStream(id: "as", name: "Arts and Science", facultyCount: 42, departmentCount: 8),
            FacultyStream(id: "en", name: "Engineering", facultyCount: 38, departmentCount: 6),
            FacultyStream(id: "mg", name: "Management", facultyCount: 13, departmentCount: 2),
            FacultyStream(id: "ed", name: "Education", facultyCount: 9, departmentCount: 2),
        ]
    }

    func departments(stream: String) async throws -> [FacultyDepartmentOption] {
        try await Task.sleep(for: latency)
        switch stream {
        case "Engineering":
            return [
                .init(id: "all", name: "All departments", facultyCount: 38),
                .init(id: "cse", name: "CSE", facultyCount: 9),
                .init(id: "ece", name: "ECE", facultyCount: 7),
                .init(id: "mech", name: "Mechanical", facultyCount: 7),
                .init(id: "civil", name: "Civil", facultyCount: 6),
                .init(id: "eee", name: "EEE", facultyCount: 5),
                .init(id: "it", name: "Information Technology", facultyCount: 4),
            ]
        default: // Arts and Science
            return [
                .init(id: "all", name: "All departments", facultyCount: 42),
                .init(id: "tamil", name: "Tamil", facultyCount: 5),
                .init(id: "english", name: "English", facultyCount: 6),
                .init(id: "maths", name: "Mathematics", facultyCount: 7),
                .init(id: "physics", name: "Physics", facultyCount: 5),
                .init(id: "chemistry", name: "Chemistry", facultyCount: 5),
                .init(id: "cs", name: "Computer Science", facultyCount: 7),
                .init(id: "stats", name: "Statistics", facultyCount: 4),
                .init(id: "eco", name: "Economics", facultyCount: 3),
            ]
        }
    }

    func departmentSummary(_ department: String) async throws -> FacultyDeptSummary {
        try await Task.sleep(for: latency)
        return FacultyDeptSummary(
            department: "Computer Science", stream: "Arts and Science",
            hodName: "Dr. Senthil Kumar Ganesan", hodDesignation: "Professor and Head",
            hodDetail: String(localized: "Present · 08:58 AM"),
            faculty: 7, present: 7, absent: 0,
            divisions: ["B.Sc CS 1A", "B.Sc CS 1B", "B.Sc CS 3A", "B.Sc CS 3B", "B.Sc CS 5A", "B.Sc CS 5B"])
    }

    func profile(id: String) async throws -> FacultyProfile {
        try await Task.sleep(for: latency)
        if id == "vignesh" {
            return FacultyProfile(
                id: id, name: "Prof. Vignesh Prabhu", designation: "Assistant Professor", role: .none,
                employeeID: "UCE-EN-2116", department: "CSE", stream: "Engineering",
                qualification: "Ph.D., M.Tech", experience: "9 years", phone: "+91 91785 23907",
                todayDateText: "Wed, 07 Oct", presence: .onLeave,
                presenceDetail: String(localized: "No punch-in needed · leave approved"),
                periodsPerWeek: 18,
                subjects: [
                    ProfileSubject(id: "s1", subject: "Theory of Computation", classLabel: "B.E. CSE · Sem 5 · Division A", perWeek: 6, isClassTeacher: false),
                    ProfileSubject(id: "s2", subject: "Compiler Design", classLabel: "B.E. CSE · Sem 7 · Division A", perWeek: 5, isClassTeacher: false),
                ],
                absenceFreePeriods: [
                    AbsenceFreePeriod(id: "a1", period: "P1", classLabel: "B.E. CSE · Sem 5 B", allocation: String(localized: "Allocated to Mr. Arul Doss")),
                    AbsenceFreePeriod(id: "a2", period: "P4", classLabel: "B.E. CSE · Sem 5 A", allocation: String(localized: "Allocated to Dr. Kavitha M.")),
                    AbsenceFreePeriod(id: "a3", period: "P6", classLabel: "B.E. CSE · Sem 3 A", allocation: String(localized: "Unallocated")),
                    AbsenceFreePeriod(id: "a4", period: "P7", classLabel: "B.E. CSE · Sem 7 A", allocation: String(localized: "Allocated to Dr. Meena Krishnan")),
                ],
                divisionOptions: [])
        }
        return FacultyProfile(
            id: id, name: "Dr. Anitha Rajan", designation: "Associate Professor", role: .classTeacher,
            employeeID: "UCE-AS-1148", department: "Computer Science · also Mathematics", stream: "Arts and Science",
            qualification: "MCA, M.Phil., Ph.D. (Anna University)", experience: "14 years", phone: "+91 94440 21587",
            todayDateText: "Wed, 07 Oct", presence: .present,
            presenceDetail: String(localized: "Punched in at 08:47 AM · fingerprint, Main block"),
            periodsPerWeek: 14,
            subjects: [
                ProfileSubject(id: "s1", subject: "Database Systems", classLabel: "B.Sc CS · Sem 5 · Division A", perWeek: 5, isClassTeacher: true),
                ProfileSubject(id: "s2", subject: "Python Programming", classLabel: "B.Sc CS · Sem 3 · Division B", perWeek: 5, isClassTeacher: false),
                ProfileSubject(id: "s3", subject: "Discrete Mathematics", classLabel: "B.Sc Maths · Sem 3 · Division A", perWeek: 4, isClassTeacher: false),
            ],
            absenceFreePeriods: [],
            divisionOptions: [
                ClassTeacherOption(id: "d1", divisionLabel: "B.Sc CS · Sem 5 · Division A", currentTeacher: String(localized: "Already class teacher"), isCurrent: true),
                ClassTeacherOption(id: "d2", divisionLabel: "B.Sc CS · Sem 3 · Division B", currentTeacher: String(localized: "Current: Ms. Lakshmi Priya Srinivasan"), isCurrent: false),
                ClassTeacherOption(id: "d3", divisionLabel: "B.Sc Maths · Sem 3 · Division A", currentTeacher: String(localized: "Current: Dr. Gayathri Pandian"), isCurrent: false),
            ])
    }

    func freePeriods() async throws -> FreePeriodsDay {
        try await Task.sleep(for: latency)
        return FreePeriodsDay(
            dateText: String(localized: "Wed, 07 Oct · from staff punch-in"),
            staffAbsent: 2, freePeriods: 6, unallocated: 3,
            absentStaff: [
                AbsentStaff(id: "p1", name: "Dr. Priya Natarajan", detail: String(localized: "IT · not punched in by 09:15 AM"), periods: String(localized: "2 periods")),
                AbsentStaff(id: "p2", name: "Prof. Vignesh Prabhu", detail: String(localized: "CSE · on sick leave (approved)"), periods: String(localized: "4 periods")),
            ],
            noteText: String(localized: "Dr. Revathi S. punched in late at 10:20 AM. Her P5 was returned to her. P2 stayed with Mr. Arul Doss because it was allocated before she arrived."),
            periods: [
                FreePeriod(id: "f1", period: "P1", time: "09:00 – 09:50 AM", subject: "Theory of Computation",
                           classLabel: "B.E. CSE · Sem 5 B · B-206", absentTeacher: "Prof. Vignesh Prabhu",
                           allocation: .allocated, allocatedTo: "Mr. Arul Doss", inProgress: false, ended: true),
                FreePeriod(id: "f2", period: "P3", time: "10:55 – 11:45 AM", subject: "Data Structures",
                           classLabel: "B.Tech IT · Sem 3 B · C-108", absentTeacher: "Dr. Priya Natarajan",
                           allocation: .unallocated, allocatedTo: nil, inProgress: true, ended: false),
                FreePeriod(id: "f3", period: "P4", time: "11:45 AM – 12:35 PM", subject: "Theory of Computation",
                           classLabel: "B.E. CSE · Sem 5 A · B-204", absentTeacher: "Prof. Vignesh Prabhu",
                           allocation: .allocated, allocatedTo: "Dr. Kavitha M.", inProgress: false, ended: false),
                FreePeriod(id: "f4", period: "P5", time: "01:30 – 02:20 PM", subject: "DBMS Lab",
                           classLabel: "B.E. CSE · Sem 5 B · Lab 3", absentTeacher: "Dr. Priya Natarajan",
                           allocation: .unallocated, allocatedTo: nil, inProgress: false, ended: false),
                FreePeriod(id: "f5", period: "P6", time: "02:20 – 03:10 PM", subject: "Compiler Design",
                           classLabel: "B.E. CSE · Sem 3 A · B-210", absentTeacher: "Prof. Vignesh Prabhu",
                           allocation: .unallocated, allocatedTo: nil, inProgress: false, ended: false),
                FreePeriod(id: "f6", period: "P7", time: "03:10 – 04:00 PM", subject: "Mentoring hour",
                           classLabel: "B.E. CSE · Sem 7 A · B-204", absentTeacher: "Prof. Vignesh Prabhu",
                           allocation: .allocated, allocatedTo: "Dr. Meena Krishnan", inProgress: false, ended: false),
            ])
    }

    // MARK: - Learner

    func children() async throws -> [FacultyChild] {
        try await Task.sleep(for: latency)
        return [
            FacultyChild(id: "aarav", name: "Aarav R.", classLabel: "B.E. CSE · Sem 5 A"),
            FacultyChild(id: "diya", name: "Diya R.", classLabel: "B.Tech IT · Sem 3 B"),
        ]
    }

    func semesters(childID: String?) async throws -> [SemesterOption] {
        try await Task.sleep(for: latency)
        return [
            SemesterOption(id: 1, label: "Sem 1", state: .done),
            SemesterOption(id: 2, label: "Sem 2", state: .done),
            SemesterOption(id: 3, label: "Sem 3", state: .done),
            SemesterOption(id: 4, label: "Sem 4", state: .done),
            SemesterOption(id: 5, label: "Sem 5", state: .current),
            SemesterOption(id: 6, label: "Sem 6", state: .next),
        ]
    }

    func semesterFaculty(childID: String?, semester: Int) async throws -> SemesterFaculty {
        try await Task.sleep(for: latency)
        let isDiya = childID == "diya"

        if semester == 6 {
            return SemesterFaculty(
                classLabel: isDiya ? "B.Tech IT · Sem 6 · Division B" : "B.E. CSE · Sem 6 · Division A",
                termText: "Dec 2026 – Apr 2027", state: .upcoming, assigned: false,
                classTeacher: nil, classTeacherHours: nil, teacherCount: 0, subjectCount: 0,
                periodsPerWeek: 0, teachers: [])
        }

        if isDiya {
            let anand = LearnerTeacher(id: "anand", name: "Prof. Anand V.", designation: "Assistant Professor", role: .classTeacher,
                                       subjects: [LearnerTeacherSubject(id: "oop", name: "Object Oriented Programming", kind: .theory, perWeek: 7)], awayNote: nil)
            return SemesterFaculty(
                classLabel: "B.Tech IT · Sem 3 · Division B", termText: "Odd semester 2026-27 · Jul – Nov 2026",
                state: .current, assigned: true, classTeacher: anand,
                classTeacherHours: String(localized: "Parent hours Mon, 02:15 – 03:05 PM"),
                teacherCount: 5, subjectCount: 6, periodsPerWeek: 38,
                teachers: [
                    anand,
                    LearnerTeacher(id: "priya", name: "Dr. Priya Natarajan", designation: "Associate Professor", role: .none,
                                   subjects: [
                                    LearnerTeacherSubject(id: "ds", name: "Data Structures", kind: .theory, perWeek: 8),
                                    LearnerTeacherSubject(id: "dslab", name: "Data Structures Lab", kind: .lab, perWeek: 4),
                                   ], awayNote: String(localized: "Away today · P3 and P5 are free periods")),
                ])
        }

        // Aarav, current Sem 5
        let meena = LearnerTeacher(id: "meena", name: "Dr. Meena Krishnan", designation: "Professor", role: .classTeacher,
                                   subjects: [
                                    LearnerTeacherSubject(id: "dbms", name: "Database Management Systems", kind: .theory, perWeek: 6),
                                    LearnerTeacherSubject(id: "dbmslab", name: "DBMS Lab", kind: .lab, perWeek: 4),
                                    LearnerTeacherSubject(id: "mentor", name: "Mentoring hour", kind: .activity, perWeek: 2),
                                   ], awayNote: nil)
        return SemesterFaculty(
            classLabel: "B.E. CSE · Sem 5 · Division A", termText: "Odd semester 2026-27 · Jul – Nov 2026",
            state: .current, assigned: true, classTeacher: meena,
            classTeacherHours: String(localized: "Parent hours Thu, 03:05 – 03:55 PM"),
            teacherCount: 7, subjectCount: 9, periodsPerWeek: 39,
            teachers: [
                meena,
                LearnerTeacher(id: "karthik", name: "Prof. Karthik Raman", designation: "Associate Professor", role: .none,
                               subjects: [LearnerTeacherSubject(id: "os", name: "Operating Systems", kind: .theory, perWeek: 7)], awayNote: nil),
                LearnerTeacher(id: "vignesh", name: "Prof. Vignesh Prabhu", designation: "Assistant Professor", role: .none,
                               subjects: [LearnerTeacherSubject(id: "toc", name: "Theory of Computation", kind: .theory, perWeek: 6)],
                               awayNote: String(localized: "On leave today · P4 substitute Dr. Kavitha M.")),
                LearnerTeacher(id: "lakshmi", name: "Dr. Lakshmi Sundar", designation: "Professor", role: .none,
                               subjects: [LearnerTeacherSubject(id: "cn", name: "Computer Networks", kind: .theory, perWeek: 5)], awayNote: nil),
            ])
    }

    func learnerProfile(teacherID: String, childID: String?) async throws -> LearnerFacultyProfile {
        try await Task.sleep(for: latency)
        if teacherID == "vignesh" {
            return LearnerFacultyProfile(
                id: teacherID, name: "Prof. Vignesh Prabhu", designation: "Assistant Professor · CSE", role: .none,
                department: "CSE", qualification: "M.E. (CSE)", experience: "9 years", alsoTaughtText: "Sem 4",
                teachesHeading: String(localized: "Teaches Aarav in Sem 5"),
                subjects: [
                    LearnerProfileSubject(id: "toc", subject: "Theory of Computation", kind: .theory, perWeek: 6,
                                          when: "Mon P4 · Tue P4 · Wed P4 · Thu P1 · Fri P2 · Sat P4"),
                ],
                parentHours: "Mon, 03:05 – 03:55 PM", cabin: "Cabin B-218",
                onLeaveNote: String(localized: "On leave today · Wed 07 Oct — P4 Theory of Computation: Substitute Dr. Kavitha M."))
        }
        return LearnerFacultyProfile(
            id: teacherID, name: "Dr. Meena Krishnan", designation: "Professor · CSE", role: .classTeacher,
            department: "CSE", qualification: "Ph.D., M.E. (CSE)", experience: "18 years", alsoTaughtText: String(localized: "Only this semester"),
            teachesHeading: String(localized: "Teaches Aarav in Sem 5"),
            subjects: [
                LearnerProfileSubject(id: "dbms", subject: "Database Management Systems", kind: .theory, perWeek: 6,
                                      when: "Mon P1 · Tue P3 · Wed P1 · Thu P2 · Fri P3 · Sat P3"),
                LearnerProfileSubject(id: "dbmslab", subject: "DBMS Lab", kind: .lab, perWeek: 4,
                                      when: "Mon P5, P6 · Thu P5, P6"),
                LearnerProfileSubject(id: "mentor", subject: "Mentoring hour", kind: .activity, perWeek: 2,
                                      when: "Mon P7 · Wed P6"),
            ],
            parentHours: "Thu, 03:05 – 03:55 PM", cabin: "Cabin B-210", onLeaveNote: nil)
    }

    // MARK: - Member generation

    private static func headline(stream: String?, departments: [String]) -> (Int, Int, Int, String) {
        let selectable = departments.filter { $0 != "All departments" }
        if stream == nil || stream == "All streams" {
            return (102, 94, 6, String(localized: "102 faculty in all streams · 18 departments"))
        }
        guard let stream else { return (102, 94, 6, "") }
        if selectable.isEmpty {
            let (total, present, absent, depts): (Int, Int, Int, Int)
            switch stream {
            case "Arts and Science": (total, present, absent, depts) = (42, 39, 3, 8)
            case "Engineering": (total, present, absent, depts) = (38, 36, 2, 6)
            case "Management": (total, present, absent, depts) = (13, 13, 0, 2)
            case "Education": (total, present, absent, depts) = (9, 8, 1, 2)
            default: (total, present, absent, depts) = (42, 39, 3, 8)
            }
            return (total, present, absent, String(localized: "\(total) faculty in \(stream) · \(depts) departments"))
        }
        // Specific departments selected — sum representative counts.
        let counts = ["Computer Science": 7, "Mathematics": 7, "Tamil": 5, "English": 6, "Physics": 5,
                      "Chemistry": 5, "Statistics": 4, "Economics": 3, "CSE": 9, "ECE": 7, "Mechanical": 7,
                      "Civil": 6, "EEE": 5, "Information Technology": 4]
        let total = selectable.reduce(0) { $0 + (counts[$1] ?? 5) }
        return (total, total, 0, String(localized: "\(total) faculty in \(stream) · \(selectable.joined(separator: ", "))"))
    }

    /// Representative members for the selected scope.
    private static func members(stream: String?, departments: [String]) -> [FacultyMember] {
        let selectable = Set(departments.filter { $0 != "All departments" })
        var result: [FacultyMember] = []

        func include(_ dept: String) -> Bool { selectable.isEmpty || selectable.contains(dept) }

        let artsAndScience = (stream == nil || stream == "Arts and Science")
        let engineering = (stream == nil || stream == "Engineering")

        if artsAndScience {
            if include("Tamil") { result += tamil }
            if include("Mathematics") { result += mathematics }
            if include("Computer Science") { result += computerScience }
            if include("English") { result += english }
            if include("Physics") { result += physics }
        }
        if engineering {
            if include("CSE") { result += cse }
        }
        return result
    }

    private static func groupByDepartment(_ members: [FacultyMember]) -> [FacultyDeptGroup] {
        let departments = members.map(\.department)
        var seen: [String] = []
        for dept in departments where !seen.contains(dept) { seen.append(dept) }
        return seen.map { dept in
            let group = members.filter { $0.department == dept }
            return FacultyDeptGroup(department: dept, presentToday: group.filter { $0.presence == .present }.count, members: group)
        }
    }

    private static func divisionGroups(from members: [FacultyMember]) -> [FacultyDivisionGroup] {
        [
            FacultyDivisionGroup(id: "d1", divisionLabel: "B.Sc CS · Sem 1 · Division A",
                                 classTeacher: "Dr. Geetha Arumugam", members: Array(computerScience.prefix(3))),
            FacultyDivisionGroup(id: "d2", divisionLabel: "B.Sc CS · Sem 3 · Division B",
                                 classTeacher: "Dr. Anitha Rajan", members: Array(computerScience.prefix(2))),
            FacultyDivisionGroup(id: "d3", divisionLabel: "B.Sc CS · Sem 5 · Division A",
                                 classTeacher: "Dr. Anitha Rajan", members: Array(computerScience.prefix(4))),
        ]
    }

    private static func member(_ id: String, _ name: String, _ designation: String, _ dept: String, _ stream: String,
                               _ subjects: String, _ role: FacultyRole = .none, _ presence: FacultyPresence = .present,
                               _ detail: String = "Present · 08:55 AM") -> FacultyMember {
        FacultyMember(id: id, name: name, designation: designation, department: dept, stream: stream,
                      subjects: subjects, role: role, presence: presence, presenceDetail: detail)
    }

    private static let tamil: [FacultyMember] = [
        member("t1", "Dr. Sivakumar Raju", "Professor and Head", "Tamil", "Arts and Science", "Tamil Literature, Sangam Poetry", .headOfDept, .present, "Present · 08:56 AM"),
        member("t2", "Dr. Jayanthi Ramesh", "Assistant Professor", "Tamil", "Arts and Science", "Modern Tamil Prose", .classTeacher, .present, "Present · 09:02 AM"),
        member("t3", "Mr. Murugan Pandi", "Assistant Professor", "Tamil", "Arts and Science", "Grammar, Linguistics", .none, .present, "Present · 08:48 AM"),
        member("t4", "Dr. Kavipriya S.", "Associate Professor", "Tamil", "Arts and Science", "Bhakti Literature", .none, .present, "Present · 08:51 AM"),
        member("t5", "Mrs. Tamilselvi K.", "Assistant Professor", "Tamil", "Arts and Science", "Folk Literature", .none, .present, "Present · 09:05 AM"),
    ]

    private static let mathematics: [FacultyMember] = [
        member("m1", "Dr. Abirami Nagarajan", "Professor and Head", "Mathematics", "Arts and Science", "Real Analysis, Linear Algebra", .headOfDept, .present, "Present · 08:40 AM"),
        member("m2", "Dr. Gayathri Pandian", "Professor", "Mathematics", "Arts and Science", "Topology, Number Theory", .classTeacher, .present, "Present · 08:45 AM"),
        member("m3", "Dr. Revathi Shankar", "Assistant Professor", "Mathematics", "Arts and Science", "Statistics, Probability", .none, .present, "Present · 08:58 AM"),
        member("m4", "Mr. Senthil Kumar", "Assistant Professor", "Mathematics", "Arts and Science", "Discrete Mathematics", .none, .present, "Present · 09:00 AM"),
        member("m5", "Dr. Bhuvana Sekar", "Associate Professor", "Mathematics", "Arts and Science", "Graph Theory", .none, .present, "Present · 08:52 AM"),
        member("m6", "Mrs. Lalitha Mohan", "Assistant Professor", "Mathematics", "Arts and Science", "Calculus", .none, .present, "Present · 08:47 AM"),
        member("m7", "Dr. Ramesh Iyer", "Professor", "Mathematics", "Arts and Science", "Differential Equations", .none, .present, "Present · 08:38 AM"),
    ]

    private static let computerScience: [FacultyMember] = [
        member("c1", "Dr. Senthil Kumar Ganesan", "Professor and Head", "Computer Science", "Arts and Science", "AI, Machine Learning", .headOfDept, .present, "Present · 08:58 AM"),
        member("c2", "Dr. Geetha Arumugam", "Assistant Professor", "Computer Science", "Arts and Science", "Data Structures", .classTeacher, .present, "Present · 09:01 AM"),
        member("c3", "Dr. Anitha Rajan", "Associate Professor", "Computer Science", "Arts and Science", "Database Systems, Python", .classTeacher, .present, "Present · 08:47 AM"),
        member("c4", "Mr. Vignesh Babu", "Assistant Professor", "Computer Science", "Arts and Science", "Web Technologies", .none, .present, "Present · 08:55 AM"),
        member("c5", "Dr. Kavitha Mohan", "Associate Professor", "Computer Science", "Arts and Science", "Operating Systems", .none, .present, "Present · 08:50 AM"),
        member("c6", "Mrs. Deepa Raman", "Assistant Professor", "Computer Science", "Arts and Science", "Computer Networks", .none, .present, "Present · 09:03 AM"),
        member("c7", "Mr. Karthik Selvan", "Assistant Professor", "Computer Science", "Arts and Science", "Software Engineering", .none, .present, "Present · 08:42 AM"),
    ]

    private static let english: [FacultyMember] = [
        member("e1", "Dr. Grace Thomas", "Professor and Head", "English", "Arts and Science", "British Literature", .headOfDept, .present, "Present · 08:49 AM"),
        member("e2", "Mrs. Fathima Noor", "Assistant Professor", "English", "Arts and Science", "Phonetics", .classTeacher, .present, "Present · 08:59 AM"),
        member("e3", "Mr. Daniel Raj", "Assistant Professor", "English", "Arts and Science", "Creative Writing", .none, .onLeave, "On casual leave (approved)"),
        member("e4", "Dr. Suganya Pillai", "Associate Professor", "English", "Arts and Science", "Post-colonial Studies", .none, .present, "Present · 08:44 AM"),
        member("e5", "Mrs. Angela Fernandes", "Assistant Professor", "English", "Arts and Science", "Communication Skills", .none, .present, "Present · 09:06 AM"),
        member("e6", "Mr. Joseph Antony", "Assistant Professor", "English", "Arts and Science", "Drama, Poetry", .none, .present, "Present · 08:53 AM"),
    ]

    private static let physics: [FacultyMember] = [
        member("p1", "Dr. Gopinath Narayanan", "Professor and Head", "Physics", "Arts and Science", "Quantum Mechanics", .headOfDept, .present, "Present · 08:41 AM"),
        member("p2", "Dr. Meenakshi Sundaram", "Professor", "Physics", "Arts and Science", "Optics, Electromagnetism", .classTeacher, .present, "Present · 08:46 AM"),
        member("p3", "Mr. Ravi Shankar", "Assistant Professor", "Physics", "Arts and Science", "Thermodynamics", .none, .notPunchedIn, "No punch-in recorded yet"),
        member("p4", "Dr. Padma Lakshmi", "Associate Professor", "Physics", "Arts and Science", "Solid State Physics", .none, .present, "Present · 08:57 AM"),
        member("p5", "Mrs. Nithya Bala", "Assistant Professor", "Physics", "Arts and Science", "Nuclear Physics", .none, .present, "Present · 09:04 AM"),
    ]

    private static let cse: [FacultyMember] = [
        member("en1", "Dr. Meena Krishnan", "Professor", "CSE", "Engineering", "DBMS, Data Mining", .classTeacher, .present, "Present · 08:41 AM"),
        member("en2", "Prof. Karthik Raman", "Associate Professor", "CSE", "Engineering", "Operating Systems", .none, .present, "Present · 08:52 AM"),
        member("en3", "Prof. Vignesh Prabhu", "Assistant Professor", "CSE", "Engineering", "Theory of Computation", .none, .onLeave, "On sick leave (approved)"),
        member("en4", "Dr. Priya Natarajan", "Associate Professor", "CSE", "Engineering", "Data Structures", .none, .notPunchedIn, "Not punched in by 09:15 AM"),
        member("en5", "Mr. Arul Doss", "Assistant Professor", "CSE", "Engineering", "Computer Networks", .none, .present, "Present · 08:48 AM"),
    ]
}
