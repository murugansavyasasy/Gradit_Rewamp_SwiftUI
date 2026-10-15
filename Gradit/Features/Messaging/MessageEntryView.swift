//
//  MessageEntryView.swift
//  Gradit
//
//  The "Message" menu tile is role-aware: staff compose, parents/students read
//  their inbox (they can't send).
//

import SwiftUI

struct MessageEntryView: View {
    let mode: MessageMode

    @Environment(AuthSession.self) private var session

    var body: some View {
        let role = session.currentRole ?? .student
        switch role {
        case .faculty, .management:
            MessageComposeView(mode: mode)
        case .parent, .student:
            MessagesInboxView(role: role, initialFilter: mode == .voice ? .voice : .text)
        }
    }
}
