//
//  CourseRoute.swift
//  Gradit
//
//  Screens pushed within the Course Details module.
//

import SwiftUI

enum CourseRoute: Hashable {
    case subject(childID: String?, code: String, semester: Int)
}

struct CourseRouteView: View {
    let route: CourseRoute

    var body: some View {
        switch route {
        case .subject(let childID, let code, _):
            SubjectDetailView(childID: childID, code: code)
        }
    }
}
