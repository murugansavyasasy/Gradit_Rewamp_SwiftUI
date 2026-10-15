//
//  ExamEntryView.swift
//  Gradit
//
//  The Exam Application Details tile is a student/parent screen.
//

import SwiftUI

struct ExamEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        ExamApplicationListView(role: session.currentRole ?? .student)
    }
}
