//
//  FeeEntryView.swift
//  Gradit
//
//  The Fee Details tile is a student/parent screen.
//

import SwiftUI

struct FeeEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        FeeDetailsView(role: session.currentRole ?? .student)
    }
}
