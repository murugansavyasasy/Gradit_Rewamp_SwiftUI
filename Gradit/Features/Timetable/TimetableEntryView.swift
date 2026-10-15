//
//  TimetableEntryView.swift
//  Gradit
//
//  The Timetable menu tile is role-aware: management builds/publishes timetables,
//  faculty see "My timetable" (+ swaps), students and parents see the class timetable.
//

import SwiftUI

struct TimetableEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        let role = session.currentRole ?? .student
        switch role {
        case .management:
            AdminTimetableListView()
        case .faculty:
            MyTimetableView()
        case .parent, .student:
            ClassTimetableView(role: role)
        }
    }
}
