//
//  CourseEntryView.swift
//  Gradit
//
//  The Course Details tile is a student/parent screen (read-only).
//

import SwiftUI

struct CourseEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        CourseDetailsView(role: session.currentRole ?? .student)
    }
}
