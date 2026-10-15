//
//  FileEntryView.swift
//  Gradit
//
//  The Files menu tile is role-aware: management and faculty upload and manage
//  files; students and parents browse and view them online.
//

import SwiftUI

struct FileEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        let role = session.currentRole ?? .student
        switch role {
        case .management, .faculty:
            FileListView(isReader: false, role: role)
        case .parent, .student:
            FileListView(isReader: true, role: role)
        }
    }
}
