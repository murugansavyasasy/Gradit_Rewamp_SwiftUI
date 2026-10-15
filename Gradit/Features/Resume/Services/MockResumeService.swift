//
//  MockResumeService.swift
//  Gradit
//
//  In-memory resume data used in DEBUG, previews and tests.
//

import Foundation

final class MockResumeService: ResumeServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    func children() async throws -> [FacultyChild] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "aarav", name: "Aarav Sharma", classLabel: "B.E. CSE · Sem 5"),
            .init(id: "diya", name: "Diya Sharma", classLabel: "B.Tech IT · Sem 3"),
        ]
    }

    func resume(childID: String?) async throws -> Resume {
        try await Task.sleep(for: latency)
        let isDiya = childID == "diya"
        return isDiya ? Self.partial : Self.full
    }

    func save(_ resume: Resume, childID: String?) async throws {
        try await Task.sleep(for: latency)
    }

    // A nearly-complete resume (Aarav / default student).
    static let full = Resume(
        personal: ResumePersonal(
            fullName: "Aarav Sharma",
            headline: "Final-year B.E. CSE · Aspiring Software Engineer",
            email: "aarav.sharma@college.edu",
            phone: "+91 98765 43210",
            location: "Chennai, Tamil Nadu"),
        summary: "Final-year Computer Science student with a strong foundation in data structures, "
            + "backend development and cloud. Looking for a software engineering role where I can build "
            + "reliable products and keep learning.",
        education: [
            ResumeEntry(id: "e1", title: "B.E. Computer Science & Engineering",
                        subtitle: "Savyasasy College of Engineering", dateRange: "2022 – 2026",
                        detail: "CGPA 8.7 / 10 · Dean's list 2024"),
            ResumeEntry(id: "e2", title: "Higher Secondary (CBSE)",
                        subtitle: "Vidya Mandir Sr. Sec. School", dateRange: "2020 – 2022",
                        detail: "92.4% · Computer Science stream"),
        ],
        experience: [
            ResumeEntry(id: "x1", title: "Software Engineering Intern",
                        subtitle: "Freshworks · Chennai", dateRange: "Jun 2025 – Aug 2025",
                        detail: "Built REST APIs in Node.js and shipped a ticket-triage dashboard used by 40+ agents."),
        ],
        projects: [
            ResumeEntry(id: "p1", title: "Campus Connect",
                        subtitle: "SwiftUI · Firebase", dateRange: "2025",
                        detail: "A college social app with notices, events and a discussion board. 500+ installs."),
            ResumeEntry(id: "p2", title: "StudyBuddy",
                        subtitle: "Python · FastAPI · PostgreSQL", dateRange: "2024",
                        detail: "An AI-assisted flashcard generator. Won 2nd place at the department hackathon."),
        ],
        certifications: [
            ResumeEntry(id: "c1", title: "AWS Certified Cloud Practitioner",
                        subtitle: "Amazon Web Services", dateRange: "2025", detail: ""),
        ],
        achievements: [
            "2nd place · Smart India Hackathon (college round) 2025",
            "Core member · Coding Club",
        ],
        skills: ["Swift", "Python", "Java", "SwiftUI", "Node.js", "SQL", "Git", "AWS"],
        languages: ["English", "Hindi", "Tamil"],
        links: [
            ResumeLink(id: "l1", label: "GitHub", url: "github.com/aaravsharma"),
            ResumeLink(id: "l2", label: "LinkedIn", url: "linkedin.com/in/aaravsharma"),
        ],
        template: "Classic")

    // A just-started resume (Diya) to show the empty / in-progress states.
    static let partial = Resume(
        personal: ResumePersonal(
            fullName: "Diya Sharma",
            headline: "",
            email: "diya.sharma@college.edu",
            phone: "",
            location: "Chennai, Tamil Nadu"),
        summary: "",
        education: [
            ResumeEntry(id: "e1", title: "B.Tech Information Technology",
                        subtitle: "Savyasasy College of Engineering", dateRange: "2024 – 2028",
                        detail: "CGPA 8.9 / 10"),
        ],
        experience: [], projects: [], certifications: [], achievements: [],
        skills: ["Python", "C++"],
        languages: [], links: [], template: "Modern")
}
