//
//  PlacementEntryView.swift
//  Gradit
//
//  The Placement Events / Placement Training tiles are student/parent screens.
//

import SwiftUI

struct PlacementEntryView: View {
    let kind: PlacementKind

    @Environment(AuthSession.self) private var session

    var body: some View {
        PlacementListView(kind: kind, role: session.currentRole ?? .student)
    }
}
