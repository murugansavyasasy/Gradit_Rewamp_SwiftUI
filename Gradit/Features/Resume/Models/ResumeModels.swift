//
//  ResumeModels.swift
//  Gradit
//
//  Payloads for the student Resume Builder (editable).
//

import Foundation

// MARK: - Pieces

nonisolated struct ResumePersonal: Codable, Hashable, Sendable {
    var fullName: String
    var headline: String               // "Final-year B.E. CSE · Aspiring Software Engineer"
    var email: String
    var phone: String
    var location: String
}

/// A repeating entry used by Education / Experience / Projects / Certifications.
nonisolated struct ResumeEntry: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var title: String                  // degree / role / project name / certificate
    var subtitle: String               // institution / company / tech stack / issuer
    var dateRange: String              // "2022 – 2026" / "Jun 2025 – Aug 2025"
    var detail: String                 // description / CGPA / bullet points

    static func blank() -> ResumeEntry {
        ResumeEntry(id: UUID().uuidString, title: "", subtitle: "", dateRange: "", detail: "")
    }
}

nonisolated struct ResumeLink: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var label: String                  // "GitHub" / "LinkedIn" / "Portfolio"
    var url: String

    static func blank() -> ResumeLink { ResumeLink(id: UUID().uuidString, label: "", url: "") }
}

// MARK: - Resume

nonisolated struct Resume: Codable, Sendable {
    var personal: ResumePersonal
    var summary: String
    var education: [ResumeEntry]
    var experience: [ResumeEntry]
    var projects: [ResumeEntry]
    var certifications: [ResumeEntry]
    var achievements: [String]
    var skills: [String]
    var languages: [String]
    var links: [ResumeLink]
    var template: String               // "Classic" / "Modern" / "Minimal"

    static func empty() -> Resume {
        Resume(personal: ResumePersonal(fullName: "", headline: "", email: "", phone: "", location: ""),
               summary: "", education: [], experience: [], projects: [], certifications: [],
               achievements: [], skills: [], languages: [], links: [], template: "Classic")
    }
}

// MARK: - Templates

/// The visual styles a student can pick for the exported resume.
nonisolated enum ResumeTemplate: String, CaseIterable, Identifiable, Sendable {
    case classic = "Classic"
    case modern = "Modern"
    case minimal = "Minimal"

    var id: String { rawValue }
    var title: String { rawValue }

    var tagline: String {
        switch self {
        case .classic: String(localized: "Timeless, single-column layout")
        case .modern: String(localized: "Accent header with bold sections")
        case .minimal: String(localized: "Clean, lots of whitespace")
        }
    }

    var highlights: [String] {
        switch self {
        case .classic: ["Centered header", "Section dividers"]
        case .modern: ["Color accent", "Two-tone headings"]
        case .minimal: ["Thin rules", "Compact spacing"]
        }
    }

    /// Accent used for headings, dividers and chips in this template.
    var accentHex: UInt32 {
        switch self {
        case .classic: 0x1D4ED8   // blue
        case .modern: 0x0D9488    // teal
        case .minimal: 0x111827   // near-black
        }
    }

    var softHex: UInt32 {
        switch self {
        case .classic: 0xEFF3FD
        case .modern: 0xE6F4F2
        case .minimal: 0xEEF0F3
        }
    }

    static func from(_ raw: String) -> ResumeTemplate { ResumeTemplate(rawValue: raw) ?? .classic }
}

// MARK: - Sections

nonisolated enum ResumeSection: String, CaseIterable, Identifiable, Sendable {
    case personal, summary, skills, education, experience, projects, certifications, achievements, languages, links
    var id: String { rawValue }

    var title: String {
        switch self {
        case .personal: String(localized: "Personal details")
        case .summary: String(localized: "Professional summary")
        case .skills: String(localized: "Skills")
        case .education: String(localized: "Education")
        case .experience: String(localized: "Experience & internships")
        case .projects: String(localized: "Projects")
        case .certifications: String(localized: "Certifications")
        case .achievements: String(localized: "Achievements")
        case .languages: String(localized: "Languages")
        case .links: String(localized: "Links")
        }
    }

    var systemImage: String {
        switch self {
        case .personal: "person.text.rectangle"
        case .summary: "text.alignleft"
        case .skills: "wrench.and.screwdriver"
        case .education: "graduationcap"
        case .experience: "briefcase"
        case .projects: "hammer"
        case .certifications: "rosette"
        case .achievements: "trophy"
        case .languages: "globe"
        case .links: "link"
        }
    }

    var required: Bool {
        switch self {
        case .personal, .summary, .skills, .education: true
        default: false
        }
    }
}

extension Resume {
    func isDone(_ section: ResumeSection) -> Bool {
        switch section {
        case .personal: !personal.fullName.trimmingCharacters(in: .whitespaces).isEmpty
        case .summary: !summary.trimmingCharacters(in: .whitespaces).isEmpty
        case .skills: !skills.isEmpty
        case .education: !education.isEmpty
        case .experience: !experience.isEmpty
        case .projects: !projects.isEmpty
        case .certifications: !certifications.isEmpty
        case .achievements: !achievements.isEmpty
        case .languages: !languages.isEmpty
        case .links: !links.isEmpty
        }
    }

    /// Short status line shown on a section card.
    func status(_ section: ResumeSection) -> String {
        switch section {
        case .personal: personal.fullName.isEmpty ? String(localized: "Not added yet") : personal.fullName
        case .summary: summary.isEmpty ? String(localized: "Not added yet") : String(localized: "Added")
        case .skills: skills.isEmpty ? String(localized: "Not added yet") : String(localized: "\(skills.count) skills")
        case .education: countStatus(education.count, "entry", "entries")
        case .experience: countStatus(experience.count, "entry", "entries")
        case .projects: countStatus(projects.count, "project", "projects")
        case .certifications: countStatus(certifications.count, "certificate", "certificates")
        case .achievements: countStatus(achievements.count, "item", "items")
        case .languages: languages.isEmpty ? String(localized: "Not added yet") : String(localized: "\(languages.count) languages")
        case .links: countStatus(links.count, "link", "links")
        }
    }

    private func countStatus(_ n: Int, _ one: String, _ many: String) -> String {
        n == 0 ? String(localized: "Not added yet") : (n == 1 ? "1 \(one)" : "\(n) \(many)")
    }

    var completedCount: Int { ResumeSection.allCases.filter { isDone($0) }.count }
    var percent: Int { Int((Double(completedCount) / Double(ResumeSection.allCases.count) * 100).rounded()) }
}
