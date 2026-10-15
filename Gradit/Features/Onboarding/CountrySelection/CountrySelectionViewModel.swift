//
//  CountrySelectionViewModel.swift
//  Gradit
//

import Foundation
import Observation

struct CountryGroup: Identifiable, Hashable {
    let letter: String
    let countries: [Country]
    var id: String { letter }
}

@Observable
final class CountrySelectionViewModel {
    var query = ""
    var selection: Country?
    /// From the device region; shown as the highlighted card at the top.
    let suggested: Country?

    init(selected: Country?, suggested: Country? = Country.suggested()) {
        self.suggested = suggested
        self.selection = selected ?? suggested
    }

    var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    var results: [Country] { Country.search(query) }

    var groups: [CountryGroup] {
        let results = results
        var letters: [String] = []
        for country in results {
            let letter = String(country.name.prefix(1))
            if !letters.contains(letter) { letters.append(letter) }
        }
        return letters.map { letter in
            CountryGroup(letter: letter, countries: results.filter { $0.name.hasPrefix(letter) })
        }
    }

    var popular: [Country] {
        Country.popularCodes
            .compactMap(Country.withCode)
            .filter { $0 != suggested }
    }

    var listTitle: String {
        isSearching ? String(localized: "RESULTS") : String(localized: "ALL COUNTRIES A–Z")
    }

    var countText: String {
        let count = results.count
        if isSearching {
            return count == 1 ? String(localized: "1 match") : String(localized: "\(count) matches")
        }
        return String(localized: "\(count) countries")
    }

    /// Continue is enabled only once a country is chosen.
    var canContinue: Bool { selection != nil }

    func select(_ country: Country) {
        selection = country
    }

    func clearSearch() {
        query = ""
    }
}
