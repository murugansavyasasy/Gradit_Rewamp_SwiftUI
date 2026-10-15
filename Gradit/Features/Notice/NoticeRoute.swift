//
//  NoticeRoute.swift
//  Gradit
//
//  Screens pushed within the Notice Board module.
//

import SwiftUI

enum NoticeRoute: Hashable {
    case create
    case detail(String)         // admin notice id
    case readerDetail(String)   // reader notice id
}

struct NoticeRouteView: View {
    let route: NoticeRoute

    @Environment(AuthSession.self) private var session

    var body: some View {
        switch route {
        case .create:
            CreateNoticeView()
        case .detail(let id):
            NoticeDetailView(noticeID: id, isReader: false, role: session.currentRole ?? .management)
        case .readerDetail(let id):
            NoticeDetailView(noticeID: id, isReader: true, role: session.currentRole ?? .student)
        }
    }
}
