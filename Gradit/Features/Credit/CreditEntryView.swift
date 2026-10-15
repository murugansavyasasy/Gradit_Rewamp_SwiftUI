//
//  CreditEntryView.swift
//  Gradit
//
//  The Sem Credit Points tile is a student/parent screen.
//

import SwiftUI

struct CreditEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        SemCreditView(role: session.currentRole ?? .student)
    }
}
