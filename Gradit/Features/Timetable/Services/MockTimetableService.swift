//
//  MockTimetableService.swift
//  Gradit
//
//  In-memory timetable data used in DEBUG, previews and tests. Mirrors timetableModule.pdf.
//

import Foundation

final class MockTimetableService: TimetableServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    // MARK: - Shared grid building

    static let periods: [TimetablePeriod] = [
        .init(id: "P1", time: "09:00 – 09:50 AM", shortStart: "09:00", breakAfter: nil),
        .init(id: "P2", time: "09:50 – 10:40 AM", shortStart: "09:50", breakAfter: "Break · 10:40 – 10:55"),
        .init(id: "P3", time: "10:55 – 11:45 AM", shortStart: "10:55", breakAfter: nil),
        .init(id: "P4", time: "11:45 AM – 12:35 PM", shortStart: "11:45", breakAfter: "Lunch · 12:35 – 01:25"),
        .init(id: "P5", time: "01:25 – 02:15 PM", shortStart: "01:25", breakAfter: nil),
        .init(id: "P6", time: "02:15 – 03:05 PM", shortStart: "02:15", breakAfter: nil),
        .init(id: "P7", time: "03:05 – 03:55 PM", shortStart: "03:05", breakAfter: nil),
    ]
    static let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private static let subjectName: [String: String] = [
        "DBMS": "Database Management Systems", "OS": "Operating Systems", "CN": "Computer Networks",
        "TOC": "Theory of Computation", "ES": "Environmental Science", "DBL": "DBMS Lab",
        "MEN": "Mentoring hour", "LIB": "Library", "SPT": "Sports",
    ]
    private static let subjectTeacher: [String: (String, String)] = [
        "DBMS": ("Dr. Meena Krishnan", "MK"), "OS": ("Prof. Karthik Raman", "KR"),
        "CN": ("Dr. Lakshmi Sundar", "LS"), "TOC": ("Prof. Vignesh Prabhu", "VP"),
        "ES": ("Dr. Revathi S.", "RS"), "DBL": ("Dr. Meena Krishnan", "MK"),
        "MEN": ("Dr. Meena Krishnan", "MK"), "LIB": ("Library staff", "LB"), "SPT": ("Sports dept", "SP"),
    ]
    private static func room(_ code: String) -> String { code == "DBL" ? "Lab 3" : "B-204" }

    /// Base subject matrix [period][day] mirroring the design week grid.
    private static let matrix: [String: [String: String]] = [
        "P1": ["Mon": "DBMS", "Tue": "OS", "Wed": "DBMS", "Thu": "TOC", "Fri": "CN", "Sat": "OS"],
        "P2": ["Mon": "OS", "Tue": "CN", "Wed": "CN", "Thu": "DBMS", "Fri": "TOC", "Sat": "CN"],
        "P3": ["Mon": "CN", "Tue": "DBMS", "Wed": "OS", "Thu": "OS", "Fri": "DBMS", "Sat": "DBMS"],
        "P4": ["Mon": "TOC", "Tue": "TOC", "Wed": "TOC", "Thu": "CN", "Fri": "OS", "Sat": "TOC"],
        "P5": ["Mon": "DBL", "Tue": "ES", "Wed": "ES", "Thu": "DBL", "Fri": "ES"],
        "P6": ["Mon": "DBL", "Tue": "OS", "Wed": "MEN", "Thu": "DBL", "Fri": "LIB"],
        "P7": ["Mon": "MEN", "Tue": "LIB", "Wed": "CN", "Thu": "ES", "Fri": "SPT"],
    ]

    private static func baseGrid(stateOverrides: [String: CellState] = [:]) -> TimetableGrid {
        var cells: [TimetableCell] = []
        for period in periods {
            for day in days {
                let code = matrix[period.id]?[day]
                let key = "\(day)-\(period.id)"
                if let code {
                    let teacher = subjectTeacher[code]
                    cells.append(TimetableCell(
                        day: day, period: period.id, subjectCode: code, subjectName: subjectName[code],
                        teacher: teacher?.0, teacherInitials: teacher?.1, room: room(code),
                        state: stateOverrides[key] ?? .normal, clashReason: nil))
                } else {
                    cells.append(TimetableCell(day: day, period: period.id, subjectCode: nil, subjectName: nil,
                                               teacher: nil, teacherInitials: nil, room: nil,
                                               state: stateOverrides[key] ?? .empty, clashReason: nil))
                }
            }
        }
        return TimetableGrid(periods: periods, days: days, cells: cells)
    }

    // MARK: - Admin

    func timetables() async throws -> [TimetableSummary] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "t1", classLabel: "B.E. CSE · Sem 5 · A", term: "Odd semester 2026–27 · Jul – Nov",
                  periodsPerWeek: 39, updatedText: "Updated today, 11:05 AM", status: .draft,
                  issuesText: "2 clashes · 2 empty periods to fix"),
            .init(id: "t2", classLabel: "B.E. CSE · Sem 5 · B", term: "Odd semester 2026–27 · Jul – Nov",
                  periodsPerWeek: 39, updatedText: "Updated 05 Oct 2026", status: .published, issuesText: nil),
            .init(id: "t3", classLabel: "B.E. CSE · Sem 3 · A", term: "Odd semester 2026–27 · Jul – Nov",
                  periodsPerWeek: 40, updatedText: "Updated 02 Oct 2026", status: .published, issuesText: nil),
            .init(id: "t4", classLabel: "B.E. CSE · Sem 7 · A", term: "Odd semester 2026–27 · Jul – Nov",
                  periodsPerWeek: 36, updatedText: "Updated 30 Sep 2026", status: .published, issuesText: nil),
        ]
    }

    func editor(id: String?) async throws -> TimetableEditor {
        try await Task.sleep(for: latency)
        var grid = Self.baseGrid(stateOverrides: ["Wed-P3": .clash, "Thu-P5": .clash, "Thu-P6": .clash])
        // Annotate the clash cells with a reason.
        for index in grid.cells.indices where grid.cells[index].state == .clash {
            grid.cells[index].clashReason = "Clash"
        }
        return TimetableEditor(
            id: id ?? "new",
            classLabel: "B.E. CSE · Sem 5 · A · from Mon, 12 Oct",
            status: .draft, grid: grid,
            clashes: [
                .init(id: "c1", title: "Faculty clash · Wed P3",
                      detail: "Dr. Lakshmi Sundar is already teaching B.E. CSE Sem 5 B (Computer Networks) at 10:55 AM on Wednesday.",
                      primaryAction: "Swap with Wed P4 (TOC)"),
                .init(id: "c2", title: "Room double-booked · Thu P5–P6",
                      detail: "Lab 3 is booked for B.E. CSE Sem 5 B (DBMS Lab) at the same time.",
                      primaryAction: "Move to Lab 2 (free)"),
            ],
            emptyPeriods: ["Tue P6", "Fri P7"],
            subjectPalette: [
                .init(code: "DBMS", name: "Database"), .init(code: "OS", name: "Operating"),
                .init(code: "CN", name: "Computer"), .init(code: "TOC", name: "Theory"),
                .init(code: "ES", name: "Environment"), .init(code: "DBL", name: "Lab"),
                .init(code: "MEN", name: "Mentoring"), .init(code: "LIB", name: "Library"),
                .init(code: "SPT", name: "Sports"),
            ],
            faculties: ["Dr. Lakshmi Sundar — busy", "Prof. Karthik Raman", "Dr. Meena Krishnan",
                        "Prof. Vignesh Prabhu", "Dr. Kavitha Mohan"],
            rooms: ["B-204", "B-206", "B-210", "Lab 2", "Lab 3", "C-108"])
    }

    // MARK: - Faculty

    func facultyTimetable() async throws -> FacultyTimetable {
        try await Task.sleep(for: latency)
        let wed: [FacultyPeriodItem] = [
            .init(id: "f1", period: "P1", time: "09:00 – 09:50", subjectName: "Database Management Systems",
                  classLabel: "B.E. CSE · Sem 5 A · B-204", state: .done, note: nil),
            .init(id: "f2", period: "P4", time: "11:45 AM – 12:35 PM", subjectName: "DBMS Lab",
                  classLabel: "B.E. CSE · Sem 5 B · Lab 3", state: .next, note: nil),
            .init(id: "f3", period: "P5", time: "01:25 – 02:15 PM", subjectName: "DBMS Lab",
                  classLabel: "B.E. CSE · Sem 5 B · Lab 3", state: .normal, note: nil),
            .init(id: "f4", period: "P6", time: "02:15 – 03:05 PM", subjectName: "Mentoring hour",
                  classLabel: "B.E. CSE · Sem 5 A · B-204", state: .normal, note: nil),
            .init(id: "f5", period: "P7", time: "03:05 – 03:55 PM", subjectName: "Theory of Computation",
                  classLabel: "B.E. CSE · Sem 7 A · C-301", state: .cover,
                  note: "Cover for Prof. Vignesh Prabhu · allocated by the Principal"),
        ]
        let fri: [FacultyPeriodItem] = [
            .init(id: "g1", period: "P3", time: "10:55 – 11:45 AM", subjectName: "Database Management Systems",
                  classLabel: "B.E. CSE · Sem 5 A · B-204", state: .normal, note: nil),
            .init(id: "g2", period: "P5", time: "01:25 – 02:15 PM", subjectName: "DBMS Lab",
                  classLabel: "B.E. CSE · Sem 5 B · Lab 3", state: .normal, note: nil),
        ]
        return FacultyTimetable(
            teacher: "Dr. Meena Krishnan · CSE",
            swapBanner: SwapBanner(requester: "Dr. Lakshmi Sundar",
                                   detail: "Mon, 12 Oct · your P1 ⇄ her P3 · reply before Monday"),
            days: [
                .init(date: "5", weekday: "Mon", isToday: false),
                .init(date: "6", weekday: "Tue", isToday: false),
                .init(date: "7", weekday: "Wed", isToday: true),
                .init(date: "8", weekday: "Thu", isToday: false),
                .init(date: "9", weekday: "Fri", isToday: false),
                .init(date: "10", weekday: "Sat", isToday: false),
            ],
            periodsByDay: ["7": wed, "9": fri])
    }

    func swapRequests() async throws -> [SwapRequest] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "s1", isSent: true, status: .pending, dateText: "Fri, 09 Oct", counterpart: "Prof. Karthik Raman",
                  giveSummary: "P3 · 10:55 AM · DBMS · You",
                  takeSummary: "P4 · 11:45 AM · Operating Systems · Prof. Karthik Raman",
                  classLabel: "B.E. CSE Sem 5 A", metaText: "Sent today, 09:40 AM · B.E. CSE Sem 5 A"),
            .init(id: "s2", isSent: false, status: .needsReply, dateText: "Mon, 12 Oct", counterpart: "Dr. Lakshmi Sundar",
                  giveSummary: "P1 · 09:00 AM · DBMS · You",
                  takeSummary: "P3 · 10:55 AM · Computer Networks · Dr. Lakshmi Sundar",
                  classLabel: "B.E. CSE Sem 5 A", metaText: "Received today, 08:30 AM · waiting for your reply"),
            .init(id: "s3", isSent: true, status: .accepted, dateText: "Mon, 05 Oct", counterpart: "Dr. Revathi S.",
                  giveSummary: "P5 · 01:25 PM · DBMS Lab · You",
                  takeSummary: "P6 · 02:15 PM · Environmental Science · Dr. Revathi S.",
                  classLabel: "B.E. CSE Sem 5 A", metaText: "Accepted by Dr. Revathi S. · 03 Oct, 04:10 PM"),
            .init(id: "s4", isSent: true, status: .declined, dateText: "Wed, 30 Sep", counterpart: "Prof. Vignesh Prabhu",
                  giveSummary: "P2 · 09:50 AM · DBMS · You",
                  takeSummary: "P4 · 11:45 AM · Theory of Computation · Prof. Vignesh Prabhu",
                  classLabel: "B.E. CSE Sem 5 A", metaText: "Declined · 29 Sep, 05:00 PM"),
            .init(id: "s5", isSent: false, status: .expired, dateText: "Mon, 28 Sep", counterpart: "Dr. Lakshmi Sundar",
                  giveSummary: "P1 · 09:00 AM · DBMS · You",
                  takeSummary: "P3 · 10:55 AM · Computer Networks · Dr. Lakshmi Sundar",
                  classLabel: "B.E. CSE Sem 5 A", metaText: "Expired · 28 Sep passed without a reply"),
        ]
    }

    func swapCandidates(onDate date: String) async throws -> [SwapCandidate] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "p1", period: "P1", time: "09:00 AM – 09:50 AM", subject: "Computer Networks",
                  teacher: "Dr. Lakshmi Sundar", eligibility: "Teacher absent", selectable: false,
                  reason: "Dr. Lakshmi Sundar is on approved leave on Friday."),
            .init(id: "p2", period: "P2", time: "09:50 AM – 10:40 AM", subject: "Theory of Computation",
                  teacher: "Prof. Vignesh Prabhu", eligibility: "Not possible", selectable: false,
                  reason: "Prof. Vignesh Prabhu has Sem 7 A at 10:55 AM (your P3 time)."),
            .init(id: "p4", period: "P4", time: "11:45 AM – 12:35 PM", subject: "Operating Systems",
                  teacher: "Prof. Karthik Raman", eligibility: "Both free: he is free at 10:55 AM, you are free at 11:45 AM.",
                  selectable: true, reason: nil),
        ]
    }

    // MARK: - Learner

    func children() async throws -> [TimetableChild] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "aarav", name: "Aarav R.", classLabel: "B.E. CSE · Sem 5 A"),
            .init(id: "diya", name: "Diya R.", classLabel: "B.Tech IT · Sem 3 B"),
        ]
    }

    func classTimetable(childID: String?) async throws -> ClassTimetable {
        try await Task.sleep(for: latency)
        let wed: [LearnerPeriodItem] = [
            .init(id: "l1", period: "P1", time: "09:00 – 09:50 AM", subjectName: "Database Management Systems",
                  teacher: "Dr. Meena Krishnan", room: "B-204", state: .normal, changeNote: nil),
            .init(id: "l2", period: "P2", time: "09:50 – 10:40 AM", subjectName: "Computer Networks",
                  teacher: "Dr. Lakshmi Sundar", room: "B-204", state: .swapped, changeNote: "Swapped · Dr. Lakshmi Sundar"),
            .init(id: "l3", period: "P3", time: "10:55 – 11:45 AM", subjectName: "Operating Systems",
                  teacher: "Prof. Karthik Raman", room: "B-204", state: .now, changeNote: "Swapped · Prof. Karthik Raman"),
            .init(id: "l4", period: "P4", time: "11:45 AM – 12:35 PM", subjectName: "Theory of Computation",
                  teacher: "Dr. Kavitha M.", room: "B-204", state: .substitute,
                  changeNote: "Changed · Substitute: Dr. Kavitha M. for Prof. Vignesh Prabhu (absent)"),
            .init(id: "l5", period: "P5", time: "01:25 – 02:15 PM", subjectName: "Environmental Science",
                  teacher: "Dr. Revathi S.", room: "B-204", state: .normal, changeNote: nil),
            .init(id: "l6", period: "P6", time: "02:15 – 03:05 PM", subjectName: "Mentoring hour",
                  teacher: "Dr. Meena Krishnan", room: "B-204", state: .normal, changeNote: nil),
            .init(id: "l7", period: "P7", time: "03:05 – 03:55 PM", subjectName: "Computer Networks",
                  teacher: "Dr. Lakshmi Sundar", room: "B-204", state: .normal, changeNote: nil),
        ]
        let grid = Self.baseGrid(stateOverrides: [
            "Wed-P2": .swapped, "Wed-P3": .swapped, "Wed-P4": .substitute,
            "Sat-P5": .empty, "Sat-P6": .empty, "Sat-P7": .empty,
        ])
        return ClassTimetable(
            classLabel: childID == "diya" ? "B.Tech IT · Sem 3 B" : "B.E. CSE · Sem 5 A",
            updatedText: "Updated 05 Oct 2026 by the Principal's office",
            changesNote: "3 changes today\nP4 Theory of Computation: Substitute Dr. Kavitha M. for Prof. Vignesh Prabhu.\nP2 and P3 are swapped today: Computer Networks (Dr. Lakshmi Sundar) is now P2, Operating Systems (Prof. Karthik Raman) is now P3.",
            closedNote: nil, published: true,
            days: [
                .init(date: "5", weekday: "Mon", isToday: false),
                .init(date: "6", weekday: "Tue", isToday: false),
                .init(date: "7", weekday: "Wed", isToday: true),
                .init(date: "8", weekday: "Thu", isToday: false),
                .init(date: "9", weekday: "Fri", isToday: false),
                .init(date: "10", weekday: "Sat", isToday: false),
            ],
            periodsByDay: ["7": wed],
            weekGrid: grid)
    }
}
