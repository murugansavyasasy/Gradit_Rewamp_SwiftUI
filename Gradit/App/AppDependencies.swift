//
//  AppDependencies.swift
//  Gradit
//

import Foundation
import Observation

/// Simple dependency container injected through the SwiftUI environment.
@Observable
final class AppDependencies {
    let apiClient: APIClient
    let userService: UserServiceProtocol
    let authService: AuthServiceProtocol
    let dashboardService: DashboardServiceProtocol
    let profileService: ProfileServiceProtocol
    let discussionService: DiscussionServiceProtocol
    let messagingService: MessagingServiceProtocol
    let attendanceService: AttendanceServiceProtocol
    let assignmentService: AssignmentServiceProtocol
    let facultyService: FacultyServiceProtocol
    let timetableService: TimetableServiceProtocol
    let eventService: EventServiceProtocol
    let noticeService: NoticeServiceProtocol
    let fileService: FileServiceProtocol
    let courseService: CourseServiceProtocol
    let feeService: FeeServiceProtocol
    let creditService: CreditServiceProtocol
    let examService: ExamServiceProtocol
    let placementService: PlacementServiceProtocol
    let resumeService: ResumeServiceProtocol
    let notificationService: NotificationServiceProtocol

    init(
        apiClient: APIClient,
        userService: UserServiceProtocol,
        authService: AuthServiceProtocol,
        dashboardService: DashboardServiceProtocol,
        profileService: ProfileServiceProtocol,
        discussionService: DiscussionServiceProtocol,
        messagingService: MessagingServiceProtocol,
        attendanceService: AttendanceServiceProtocol,
        assignmentService: AssignmentServiceProtocol = MockAssignmentService(latency: .zero),
        facultyService: FacultyServiceProtocol = MockFacultyService(latency: .zero),
        timetableService: TimetableServiceProtocol = MockTimetableService(latency: .zero),
        eventService: EventServiceProtocol = MockEventService(latency: .zero),
        noticeService: NoticeServiceProtocol = MockNoticeService(latency: .zero),
        fileService: FileServiceProtocol = MockFileService(latency: .zero),
        courseService: CourseServiceProtocol = MockCourseService(latency: .zero),
        feeService: FeeServiceProtocol = MockFeeService(latency: .zero),
        creditService: CreditServiceProtocol = MockCreditService(latency: .zero),
        examService: ExamServiceProtocol = MockExamService(latency: .zero),
        placementService: PlacementServiceProtocol = MockPlacementService(latency: .zero),
        resumeService: ResumeServiceProtocol = MockResumeService(latency: .zero),
        notificationService: NotificationServiceProtocol = MockNotificationService(latency: .zero)
    ) {
        self.apiClient = apiClient
        self.userService = userService
        self.authService = authService
        self.dashboardService = dashboardService
        self.profileService = profileService
        self.discussionService = discussionService
        self.messagingService = messagingService
        self.attendanceService = attendanceService
        self.assignmentService = assignmentService
        self.facultyService = facultyService
        self.timetableService = timetableService
        self.eventService = eventService
        self.noticeService = noticeService
        self.fileService = fileService
        self.courseService = courseService
        self.feeService = feeService
        self.creditService = creditService
        self.examService = examService
        self.placementService = placementService
        self.resumeService = resumeService
        self.notificationService = notificationService
    }

    static var live: AppDependencies {
        let client = APIClient(baseURL: AppConfig.baseURL)
        if AppConfig.useMockServices {
            return AppDependencies(
                apiClient: client,
                userService: MockUserService(),
                authService: MockAuthService(),
                dashboardService: MockDashboardService(),
                profileService: MockProfileService(),
                discussionService: MockDiscussionService(),
                messagingService: MockMessagingService(),
                attendanceService: MockAttendanceService(),
                assignmentService: MockAssignmentService(),
                facultyService: MockFacultyService(),
                timetableService: MockTimetableService(),
                eventService: MockEventService(),
                noticeService: MockNoticeService(),
                fileService: MockFileService(),
                courseService: MockCourseService(),
                feeService: MockFeeService(),
                creditService: MockCreditService(),
                examService: MockExamService(),
                placementService: MockPlacementService(),
                resumeService: MockResumeService(),
                notificationService: MockNotificationService()
            )
        }
        return AppDependencies(
            apiClient: client,
            userService: UserService(client: client),
            authService: AuthService(client: client),
            dashboardService: DashboardService(client: client),
            profileService: ProfileService(client: client),
            discussionService: DiscussionService(client: client),
            messagingService: MessagingService(client: client),
            attendanceService: AttendanceService(client: client),
            assignmentService: AssignmentService(client: client),
            facultyService: FacultyService(client: client),
            timetableService: TimetableService(client: client),
            eventService: EventService(client: client),
            noticeService: NoticeService(client: client),
            fileService: FileService(client: client),
            courseService: CourseService(client: client),
            feeService: FeeService(client: client),
            creditService: CreditService(client: client),
            examService: ExamService(client: client),
            placementService: PlacementService(client: client),
            resumeService: ResumeService(client: client),
            notificationService: NotificationService(client: client)
        )
    }

    static var preview: AppDependencies {
        AppDependencies(
            apiClient: APIClient(baseURL: AppConfig.baseURL),
            userService: MockUserService(),
            authService: MockAuthService(latency: .milliseconds(400)),
            dashboardService: MockDashboardService(latency: .milliseconds(300)),
            profileService: MockProfileService(latency: .milliseconds(300)),
            discussionService: MockDiscussionService(latency: .milliseconds(300)),
            messagingService: MockMessagingService(latency: .milliseconds(300)),
            attendanceService: MockAttendanceService(latency: .milliseconds(300)),
            assignmentService: MockAssignmentService(latency: .milliseconds(300)),
            facultyService: MockFacultyService(latency: .milliseconds(300)),
            timetableService: MockTimetableService(latency: .milliseconds(300)),
            eventService: MockEventService(latency: .milliseconds(300)),
            noticeService: MockNoticeService(latency: .milliseconds(300)),
            fileService: MockFileService(latency: .milliseconds(300)),
            courseService: MockCourseService(latency: .milliseconds(300)),
            feeService: MockFeeService(latency: .milliseconds(300)),
            creditService: MockCreditService(latency: .milliseconds(300)),
            examService: MockExamService(latency: .milliseconds(300)),
            placementService: MockPlacementService(latency: .milliseconds(300)),
            resumeService: MockResumeService(latency: .milliseconds(300)),
            notificationService: MockNotificationService(latency: .milliseconds(300))
        )
    }

    /// Zero-latency mocks for previews that need loaded content in the snapshot.
    static var previewZero: AppDependencies {
        AppDependencies(
            apiClient: APIClient(baseURL: AppConfig.baseURL),
            userService: MockUserService(),
            authService: MockAuthService(latency: .zero),
            dashboardService: MockDashboardService(latency: .zero),
            profileService: MockProfileService(latency: .zero),
            discussionService: MockDiscussionService(latency: .zero),
            messagingService: MockMessagingService(latency: .zero),
            attendanceService: MockAttendanceService(latency: .zero),
            assignmentService: MockAssignmentService(latency: .zero),
            facultyService: MockFacultyService(latency: .zero),
            timetableService: MockTimetableService(latency: .zero),
            eventService: MockEventService(latency: .zero),
            noticeService: MockNoticeService(latency: .zero),
            fileService: MockFileService(latency: .zero),
            courseService: MockCourseService(latency: .zero),
            feeService: MockFeeService(latency: .zero),
            creditService: MockCreditService(latency: .zero),
            examService: MockExamService(latency: .zero),
            placementService: MockPlacementService(latency: .zero),
            resumeService: MockResumeService(latency: .zero),
            notificationService: MockNotificationService(latency: .zero)
        )
    }
}
