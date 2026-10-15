//
//  Country.swift
//  Gradit
//
//  Countries offered on Common › Onboarding › Country selection, in the design's order.
//

import Foundation

nonisolated struct Country: Identifiable, Hashable, Sendable {
    /// ISO 3166-1 alpha-2, e.g. "IN".
    let code: String
    let name: String
    let dialCode: String
    let currency: String
    let region: String

    var id: String { code }

    /// Short label used on the "popular" chips.
    var shortName: String { code == "AE" ? "UAE" : name }

    /// "+91 · INR ₹"
    var summary: String { "\(dialCode) · \(currency)" }

    static let all: [Country] = [
        Country(code: "AU", name: "Australia", dialCode: "+61", currency: "AUD", region: "Oceania"),
        Country(code: "BH", name: "Bahrain", dialCode: "+973", currency: "BHD", region: "Middle East"),
        Country(code: "BD", name: "Bangladesh", dialCode: "+880", currency: "BDT", region: "South Asia"),
        Country(code: "CA", name: "Canada", dialCode: "+1", currency: "CAD", region: "North America"),
        Country(code: "IN", name: "India", dialCode: "+91", currency: "INR ₹", region: "South Asia"),
        Country(code: "KW", name: "Kuwait", dialCode: "+965", currency: "KWD", region: "Middle East"),
        Country(code: "MY", name: "Malaysia", dialCode: "+60", currency: "MYR", region: "South-East Asia"),
        Country(code: "NP", name: "Nepal", dialCode: "+977", currency: "NPR", region: "South Asia"),
        Country(code: "OM", name: "Oman", dialCode: "+968", currency: "OMR", region: "Middle East"),
        Country(code: "QA", name: "Qatar", dialCode: "+974", currency: "QAR", region: "Middle East"),
        Country(code: "SA", name: "Saudi Arabia", dialCode: "+966", currency: "SAR", region: "Middle East"),
        Country(code: "SG", name: "Singapore", dialCode: "+65", currency: "SGD", region: "South-East Asia"),
        Country(code: "LK", name: "Sri Lanka", dialCode: "+94", currency: "LKR", region: "South Asia"),
        Country(code: "AE", name: "United Arab Emirates", dialCode: "+971", currency: "AED", region: "Middle East"),
        Country(code: "GB", name: "United Kingdom", dialCode: "+44", currency: "GBP £", region: "Europe"),
        Country(code: "US", name: "United States", dialCode: "+1", currency: "USD $", region: "North America"),
    ]

    /// "Popular with our colleges"
    static let popularCodes = ["IN", "AE", "SA", "SG", "LK"]

    static func withCode(_ code: String) -> Country? {
        let code = code.uppercased()
        return all.first { $0.code == code }
    }

    /// Matches country name, ISO code, or phone code (e.g. "+971" or "971").
    static func search(_ query: String) -> [Country] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return all }
        let digits = q.replacingOccurrences(of: " ", with: "")
        return all.filter { country in
            country.name.lowercased().contains(q)
                || country.code.lowercased() == q
                || country.dialCode.contains(digits)
        }
    }

    /// Suggestion from the device's region setting (no location permission needed).
    static func suggested(for locale: Locale = .current) -> Country? {
        guard let region = locale.region?.identifier else { return nil }
        return withCode(region)
    }
}
