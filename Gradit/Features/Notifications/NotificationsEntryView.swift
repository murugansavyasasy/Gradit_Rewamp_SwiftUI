//
//  NotificationsEntryView.swift
//  Gradit
//
//  Notifications are available to every role; content is role-aware.
//

import SwiftUI

struct NotificationsEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        NotificationsView(role: session.currentRole ?? .student)
    }
}
