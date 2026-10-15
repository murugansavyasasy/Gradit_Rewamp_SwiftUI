//
//  NoticeEntryView.swift
//  Gradit
//
//  The Notice Board menu tile is role-aware: management and faculty create and
//  manage notices; students and parents read them.
//

import SwiftUI

struct NoticeEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        let role = session.currentRole ?? .student
        switch role {
        case .management, .faculty:
            NoticeListView()
        case .parent, .student:
            ReaderNoticeListView(role: role)
        }
    }
}
