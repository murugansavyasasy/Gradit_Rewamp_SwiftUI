//
//  AssignmentEntryView.swift
//  Gradit
//
//  The Assignment menu tile is role-aware: faculty and management manage and grade
//  assignments; students and parents view and submit them.
//

import SwiftUI

struct AssignmentEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        let role = session.currentRole ?? .student
        switch role {
        case .faculty, .management:
            FacultyAssignmentListView()
        case .parent, .student:
            LearnerAssignmentListView(role: role)
        }
    }
}
