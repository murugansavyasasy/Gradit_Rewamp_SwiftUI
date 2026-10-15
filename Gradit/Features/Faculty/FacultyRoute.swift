//
//  FacultyRoute.swift
//  Gradit
//
//  Screens pushed within the Faculty module, wired into the shared `Route` enum.
//

import SwiftUI

enum FacultyRoute: Hashable {
    case profile(String)                                   // staff faculty id
    case freePeriods
    case learnerProfile(teacherID: String, childID: String?)
}

struct FacultyRouteView: View {
    let route: FacultyRoute

    var body: some View {
        switch route {
        case .profile(let id):
            FacultyProfileView(facultyID: id)
        case .freePeriods:
            FreePeriodsView()
        case .learnerProfile(let teacherID, let childID):
            LearnerFacultyProfileView(teacherID: teacherID, childID: childID)
        }
    }
}
