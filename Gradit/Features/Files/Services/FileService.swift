//
//  FileService.swift
//  Gradit
//

import Foundation

protocol FileServiceProtocol {
    // Admin / faculty
    func files() async throws -> [SharedFile]
    func fileDetail(id: String) async throws -> FileDetail
    func folders() async throws -> [FileFolder]
    func publish(_ draft: UploadDraft) async throws

    // Reader (student / parent)
    func readerFiles(studentID: String?) async throws -> [SharedFile]
    func readerFileDetail(id: String, studentID: String?) async throws -> FileDetail
}

/// Live implementation. Endpoint paths are placeholders — align them with the backend.
final class FileService: FileServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func files() async throws -> [SharedFile] {
        try await client.send(Endpoint(path: "/files"))
    }

    func fileDetail(id: String) async throws -> FileDetail {
        try await client.send(Endpoint(path: "/files/\(id)"))
    }

    func folders() async throws -> [FileFolder] {
        try await client.send(Endpoint(path: "/files/folders"))
    }

    func publish(_ draft: UploadDraft) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        var endpoint = Endpoint(path: "/files", method: .post)
        endpoint.body = try encoder.encode(draft)
        try await client.sendRaw(endpoint)
    }

    func readerFiles(studentID: String?) async throws -> [SharedFile] {
        var endpoint = Endpoint(path: "/files/reader")
        if let studentID { endpoint.queryItems = [URLQueryItem(name: "student_id", value: studentID)] }
        return try await client.send(endpoint)
    }

    func readerFileDetail(id: String, studentID: String?) async throws -> FileDetail {
        var endpoint = Endpoint(path: "/files/reader/\(id)")
        if let studentID { endpoint.queryItems = [URLQueryItem(name: "student_id", value: studentID)] }
        return try await client.send(endpoint)
    }
}
