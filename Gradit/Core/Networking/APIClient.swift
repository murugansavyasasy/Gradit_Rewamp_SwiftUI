//
//  APIClient.swift
//  Gradit
//

import Foundation
internal import os

/// Thin async/await wrapper around URLSession.
final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    /// Set after login; attached as a Bearer token to every request.
    var authToken: String?

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type = T.self) async throws -> T {
        let data = try await sendRaw(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            AppLogger.network.error("Decoding \(String(describing: T.self)) failed: \(String(describing: error))")
            throw APIError.decoding(error.localizedDescription)
        }
    }

    @discardableResult
    func sendRaw(_ endpoint: Endpoint) async throws -> Data {
        var request = try endpoint.urlRequest(baseURL: baseURL)
        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        AppLogger.network.debug("\(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        return data
    }
}
