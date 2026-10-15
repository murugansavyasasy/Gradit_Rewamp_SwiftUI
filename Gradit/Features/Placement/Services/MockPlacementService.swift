//
//  MockPlacementService.swift
//  Gradit
//
//  In-memory placement data used in DEBUG, previews and tests.
//  Mirrors placementModule.pdf (events) and placementTaining.pdf (training).
//

import Foundation

final class MockPlacementService: PlacementServiceProtocol {
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

    func items(kind: PlacementKind, tab: String, childID: String?) async throws -> PlacementBundle {
        try await Task.sleep(for: latency)
        let historical = tab == "historical"
        return kind == .events ? eventsBundle(historical: historical) : trainingBundle(historical: historical)
    }

    // MARK: - Events

    private func eventsBundle(historical: Bool) -> PlacementBundle {
        let alert = PlacementAlert(title: "1 event in the next 2 days",
                                   message: "Freshworks Pre-placement Talk, tomorrow at 10:00 AM", itemID: "ev-freshworks")
        if historical {
            return PlacementBundle(alert: alert, items: [
                PlacementItem(id: "ev-tata", title: "Placement on campus", subtitle: "Computer science placement",
                              typeLabel: "Placement event", mode: .onCampus, highlight: .ended, highlightText: "Ended",
                              dateMonth: "Sep", dateDay: "29", dateWeekday: "Tue", timeText: "10:40 AM",
                              locationText: "Campus", repeatText: nil, company: "Tata Electronics", trainer: nil,
                              chips: ["B.E. CSE", "B.Tech IT"], eligibilityNote: "Open to Aarav's and Diya's courses", section: "ENDED"),
                PlacementItem(id: "ev-edutech", title: "EduTech Fair", subtitle: "Internship program for graduates",
                              typeLabel: "Placement event", mode: .virtual, highlight: .ended, highlightText: "Ended",
                              dateMonth: "Sep", dateDay: "07", dateWeekday: "Mon", timeText: "10:00 AM",
                              locationText: "Chennai", repeatText: nil, company: "Vuram", trainer: nil,
                              chips: ["B.E. CSE", "B.Tech IT"], eligibilityNote: "Open to Aarav's and Diya's courses", section: "ENDED"),
            ])
        }
        return PlacementBundle(alert: alert, items: [
            PlacementItem(id: "ev-freshworks", title: "Freshworks Pre-placement Talk",
                          subtitle: "Summer Internship 2027 for pre-final year students",
                          typeLabel: "Pre-placement talk", mode: .virtual, highlight: .tomorrow, highlightText: "Tomorrow",
                          dateMonth: "Oct", dateDay: "08", dateWeekday: "Thu", timeText: "10:00 AM – 11:00 AM",
                          locationText: "Online · video meeting", repeatText: nil, company: "Freshworks", trainer: nil,
                          chips: ["B.E. CSE", "B.Tech IT"], eligibilityNote: "Open to Aarav's and Diya's courses", section: "THIS WEEK"),
            PlacementItem(id: "ev-infosys", title: "Infosys Campus Drive 2026",
                          subtitle: "InStep Internship and Systems Engineer roles",
                          typeLabel: "Campus drive", mode: .onCampus, highlight: .upcoming, highlightText: "In 11 days",
                          dateMonth: "Oct", dateDay: "18", dateWeekday: "Sun", timeText: "09:00 AM – 05:00 PM",
                          locationText: "Main auditorium, Block A", repeatText: nil, company: "Infosys", trainer: nil,
                          chips: ["B.E. CSE", "B.Tech IT"], eligibilityNote: "Open to Aarav's and Diya's courses", section: "LATER"),
            PlacementItem(id: "ev-deloitte", title: "Deloitte Analyst Hiring",
                          subtitle: "Audit and tax analyst roles for commerce and MBA graduates",
                          typeLabel: "Placement event", mode: .onCampus, highlight: .upcoming, highlightText: "In 15 days",
                          dateMonth: "Oct", dateDay: "22", dateWeekday: "Wed", timeText: "10:30 AM – 04:00 PM",
                          locationText: "Seminar hall, Block B", repeatText: nil, company: "Deloitte", trainer: nil,
                          chips: ["B.Com", "MBA"], eligibilityNote: "Not in Aarav's or Diya's courses", section: "LATER"),
            PlacementItem(id: "ev-chennai", title: "Chennai IT Job Fair 2026",
                          subtitle: "Internships and graduate roles from 12 companies",
                          typeLabel: "Job fair", mode: .offCampus, highlight: .upcoming, highlightText: "In 24 days",
                          dateMonth: "Oct", dateDay: "31", dateWeekday: "Sat", timeText: "10:00 AM – 04:00 PM",
                          locationText: "Chennai Trade Centre, Nandambakkam", repeatText: nil, company: "Zoho", trainer: nil,
                          chips: ["B.E. CSE", "B.Tech IT"], eligibilityNote: "Open to Aarav's and Diya's courses", section: "LATER"),
        ])
    }

    // MARK: - Training

    private func trainingBundle(historical: Bool) -> PlacementBundle {
        let alert = PlacementAlert(title: "2 sessions in the next 2 days",
                                   message: "Data Structures and Algorithms, Today, Wed 07 Oct at 02:00 PM · Spoken English, Fri 09 Oct at 03:05 PM", itemID: "tr-dsa")
        if historical {
            return PlacementBundle(alert: alert, items: [
                PlacementItem(id: "tr-python", title: "Python for Problem Solving", subtitle: "Python basics to intermediate problem solving",
                              typeLabel: "Placement training", mode: .onCampus, highlight: .ended, highlightText: "Ended",
                              dateMonth: "Aug", dateDay: "03", dateWeekday: "Mon", timeText: "03:05 PM – 03:55 PM",
                              locationText: "Computer centre, Lab 2, Block C",
                              repeatText: "Repeats every day, Monday to Friday until 28 Aug 2026", company: nil, trainer: "Mr. Arul Doss",
                              chips: ["2024"], eligibilityNote: "For Aarav's batch (2024)", section: "ENDED"),
            ])
        }
        return PlacementBundle(alert: alert, items: [
            PlacementItem(id: "tr-dsa", title: "Data Structures and Algorithms – Coding Track",
                          subtitle: "Problem solving for coding rounds: arrays, trees, graphs and dynamic programming",
                          typeLabel: "Placement training", mode: .onCampus, highlight: .today, highlightText: "Session today · 02:00 PM",
                          dateMonth: "Oct", dateDay: "07", dateWeekday: "Wed", timeText: "02:00 PM – 03:30 PM",
                          locationText: "Computer centre, Lab 3, Block C",
                          repeatText: "Repeats every week on Monday and Wednesday until 16 Oct 2026", company: nil, trainer: "Dr. Lakshmi Sundar",
                          chips: ["2024"], eligibilityNote: "For Aarav's batch (2024)", section: "THIS WEEK"),
            PlacementItem(id: "tr-aptitude", title: "Aptitude Bootcamp",
                          subtitle: "Quantitative aptitude and logical reasoning for campus drives",
                          typeLabel: "Placement training", mode: .virtual, highlight: .upcoming, highlightText: "Starts in 5 days",
                          dateMonth: "Oct", dateDay: "12", dateWeekday: "Mon", timeText: "03:05 PM – 04:30 PM",
                          locationText: "Google Meet",
                          repeatText: "Repeats every week on Monday, Wednesday and Friday until 30 Oct 2026", company: nil, trainer: "Ravi Shankar",
                          chips: ["2024"], eligibilityNote: "For Aarav's batch (2024)", section: "THIS WEEK"),
            PlacementItem(id: "tr-fullstack", title: "Full Stack Web Development Course",
                          subtitle: "HTML, CSS, JavaScript, React and Node.js with a capstone project",
                          typeLabel: "Placement training", mode: .virtual, highlight: .upcoming, highlightText: "Starts in 12 days",
                          dateMonth: "Oct", dateDay: "19", dateWeekday: "Mon", timeText: "04:40 PM – 07:40 PM",
                          locationText: "Google Meet", repeatText: "Repeats every week on Monday until 30 Nov 2026", company: nil, trainer: "Priya",
                          chips: ["2024", "2025"], eligibilityNote: "For Aarav's and Diya's batches", section: "LATER"),
            PlacementItem(id: "tr-mock", title: "Mock Interview Week",
                          subtitle: "One-to-one technical and HR mock interviews with feedback",
                          typeLabel: "Placement training", mode: .onCampus, highlight: .upcoming, highlightText: "Starts in 19 days",
                          dateMonth: "Oct", dateDay: "26", dateWeekday: "Mon", timeText: "10:00 AM – 01:00 PM",
                          locationText: "Placement cell, Block C, 2nd floor",
                          repeatText: "Repeats every day, Monday to Friday until 30 Oct 2026", company: nil, trainer: "Placement cell panel",
                          chips: ["2024"], eligibilityNote: "For Aarav's batch (2024)", section: "LATER"),
        ])
    }

    // MARK: - Detail

    func detail(kind: PlacementKind, id: String, childID: String?) async throws -> PlacementDetail {
        try await Task.sleep(for: latency)
        return kind == .events ? eventDetail(id) : trainingDetail(id)
    }

    private let children = [
        ChildEligibility(id: "aarav", name: "Aarav · B.E. CSE", eligible: true, note: "Course is eligible"),
        ChildEligibility(id: "diya", name: "Diya · B.Tech IT", eligible: true, note: "Course is eligible"),
    ]

    private func eventDetail(_ id: String) -> PlacementDetail {
        switch id {
        case "ev-infosys":
            return PlacementDetail(id: id, kind: .events, title: "Infosys Campus Drive 2026",
                subtitle: "InStep Internship and Systems Engineer roles", typeLabel: "Campus drive", mode: .onCampus,
                highlight: .upcoming, highlightText: nil, dateLine: "Sun, 18 Oct 2026 · in 11 days",
                timeText: "09:00 AM – 05:00 PM", locationText: "Main auditorium, Block A",
                joinable: false, joinLabel: "", trainer: nil, scheduleRows: [], nextSessions: [],
                orgs: [PlacementOrg(id: "o1", initials: "IN", name: "Infosys")], orgsHeading: "Company",
                childrenHeading: "For your children", batchChips: [], children: children)
        case "ev-freshworks":
            return PlacementDetail(id: id, kind: .events, title: "Freshworks Pre-placement Talk",
                subtitle: "Summer Internship 2027 for pre-final year students", typeLabel: "Pre-placement talk", mode: .virtual,
                highlight: .tomorrow, highlightText: "Tomorrow", dateLine: "Thu, 08 Oct 2026 · Tomorrow",
                timeText: "10:00 AM – 11:00 AM", locationText: "Online · video meeting",
                joinable: true, joinLabel: "Join link (opens 10 minutes before)", trainer: nil, scheduleRows: [], nextSessions: [],
                orgs: [PlacementOrg(id: "o1", initials: "FW", name: "Freshworks")], orgsHeading: "Company",
                childrenHeading: "For your children", batchChips: [], children: children)
        case "ev-deloitte":
            return PlacementDetail(id: id, kind: .events, title: "Deloitte Analyst Hiring",
                subtitle: "Audit and tax analyst roles for commerce and MBA graduates", typeLabel: "Placement event", mode: .onCampus,
                highlight: .upcoming, highlightText: nil, dateLine: "Thu, 22 Oct 2026 · in 15 days",
                timeText: "10:30 AM – 04:00 PM", locationText: "Seminar hall, Block B",
                joinable: false, joinLabel: "", trainer: nil, scheduleRows: [], nextSessions: [],
                orgs: [PlacementOrg(id: "o1", initials: "DE", name: "Deloitte")], orgsHeading: "Company",
                childrenHeading: "For your children", batchChips: [], children: [
                    ChildEligibility(id: "aarav", name: "Aarav · B.E. CSE", eligible: false, note: "Course not in the eligible list"),
                    ChildEligibility(id: "diya", name: "Diya · B.Tech IT", eligible: false, note: "Course not in the eligible list"),
                ])
        case "ev-chennai":
            return PlacementDetail(id: id, kind: .events, title: "Chennai IT Job Fair 2026",
                subtitle: "Internships and graduate roles from 12 companies", typeLabel: "Job fair", mode: .offCampus,
                highlight: .upcoming, highlightText: nil, dateLine: "Sat, 31 Oct 2026 · in 24 days",
                timeText: "10:00 AM – 04:00 PM", locationText: "Chennai Trade Centre, Nandambakkam",
                joinable: false, joinLabel: "", trainer: nil, scheduleRows: [], nextSessions: [],
                orgs: [PlacementOrg(id: "o1", initials: "ZO", name: "Zoho"), PlacementOrg(id: "o2", initials: "FW", name: "Freshworks"),
                       PlacementOrg(id: "o3", initials: "IN", name: "Infosys"), PlacementOrg(id: "o4", initials: "TC", name: "TCS"),
                       PlacementOrg(id: "o5", initials: "WI", name: "Wipro"), PlacementOrg(id: "o6", initials: "HC", name: "HCL")],
                orgsHeading: "Participating companies · 6", childrenHeading: "For your children", batchChips: [], children: children)
        default:
            return PlacementDetail(id: id, kind: .events, title: "EduTech Fair", subtitle: "Internship program for graduates",
                typeLabel: "Placement event", mode: .virtual, highlight: .ended, highlightText: "Ended",
                dateLine: "Mon, 07 Sep 2026 · ended", timeText: "10:00 AM", locationText: "Chennai",
                joinable: false, joinLabel: "", trainer: nil, scheduleRows: [], nextSessions: [],
                orgs: [PlacementOrg(id: "o1", initials: "VU", name: "Vuram"), PlacementOrg(id: "o2", initials: "AV", name: "AVM Studios"),
                       PlacementOrg(id: "o3", initials: "DE", name: "Deloitte")],
                orgsHeading: "Participating companies · 3", childrenHeading: "For your children", batchChips: [], children: children)
        }
    }

    private func trainingDetail(_ id: String) -> PlacementDetail {
        switch id {
        case "tr-aptitude":
            return PlacementDetail(id: id, kind: .training, title: "Aptitude Bootcamp",
                subtitle: "Quantitative aptitude and logical reasoning for campus drives", typeLabel: "Placement training", mode: .virtual,
                highlight: .upcoming, highlightText: "Starts in 5 days", dateLine: "", timeText: "", locationText: "",
                joinable: true, joinLabel: "Join on Google Meet (opens 10 minutes before)",
                trainer: PlacementPerson(initials: "RS", name: "Ravi Shankar", role: "Senior Aptitude Trainer, TalentSprint Academy"),
                scheduleRows: [
                    PlacementScheduleRow(id: "s1", label: "Starts", value: "Mon, 12 Oct 2026", highlight: false),
                    PlacementScheduleRow(id: "s2", label: "Time", value: "03:05 PM – 04:30 PM", highlight: false),
                    PlacementScheduleRow(id: "s3", label: "Repeats", value: "Every week on Monday, Wednesday and Friday", highlight: true),
                    PlacementScheduleRow(id: "s4", label: "Until", value: "Fri 30 Oct 2026", highlight: false),
                    PlacementScheduleRow(id: "s5", label: "Platform", value: "Google Meet", highlight: false),
                ],
                nextSessions: ["Mon 12 Oct · 03:05 PM", "Wed 14 Oct · 03:05 PM", "Fri 16 Oct · 03:05 PM"],
                orgs: [], orgsHeading: "", childrenHeading: "Applicable batches", batchChips: ["2024", "2025", "2026", "2027"],
                children: [ChildEligibility(id: "aarav", name: "Aarav · B.E. CSE · batch 2024", eligible: true, note: "Batch 2024 is included")])
        case "tr-fullstack":
            return PlacementDetail(id: id, kind: .training, title: "Full Stack Web Development Course",
                subtitle: "HTML, CSS, JavaScript, React and Node.js with a capstone project", typeLabel: "Placement training", mode: .virtual,
                highlight: .upcoming, highlightText: "Starts in 12 days", dateLine: "", timeText: "", locationText: "",
                joinable: true, joinLabel: "Join on Google Meet (opens 10 minutes before)",
                trainer: PlacementPerson(initials: "P", name: "Priya", role: "Full stack trainer"),
                scheduleRows: [
                    PlacementScheduleRow(id: "s1", label: "Starts", value: "Mon, 19 Oct 2026", highlight: false),
                    PlacementScheduleRow(id: "s2", label: "Time", value: "04:40 PM – 07:40 PM", highlight: false),
                    PlacementScheduleRow(id: "s3", label: "Repeats", value: "Every week on Monday", highlight: true),
                    PlacementScheduleRow(id: "s4", label: "Until", value: "Mon 30 Nov 2026", highlight: false),
                    PlacementScheduleRow(id: "s5", label: "Platform", value: "Google Meet", highlight: false),
                ],
                nextSessions: ["Mon 19 Oct · 04:40 PM", "Mon 26 Oct · 04:40 PM"],
                orgs: [], orgsHeading: "", childrenHeading: "Applicable batches", batchChips: ["2024", "2025", "2026", "2027"],
                children: [ChildEligibility(id: "aarav", name: "Aarav · B.E. CSE · batch 2024", eligible: true, note: "Batch 2024 is included"),
                           ChildEligibility(id: "diya", name: "Diya · B.Tech IT · batch 2025", eligible: true, note: "Batch 2025 is included")])
        case "tr-mock":
            return PlacementDetail(id: id, kind: .training, title: "Mock Interview Week",
                subtitle: "One-to-one technical and HR mock interviews with feedback", typeLabel: "Placement training", mode: .onCampus,
                highlight: .upcoming, highlightText: "Starts in 19 days", dateLine: "", timeText: "", locationText: "",
                joinable: false, joinLabel: "",
                trainer: PlacementPerson(initials: "PC", name: "Placement cell panel", role: "Faculty and alumni from partner companies"),
                scheduleRows: [
                    PlacementScheduleRow(id: "s1", label: "Starts", value: "Mon, 26 Oct 2026", highlight: false),
                    PlacementScheduleRow(id: "s2", label: "Time", value: "10:00 AM – 01:00 PM", highlight: false),
                    PlacementScheduleRow(id: "s3", label: "Repeats", value: "Every day, Monday to Friday", highlight: true),
                    PlacementScheduleRow(id: "s4", label: "Until", value: "Fri 30 Oct 2026", highlight: false),
                    PlacementScheduleRow(id: "s5", label: "Venue", value: "Placement cell, Block C, 2nd floor", highlight: false),
                ],
                nextSessions: ["Mon 26 Oct · 10:00 AM", "Tue 27 Oct · 10:00 AM"],
                orgs: [], orgsHeading: "", childrenHeading: "Applicable batches", batchChips: ["2024", "2025", "2026", "2027"],
                children: [ChildEligibility(id: "aarav", name: "Aarav · B.E. CSE · batch 2024", eligible: true, note: "Batch 2024 is included")])
        default: // tr-dsa
            return PlacementDetail(id: id, kind: .training, title: "Data Structures and Algorithms – Coding Track",
                subtitle: "Problem solving for coding rounds: arrays, trees, graphs and dynamic programming",
                typeLabel: "Placement training", mode: .onCampus, highlight: .today, highlightText: "Session today · 02:00 PM",
                dateLine: "", timeText: "", locationText: "", joinable: false, joinLabel: "",
                trainer: PlacementPerson(initials: "LS", name: "Dr. Lakshmi Sundar", role: "Associate Professor, CSE"),
                scheduleRows: [
                    PlacementScheduleRow(id: "s1", label: "Starts", value: "Mon, 14 Sep 2026", highlight: false),
                    PlacementScheduleRow(id: "s2", label: "Time", value: "02:00 PM – 03:30 PM", highlight: false),
                    PlacementScheduleRow(id: "s3", label: "Repeats", value: "Every week on Monday and Wednesday", highlight: true),
                    PlacementScheduleRow(id: "s4", label: "Until", value: "Fri 16 Oct 2026", highlight: false),
                    PlacementScheduleRow(id: "s5", label: "Venue", value: "Computer centre, Lab 3, Block C", highlight: false),
                ],
                nextSessions: ["Wed 08 Oct · 02:00 PM", "Mon 13 Oct · 02:00 PM", "Wed 15 Oct · 02:00 PM"],
                orgs: [], orgsHeading: "", childrenHeading: "Applicable batches", batchChips: ["2024", "2025", "2026", "2027"],
                children: [ChildEligibility(id: "aarav", name: "Aarav · B.E. CSE · batch 2024", eligible: true, note: "Batch 2024 is included")])
        }
    }
}
