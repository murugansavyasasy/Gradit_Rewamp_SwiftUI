//
//  ProfileService.swift
//  Gradit
//

import Foundation

protocol ProfileServiceProtocol {
    func profile(role: UserRole) async throws -> UserProfile
    func updateProfile(fullName: String, email: String?, dateOfBirth: String?) async throws -> UserProfile
    func uploadPhoto(jpegData: Data) async throws -> UserProfile
    func removePhoto() async throws -> UserProfile
    func changePassword(current: String, new: String, signOutOtherDevices: Bool) async throws
    func notificationPreferences() async throws -> NotificationPreferences
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class ProfileService: ProfileServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func profile(role: UserRole) async throws -> UserProfile {
        try await client.send(Endpoint(path: "/me/profile", queryItems: [URLQueryItem(name: "role", value: role.rawValue)]))
    }

    func updateProfile(fullName: String, email: String?, dateOfBirth: String?) async throws -> UserProfile {
        var body = ["fullName": fullName]
        if let email { body["email"] = email }
        if let dateOfBirth { body["dateOfBirth"] = dateOfBirth }
        return try await client.send(.json("/me/profile", method: .patch, body: body))
    }

    func uploadPhoto(jpegData: Data) async throws -> UserProfile {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".utf8))
        body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
        body.append(jpegData)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))

        var endpoint = Endpoint(path: "/me/profile/photo", method: .post, body: body)
        endpoint.headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        return try await client.send(endpoint)
    }

    func removePhoto() async throws -> UserProfile {
        try await client.send(Endpoint(path: "/me/profile/photo", method: .delete))
    }

    func changePassword(current: String, new: String, signOutOtherDevices: Bool) async throws {
        do {
            try await client.sendRaw(.json("/me/password", body: [
                "currentPassword": current,
                "newPassword": new,
                "signOutOtherDevices": signOutOtherDevices ? "true" : "false",
            ]))
        } catch APIError.httpStatus(let status) where status == 401 || status == 403 {
            throw ProfileError.wrongCurrentPassword
        }
    }

    func notificationPreferences() async throws -> NotificationPreferences {
        try await client.send(Endpoint(path: "/me/notification-preferences"))
    }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(preferences)
        return try await client.send(Endpoint(path: "/me/notification-preferences", method: .put, body: body))
    }
}

/// In-memory backend for DEBUG builds (`AppConfig.useMockServices`), previews and tests.
/// Sample values come from the design canvas.
final class MockProfileService: ProfileServiceProtocol {
    var latency: Duration
    private var stored: UserProfile
    private var preferences = NotificationPreferences.defaults

    init(latency: Duration = .milliseconds(400)) {
        self.latency = latency
        self.stored = UserProfile(
            fullName: MockAuthService.demoUser.name,
            mobile: "+91 98765 43210",
            email: "rajesh.sharma@gmail.com",
            dateOfBirth: "1978-08-12",
            summary: nil,
            photoURL: nil
        )
    }

    func profile(role: UserRole) async throws -> UserProfile {
        try await Task.sleep(for: latency)
        var profile = stored
        switch role {
        case .parent: profile.summary = "Parent of Aarav Sharma · B.E. CSE"
        case .student: profile.summary = "B.E. CSE · Sem 5 · Roll no. 21CS045"
        case .faculty: profile.summary = "Dept. of CSE · Staff ID UCEC-0148"
        case .management: profile.summary = "Administration · Staff ID UCEC-0012"
        }
        return profile
    }

    func updateProfile(fullName: String, email: String?, dateOfBirth: String?) async throws -> UserProfile {
        try await Task.sleep(for: latency)
        stored.fullName = fullName
        stored.email = email
        stored.dateOfBirth = dateOfBirth
        return stored
    }

    func uploadPhoto(jpegData: Data) async throws -> UserProfile {
        try await Task.sleep(for: latency)
        let url = FileManager.default.temporaryDirectory.appending(path: "mock-profile-photo.jpg")
        try jpegData.write(to: url)
        stored.photoURL = url
        return stored
    }

    func removePhoto() async throws -> UserProfile {
        try await Task.sleep(for: latency)
        stored.photoURL = nil
        return stored
    }

    func changePassword(current: String, new: String, signOutOtherDevices: Bool) async throws {
        try await Task.sleep(for: latency)
        guard current.count >= 6 else { throw ProfileError.wrongCurrentPassword }
    }

    func notificationPreferences() async throws -> NotificationPreferences {
        try await Task.sleep(for: latency)
        return preferences
    }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences {
        try await Task.sleep(for: latency)
        self.preferences = preferences
        return preferences
    }
}
