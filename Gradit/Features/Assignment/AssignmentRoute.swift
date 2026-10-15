//
//  AssignmentRoute.swift
//  Gradit
//
//  Screens pushed within the Assignment module, wired into the shared `Route`
//  enum so they use the active tab's NavigationStack.
//

import SwiftUI

enum AssignmentRoute: Hashable {
    case facultyDetail(FacultyAssignment)
    case create
    case grade(assignmentID: String, assignmentTitle: String, submission: AssignmentSubmission)
    case learnerDetail(LearnerAssignment)
    case submit(LearnerAssignmentDetail)
}

/// Builds the destination for an `AssignmentRoute`; reads the role from the session.
struct AssignmentRouteView: View {
    let route: AssignmentRoute

    @Environment(AuthSession.self) private var session

    var body: some View {
        switch route {
        case .facultyDetail(let assignment):
            FacultyAssignmentDetailView(assignment: assignment)
        case .create:
            CreateAssignmentView()
        case .grade(let assignmentID, let title, let submission):
            GradeSubmissionView(assignmentID: assignmentID, assignmentTitle: title, submission: submission)
        case .learnerDetail(let assignment):
            LearnerAssignmentDetailView(assignmentID: assignment.id, role: session.currentRole ?? .student)
        case .submit(let detail):
            SubmitAssignmentView(detail: detail)
        }
    }
}
