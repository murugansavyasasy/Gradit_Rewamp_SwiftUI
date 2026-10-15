//
//  PlacementModels.swift
//  Gradit
//
//  Payloads shared by the Placement Events and Placement Training modules
//  (student/parent, read-only). Design: placementModule.pdf, placementTaining.pdf.
//

import Foundation

// MARK: - Kind & mode

nonisolated enum PlacementKind: String, Codable, Sendable {
    case events, training
    var title: String {
        switch self {
        case .events: String(localized: "Placement Events")
        case .training: String(localized: "Placement Training")
        }
    }
    /// Label for the eligibility filter dropdown.
    var filterLabel: String {
        switch self {
        case .events: String(localized: "Course")
        case .training: String(localized: "Batch")
        }
    }
}

nonisolated enum PlacementMode: String, Codable, Sendable {
    case onCampus, offCampus, virtual
    var title: String {
        switch self {
        case .onCampus: String(localized: "On-campus")
        case .offCampus: String(localized: "Off-campus")
        case .virtual: String(localized: "Virtual")
        }
    }
    var systemImage: String {
        switch self {
        case .onCampus: "bell"
        case .offCampus: "mappin.and.ellipse"
        case .virtual: "video"
        }
    }
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = PlacementMode(rawValue: raw) ?? .onCampus
    }
}

/// Small coloured status pill shown under the type chips.
nonisolated enum PlacementHighlight: String, Codable, Sendable {
    case tomorrow, today, upcoming, ended, none
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = PlacementHighlight(rawValue: raw) ?? .none
    }
}

// MARK: - List

nonisolated struct PlacementItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let typeLabel: String               // "Pre-placement talk" / "Placement training" / "Job fair"
    let mode: PlacementMode
    let highlight: PlacementHighlight
    let highlightText: String?          // "Tomorrow" / "Session today · 02:00 PM" / "Ended"
    let dateMonth: String               // "Oct"
    let dateDay: String                 // "08"
    let dateWeekday: String             // "Thu"
    let timeText: String                // "10:00 AM – 11:00 AM"
    let locationText: String            // "Online · video meeting" / "Computer centre, Lab 3, Block C"
    let repeatText: String?             // training only
    let company: String?                // events: "Freshworks"
    let trainer: String?                // training: "Dr. Lakshmi Sundar"
    let chips: [String]                 // eligible courses / applicable batches
    let eligibilityNote: String         // "Open to Aarav's and Diya's courses" / "For Aarav's batch (2024)"
    let section: String                 // "THIS WEEK" / "LATER" / "ENDED"
}

nonisolated struct PlacementAlert: Codable, Hashable, Sendable {
    let title: String                   // "1 event in the next 2 days"
    let message: String                 // "Freshworks Pre-placement Talk, tomorrow at 10:00 AM"
    let itemID: String?
}

nonisolated struct PlacementBundle: Codable, Sendable {
    let alert: PlacementAlert?
    let items: [PlacementItem]
}

// MARK: - Detail

nonisolated struct PlacementPerson: Codable, Hashable, Sendable {
    let initials: String
    let name: String
    let role: String                    // "Associate Professor, CSE"
}

nonisolated struct PlacementOrg: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let initials: String
    let name: String
}

nonisolated struct ChildEligibility: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String                    // "Aarav · B.E. CSE" / "Aarav · B.E. CSE · batch 2024"
    let eligible: Bool
    let note: String                    // "Course is eligible" / "Batch 2024 is included" / "Course not in the eligible list"
}

nonisolated struct PlacementScheduleRow: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let label: String                   // "Starts" / "Time" / "Repeats" / "Until" / "Venue"
    let value: String
    let highlight: Bool                 // orange for "Repeats"
}

nonisolated struct PlacementDetail: Codable, Sendable {
    let id: String
    let kind: PlacementKind
    let title: String
    let subtitle: String
    let typeLabel: String
    let mode: PlacementMode
    let highlight: PlacementHighlight
    let highlightText: String?
    // summary block (events)
    let dateLine: String                // "Sun, 18 Oct 2026 · in 11 days"
    let timeText: String
    let locationText: String
    // actions
    let joinable: Bool                  // virtual → Join link; else Open in Maps
    let joinLabel: String               // "Join link (opens 10 minutes before)" / "Join on Google Meet …"
    // training
    let trainer: PlacementPerson?
    let scheduleRows: [PlacementScheduleRow]
    let nextSessions: [String]          // "Mon 12 Oct · 03:05 PM"
    // events
    let orgs: [PlacementOrg]
    let orgsHeading: String             // "Company" / "Participating companies · 6"
    // eligibility
    let childrenHeading: String         // "For your children" / "Applicable batches"
    let batchChips: [String]            // training applicable batches
    let children: [ChildEligibility]
}
