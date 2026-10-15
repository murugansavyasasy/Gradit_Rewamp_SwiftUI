//
//  String+Extensions.swift
//  Gradit
//

import Foundation

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var isBlank: Bool { trimmed.isEmpty }

    var isValidEmail: Bool {
        (try? #/^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/#.wholeMatch(in: self)) != nil
    }
}
