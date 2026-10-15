//
//  PlacementRoute.swift
//  Gradit
//
//  Screens pushed within the Placement modules.
//

import SwiftUI

enum PlacementRoute: Hashable {
    case detail(kind: PlacementKind, id: String, childID: String?)
}

struct PlacementRouteView: View {
    let route: PlacementRoute

    var body: some View {
        switch route {
        case .detail(let kind, let id, let childID):
            PlacementDetailView(kind: kind, id: id, childID: childID)
        }
    }
}

// MARK: - Shared styling

extension PlacementMode {
    var tone: StatusBadge.Tone {
        switch self {
        case .onCampus: .blueSoft
        case .offCampus: .amber
        case .virtual: .green
        }
    }
}

extension PlacementHighlight {
    var tone: StatusBadge.Tone {
        switch self {
        case .tomorrow: .amber
        case .today: .blueSolid
        case .upcoming: .blueSoft
        case .ended, .none: .neutral
        }
    }
}
