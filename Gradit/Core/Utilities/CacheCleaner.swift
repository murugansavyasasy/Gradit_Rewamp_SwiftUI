//
//  CacheCleaner.swift
//  Gradit
//
//  Backs Profile › Clear cache: downloaded files, thumbnails and HTTP cache.
//  Never touches the Keychain, UserDefaults or anything account-related.
//

import Foundation

nonisolated enum CacheCleaner {
    /// Bytes currently used by caches.
    static func currentSize() -> Int64 {
        Int64(URLCache.shared.currentDiskUsage) + directories.reduce(0) { $0 + size(of: $1) }
    }

    /// Clears caches and returns the bytes freed.
    @discardableResult
    static func clear() -> Int64 {
        let before = currentSize()
        URLCache.shared.removeAllCachedResponses()
        let fileManager = FileManager.default
        for directory in directories {
            let items = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
            for item in items {
                try? fileManager.removeItem(at: item)
            }
        }
        return max(0, before - currentSize())
    }

    static func formatted(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private static var directories: [URL] {
        var urls = [FileManager.default.temporaryDirectory]
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            urls.append(caches)
        }
        return urls
    }

    private static func size(of directory: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey]
        ) else { return 0 }

        var total: Int64 = 0
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey])
            if values?.isRegularFile == true {
                total += Int64(values?.totalFileAllocatedSize ?? 0)
            }
        }
        return total
    }
}
