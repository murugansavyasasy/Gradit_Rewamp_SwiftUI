//
//  MockAttendanceService.swift
//  Gradit
//
//  In-memory attendance report used in DEBUG, previews and tests.
//  Numbers mirror the design (Students · Today · CSE · III Sem 6).
//

import Foundation

final class MockAttendanceService: AttendanceServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    func report(range: AttendanceRange,
                audience: AttendanceAudience,
                department: String,
                yearSem: String) async throws -> AttendanceReport {
        try await Task.sleep(for: latency)

        switch audience {
        case .students:
            return AttendanceReport(
                stats: [
                    AttendanceStat(id: "overall", title: String(localized: "Overall attendance"),
                                   value: "87.3%", deltaText: String(localized: "2.1 pts better"),
                                   trend: .up, emphasized: true),
                    AttendanceStat(id: "present", title: String(localized: "Present"),
                                   value: "2,184", deltaText: String(localized: "63 better"), trend: .up),
                    AttendanceStat(id: "absent", title: String(localized: "Absent"),
                                   value: "236", deltaText: String(localized: "12 better"), trend: .up),
                    AttendanceStat(id: "late", title: String(localized: "Late / on leave"),
                                   value: "82", deltaText: String(localized: "12 better"), trend: .up),
                ],
                byPeriod: [
                    PeriodAttendance(id: "P1", percent: 86.7),
                    PeriodAttendance(id: "P2", percent: 87.3),
                    PeriodAttendance(id: "P3", percent: 88.1),
                    PeriodAttendance(id: "P4", percent: 85.9),
                    PeriodAttendance(id: "P5", percent: 87.8),
                    PeriodAttendance(id: "P6", percent: 86.2),
                ]
            )
        case .staff:
            return AttendanceReport(
                stats: [
                    AttendanceStat(id: "overall", title: String(localized: "Overall attendance"),
                                   value: "94.1%", deltaText: String(localized: "1.2 pts better"),
                                   trend: .up, emphasized: true),
                    AttendanceStat(id: "present", title: String(localized: "Present"),
                                   value: "148", deltaText: String(localized: "3 better"), trend: .up),
                    AttendanceStat(id: "absent", title: String(localized: "Absent"),
                                   value: "9", deltaText: String(localized: "2 better"), trend: .up),
                    AttendanceStat(id: "late", title: String(localized: "Late / on leave"),
                                   value: "5", deltaText: String(localized: "no change"), trend: .flat),
                ],
                byPeriod: [
                    PeriodAttendance(id: "P1", percent: 95.0),
                    PeriodAttendance(id: "P2", percent: 94.1),
                    PeriodAttendance(id: "P3", percent: 93.2),
                    PeriodAttendance(id: "P4", percent: 94.8),
                    PeriodAttendance(id: "P5", percent: 92.9),
                    PeriodAttendance(id: "P6", percent: 94.4),
                ]
            )
        }
    }

    func staffToday() async throws -> StaffAttendanceToday {
        try await Task.sleep(for: latency)
        return StaffAttendanceToday(
            dateLabel: "Wednesday, 07 Oct 2026",
            lastUpdated: String(localized: "Last updated at 11:10 AM · from Mark Your Attendance"),
            total: 102, present: 94, absent: 3, onLeave: 3, late: 7, notPunchedIn: 2,
            staff: [
                StaffMember(id: "s1", name: "Dr. Priya Natarajan", department: "Information Technology",
                            designation: "Associate Professor", status: .absent,
                            detail: String(localized: "Not punched in by 09:15 AM"),
                            freePeriodsNote: String(localized: "2 periods free today")),
                StaffMember(id: "s2", name: "Mr. Kumaravel Natesan", department: "Mechanical",
                            designation: "Assistant Professor", status: .absent,
                            detail: String(localized: "Not punched in by 09:15 AM · no classes"), freePeriodsNote: nil),
                StaffMember(id: "s3", name: "Dr. Suresh Babu", department: "Civil",
                            designation: "Professor", status: .absent,
                            detail: String(localized: "On duty · inspection visit"), freePeriodsNote: nil),
                StaffMember(id: "s4", name: "Dr. Gayathri Pandian", department: "Mathematics",
                            designation: "Professor", status: .late,
                            detail: String(localized: "In 09:05 AM · Out not yet · 2h 05m so far"), freePeriodsNote: nil),
                StaffMember(id: "s5", name: "Dr. Geetha Arumugam", department: "Computer Science",
                            designation: "Assistant Professor", status: .late,
                            detail: String(localized: "In 09:12 AM · Out not yet · 1h 58m so far"), freePeriodsNote: nil),
                StaffMember(id: "s6", name: "Dr. Gopinath Narayanan", department: "Physics",
                            designation: "Associate Professor", status: .late,
                            detail: String(localized: "In 09:18 AM · Out not yet · 1h 52m so far"), freePeriodsNote: nil),
                StaffMember(id: "s7", name: "Dr. Lakshmi Sundar", department: "Information Technology",
                            designation: "Professor", status: .onLeave,
                            detail: String(localized: "Casual leave · approved"), freePeriodsNote: nil),
                StaffMember(id: "s8", name: "Prof. Vignesh Prabhu", department: "Computer Science",
                            designation: "Assistant Professor", status: .onLeave,
                            detail: String(localized: "Sick leave · approved"), freePeriodsNote: String(localized: "4 periods free today")),
                StaffMember(id: "s9", name: "Dr. Meena Krishnan", department: "Computer Science",
                            designation: "Professor", status: .present,
                            detail: String(localized: "In 08:41 AM · on campus"), freePeriodsNote: nil),
                StaffMember(id: "s10", name: "Prof. Karthik Raman", department: "Computer Science",
                            designation: "Associate Professor", status: .present,
                            detail: String(localized: "In 08:52 AM · on campus"), freePeriodsNote: nil),
                StaffMember(id: "s11", name: "Mr. Arul Doss", department: "Mechanical",
                            designation: "Assistant Professor", status: .notPunchedIn,
                            detail: String(localized: "No punch-in recorded yet"), freePeriodsNote: nil),
                StaffMember(id: "s12", name: "Dr. Revathi Shankar", department: "Mathematics",
                            designation: "Assistant Professor", status: .notPunchedIn,
                            detail: String(localized: "No punch-in recorded yet"), freePeriodsNote: nil),
            ]
        )
    }

    func staffMonthly(year: Int, month: Int?) async throws -> StaffAttendanceMonthly {
        try await Task.sleep(for: latency)
        let rows = [
            StaffMonthlyRow(id: "s1", name: "Dr. Abirami Mani", department: "Physics",
                            designation: "Professor and Head", percent: 100, present: 5, absent: 0, leave: 0, late: 1),
            StaffMonthlyRow(id: "s2", name: "Dr. Abirami Nagarajan", department: "Mathematics",
                            designation: "Professor and Head", percent: 100, present: 5, absent: 0, leave: 0, late: 0),
            StaffMonthlyRow(id: "s3", name: "Dr. Anitha Periyasamy", department: "History",
                            designation: "Assistant Professor", percent: 100, present: 5, absent: 0, leave: 0, late: 0),
            StaffMonthlyRow(id: "s4", name: "Dr. Anitha Rajan", department: "Computer Science",
                            designation: "Associate Professor", percent: 80, present: 4, absent: 1, leave: 0, late: 2),
            StaffMonthlyRow(id: "s5", name: "Dr. Bhuvana Sekar", department: "Chemistry",
                            designation: "Professor", percent: 72, present: 3, absent: 2, leave: 0, late: 1),
            StaffMonthlyRow(id: "s6", name: "Mr. Chandran Velu", department: "Mechanical",
                            designation: "Assistant Professor", percent: 60, present: 3, absent: 1, leave: 1, late: 0),
        ]
        return StaffAttendanceMonthly(averagePercent: 94, belowThreshold: 4, workingDays: 5, leaveDays: 19, staff: rows)
    }

    func facultyClasses() async throws -> [FacultyClassSession] {
        try await Task.sleep(for: latency)
        return [
            FacultyClassSession(id: "c1", subject: "DBMS", classLabel: "B.E. CSE · Sem 5 A",
                                room: "Room B-204 · 58 students", period: "P1", time: "09:00 AM", total: 58, takenCount: 52),
            FacultyClassSession(id: "c2", subject: "DBMS Lab", classLabel: "B.E. CSE · Sem 5 B",
                                room: "Lab 3 · 42 students", period: "P3", time: "11:30 AM", total: 42, takenCount: nil),
            FacultyClassSession(id: "c3", subject: "Mentoring hour", classLabel: "B.E. CSE · Sem 5 A",
                                room: "Room B-204 · 58 students", period: "P6", time: "02:00 PM", total: 58, takenCount: nil),
        ]
    }

    func leaveRequests() async throws -> [StudentLeaveRequest] {
        try await Task.sleep(for: latency)
        return [
            StudentLeaveRequest(id: "l1", studentName: "Rahul Kumar",
                                classLabel: "B.E. CSE · Sem 5 A · Reg. 2024503041",
                                leaveType: "Sick leave", appliedText: String(localized: "Applied today, 08:12 AM"),
                                fromText: "07 Oct", toText: "08 Oct", days: 2,
                                reason: "Running a high fever since last night. The doctor has advised two days of rest.",
                                status: .pending),
            StudentLeaveRequest(id: "l2", studentName: "Sneha Nair",
                                classLabel: "B.E. CSE · Sem 5 A · Reg. 2024503052",
                                leaveType: "Casual leave", appliedText: String(localized: "Applied 05 Oct, 07:40 PM"),
                                fromText: "09 Oct", toText: "09 Oct", days: 1,
                                reason: "Family function at our native place in Thanjavur.", status: .pending),
            StudentLeaveRequest(id: "l3", studentName: "Arjun Dev",
                                classLabel: "B.E. CSE · Sem 5 A · Reg. 2024503022",
                                leaveType: "Medical leave", appliedText: String(localized: "Applied 02 Oct, 09:10 AM"),
                                fromText: "03 Oct", toText: "03 Oct", days: 1,
                                reason: "Dental surgery follow-up.", status: .approved),
        ]
    }

    func classRoster(sessionID: String) async throws -> [RosterStudent] {
        try await Task.sleep(for: latency)
        let names = [
            ("Aakash M.", "2024503101", "UCE24CS101"), ("Abinaya S.", "2024503102", "UCE24CS102"),
            ("Bharath K.", "2024503103", "UCE24CS103"), ("Divya R.", "2024503104", "UCE24CS104"),
            ("Gokul V.", "2024503105", "UCE24CS105"), ("Harini P.", "2024503106", "UCE24CS106"),
            ("Karthik S.", "2024503107", "UCE24CS107"), ("Lavanya M.", "2024503108", "UCE24CS108"),
            ("Rohit M.", "2024503109", "UCE24CS109"), ("Vijay A.", "2024503110", "UCE24CS110"),
        ]
        return names.enumerated().map { index, item in
            let status: MarkStatus = [3, 8, 9].contains(index) ? .absent : (index == 5 ? .onDuty : (index == 7 ? .onLeave : .present))
            return RosterStudent(id: "r\(index)", name: item.0, registerNo: item.1, admissionNo: item.2, status: status)
        }
    }

    func learnerAttendance(studentID: String?) async throws -> LearnerAttendance {
        try await Task.sleep(for: latency)
        // October 2026 starts on a Thursday (weekday index 4).
        let marked: [LearnerDay] = [
            LearnerDay(id: 1, status: .present), LearnerDay(id: 2, status: .holiday),
            LearnerDay(id: 3, status: .present), LearnerDay(id: 5, status: .partlyPresent, isToday: false),
            LearnerDay(id: 6, status: .present, isToday: true),
        ]
        return LearnerAttendance(
            studentName: "Aarav R.", classLabel: "B.E. CSE · Sem 5 A",
            overallPercent: 86, rangeLabel: String(localized: "OVERALL · JUL – NOV 2026"),
            presentDays: 112, totalDays: 130, monthLabel: "October 2026",
            firstWeekday: 4, daysInMonth: 31, days: marked,
            subjects: [
                LearnerSubject(id: "dbms", name: "Database Management Systems", teacher: "Dr. Meena Krishnan",
                               percent: 96, hoursAttended: 24, hoursAbsent: 1),
                LearnerSubject(id: "os", name: "Operating Systems", teacher: "Prof. Karthik Raman",
                               percent: 90, hoursAttended: 27, hoursAbsent: 3),
                LearnerSubject(id: "cn", name: "Computer Networks", teacher: "Dr. Lakshmi Sundar",
                               percent: 78, hoursAttended: 21, hoursAbsent: 6),
                LearnerSubject(id: "toc", name: "Theory of Computation", teacher: "Prof. Vignesh Prabhu",
                               percent: 72, hoursAttended: 18, hoursAbsent: 7),
            ],
            periods: [
                LearnerDayPeriod(id: "P1", subject: "Database Management Systems", time: "09:00 – 09:50 AM", present: true),
                LearnerDayPeriod(id: "P2", subject: "Operating Systems", time: "09:50 – 10:40 AM", present: true),
                LearnerDayPeriod(id: "P3", subject: "Computer Networks", time: "11:00 – 11:50 AM", present: false),
                LearnerDayPeriod(id: "P4", subject: "Theory of Computation", time: "11:50 AM – 12:40 PM", present: true),
                LearnerDayPeriod(id: "P5", subject: "DBMS Lab", time: "02:00 – 03:40 PM", present: true),
            ],
            leaves: [
                LearnerLeave(id: "lv1", type: "Sick leave", status: .pending, appliedOn: "Applied on 06 Oct 2026",
                             fromText: "07 Oct 2026", toText: "08 Oct 2026", days: 2,
                             reason: "Fever since last night. The doctor has advised two days of rest.", note: nil),
                LearnerLeave(id: "lv2", type: "Casual leave", status: .approved, appliedOn: "Applied on 18 Sep 2026",
                             fromText: "22 Sep 2026", toText: "22 Sep 2026", days: 1,
                             reason: "Attending my sister’s wedding reception in Madurai.",
                             note: String(localized: "Approved by Dr. Meena Krishnan, class advisor")),
                LearnerLeave(id: "lv3", type: "On duty", status: .rejected, appliedOn: "Applied on 07 Sep 2026",
                             fromText: "09 Sep 2026", toText: "09 Sep 2026", days: 1,
                             reason: "Inter-college hackathon at Anna University, Guindy.",
                             note: String(localized: "The event was not approved by the department. Please get the HoD’s letter first.")),
            ]
        )
    }

    func selfAttendance() async throws -> SelfAttendanceState {
        try await Task.sleep(for: latency)
        return SelfAttendanceState(
            dateLabel: "Tuesday, 6 October 2026",
            locationLabel: "Inside campus · Admin block",
            isInsideCampus: true,
            locationNote: String(localized: "Location verified 20 seconds ago · accuracy 12 m"),
            shiftStartNote: String(localized: "You haven't checked in today. Shift starts at 9:00 AM."),
            checkInTime: nil, checkOutTime: nil, hoursText: nil,
            monthSummary: String(localized: "This month: 4 of 4 days present"),
            history: [
                SelfAttendanceDay(id: "d5", dayNumber: 5, weekday: "Mon", timeRange: "8:52 AM – 5:06 PM",
                                  detail: "8h 14m · Admin block", status: .present),
                SelfAttendanceDay(id: "d3", dayNumber: 3, weekday: "Sat", timeRange: "8:58 AM – 1:02 PM",
                                  detail: String(localized: "4h 04m · Saturday half day"), status: .halfDay),
                SelfAttendanceDay(id: "d2", dayNumber: 2, weekday: "Fri", timeRange: nil,
                                  detail: "Gandhi Jayanti", status: .holiday),
            ]
        )
    }
}
