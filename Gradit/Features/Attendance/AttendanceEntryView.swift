//
//  AttendanceEntryView.swift
//  Gradit
//
//  The Attendance menu tile is role-aware: staff open the attendance report.
//  (Parent/student personal attendance is a separate screen, not built yet.)
//

import SwiftUI

struct AttendanceEntryView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        let role = session.currentRole ?? .student
        switch role {
        case .management:
            StaffAttendanceView(role: role)
        case .faculty:
            FacultyAttendanceView()
        case .parent, .student:
            LearnerAttendanceView(role: role)
        }
    }
}
