//
//  ExamRoute.swift
//  Gradit
//
//  Screens pushed within the Exam Application module.
//

import SwiftUI

enum ExamRoute: Hashable {
    case detail(id: String, childID: String?)
}

struct ExamRouteView: View {
    let route: ExamRoute

    var body: some View {
        switch route {
        case .detail(let id, let childID):
            ExamApplicationDetailView(examID: id, childID: childID)
        }
    }
}
