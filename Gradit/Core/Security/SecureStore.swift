//
//  SecureStore.swift
//  Gradit
//

import Foundation

/// Small key-value store for secrets. `KeychainStore` in the app, `InMemorySecureStore` in tests/previews.
protocol SecureStore {
    func setData(_ data: Data, for key: String) throws
    func data(for key: String) -> Data?
    func removeValue(for key: String)
}

extension SecureStore {
    func setValue<T: Encodable>(_ value: T, for key: String) throws {
        try setData(JSONEncoder().encode(value), for: key)
    }

    func value<T: Decodable>(_ type: T.Type, for key: String) -> T? {
        guard let data = data(for: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

final class InMemorySecureStore: SecureStore {
    private var storage: [String: Data] = [:]

    func setData(_ data: Data, for key: String) throws { storage[key] = data }
    func data(for key: String) -> Data? { storage[key] }
    func removeValue(for key: String) { storage[key] = nil }
}
