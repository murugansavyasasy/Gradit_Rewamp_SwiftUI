//
//  FileRoute.swift
//  Gradit
//
//  Screens pushed within the Files module.
//

import SwiftUI

enum FileRoute: Hashable {
    case folders
    case upload
    case detail(String)         // admin file id
    case viewer(String)         // reader file id
}

struct FileRouteView: View {
    let route: FileRoute

    @Environment(AuthSession.self) private var session

    var body: some View {
        switch route {
        case .folders:
            FoldersView()
        case .upload:
            UploadFilesView()
        case .detail(let id):
            FileDetailView(fileID: id, isReader: false, role: session.currentRole ?? .management)
        case .viewer(let id):
            FileViewerView(fileID: id, role: session.currentRole ?? .student)
        }
    }
}
