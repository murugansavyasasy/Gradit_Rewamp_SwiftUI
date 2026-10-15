//
//  ResumeEntryView.swift
//  Gradit
//
//  The Resume Builder tile is a student / parent screen.
//

import SwiftUI

struct ResumeEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        ResumeBuilderView(role: session.currentRole ?? .student)
    }
}
