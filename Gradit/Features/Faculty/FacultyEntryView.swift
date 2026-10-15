//
//  FacultyEntryView.swift
//  Gradit
//
//  The Faculty menu tile is role-aware: management and faculty get the staff
//  directory; students and parents get "my teachers by semester".
//

import SwiftUI

struct FacultyEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        let role = session.currentRole ?? .student
        switch role {
        case .management, .faculty:
            FacultyDirectoryView()
        case .parent, .student:
            LearnerFacultyView(role: role)
        }
    }
}
