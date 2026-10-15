//
//  AppRouter.swift
//  Gradit
//

import SwiftUI
import Observation

/// Every pushable screen in the signed-in app.
enum Route: Hashable {
    case userDetail(User)
    case feature(DashboardFeature)
    case profile(ProfileRoute)
    case discussion(DiscussionRoute)
    case message(Message)
    case markAttendance(FacultyClassSession)
    case assignment(AssignmentRoute)
    case faculty(FacultyRoute)
    case timetable(TimetableRoute)
    case event(EventRoute)
    case notice(NoticeRoute)
    case file(FileRoute)
    case course(CourseRoute)
    case exam(ExamRoute)
    case placement(PlacementRoute)

    @ViewBuilder
    var destination: some View {
        switch self {
        case .userDetail(let user):
            Text(user.name)
                .navigationTitle(user.name)
        case .feature(.discussionBoard):
            DiscussionRouteView(route: .board)
        case .feature(.textMessage):
            MessageEntryView(mode: .text)
        case .feature(.voiceMessage):
            MessageEntryView(mode: .voice)
        case .feature(.attendance):
            AttendanceEntryView()
        case .feature(.attendanceReport):
            AttendanceReportView(role: .management)
        case .feature(.markYourAttendance):
            MarkYourAttendanceView()
        case .feature(.assignment):
            AssignmentEntryView()
        case .feature(.faculty):
            FacultyEntryView()
        case .feature(.freePeriods):
            FacultyRouteView(route: .freePeriods)
        case .feature(.timetable):
            TimetableEntryView()
        case .feature(.noticeBoard):
            NoticeEntryView()
        case .feature(.files):
            FileEntryView()
        case .feature(.courseDetails):
            CourseEntryView()
        case .feature(.feeDetails):
            FeeEntryView()
        case .feature(.resumeBuilder):
            ResumeEntryView()
        case .feature(.notifications):
            NotificationsEntryView()
        case .feature(.semCreditPoints), .feature(.categoryCreditPoints):
            CreditEntryView()
        case .feature(.examApplication):
            ExamEntryView()
        case .feature(.placementEvents):
            PlacementEntryView(kind: .events)
        case .feature(.placementTraining):
            PlacementEntryView(kind: .training)
        case .feature(.events):
            EventsEntryView()
        case .feature(.eventMedia):
            EventRouteView(route: .pendingMedia)
        case .feature(let feature):
            FeaturePlaceholderView(feature: feature)
        case .profile(let route):
            ProfileRouteView(route: route)
        case .discussion(let route):
            DiscussionRouteView(route: route)
        case .message(let message):
            MessageDetailView(message: message)
        case .markAttendance(let session):
            MarkAttendanceView(session: session)
        case .assignment(let route):
            AssignmentRouteView(route: route)
        case .faculty(let route):
            FacultyRouteView(route: route)
        case .timetable(let route):
            TimetableRouteView(route: route)
        case .event(let route):
            EventRouteView(route: route)
        case .notice(let route):
            NoticeRouteView(route: route)
        case .file(let route):
            FileRouteView(route: route)
        case .course(let route):
            CourseRouteView(route: route)
        case .exam(let route):
            ExamRouteView(route: route)
        case .placement(let route):
            PlacementRouteView(route: route)
        }
    }
}

/// Selected bottom tab and one navigation path per tab.
@Observable
final class AppRouter {
    var selectedTab: DashboardTab = .home
    private var paths: [DashboardTab: NavigationPath] = [:]

    func path(for tab: DashboardTab) -> Binding<NavigationPath> {
        Binding(
            get: { self.paths[tab] ?? NavigationPath() },
            set: { self.paths[tab] = $0 }
        )
    }

    func isAtRoot(_ tab: DashboardTab) -> Bool {
        paths[tab]?.isEmpty ?? true
    }

    /// Pushes onto the selected tab's stack.
    func push(_ route: Route) {
        paths[selectedTab, default: NavigationPath()].append(route)
    }

    /// Tapping the selected tab again pops it to its root.
    func select(_ tab: DashboardTab) {
        if tab == selectedTab {
            paths[tab] = NavigationPath()
        } else {
            selectedTab = tab
        }
    }

    /// Pops `count` screens off the selected tab's stack.
    func pop(_ count: Int = 1) {
        var path = paths[selectedTab] ?? NavigationPath()
        path.removeLast(min(count, path.count))
        paths[selectedTab] = path
    }

    func popToRoot() {
        paths[selectedTab] = NavigationPath()
    }

    func reset() {
        selectedTab = .home
        paths = [:]
    }
}
