//
//  DiscussionRoute.swift
//  Gradit
//
//  Screens pushed within the Discussion Board, wired into the shared `Route` enum
//  so they use the active tab's NavigationStack.
//

import SwiftUI

enum DiscussionRoute: Hashable {
    case board
    case thread(DiscussionThread)
}

/// Builds the destination for a `DiscussionRoute`; reads services from the environment.
struct DiscussionRouteView: View {
    let route: DiscussionRoute

    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        switch route {
        case .board:
            DiscussionBoardView(service: dependencies.discussionService)
        case .thread(let thread):
            DiscussionThreadView(thread: thread, service: dependencies.discussionService)
        }
    }
}
