//
//  APIError.swift
//  Gradit
//

import Foundation

nonisolated enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "The request URL is invalid."
        case .invalidResponse: "The server returned an invalid response."
        case .httpStatus(let code): "Request failed with status code \(code)."
        case .decoding(let message): "Couldn't read the server response: \(message)"
        case .transport(let message): message
        }
    }
}
