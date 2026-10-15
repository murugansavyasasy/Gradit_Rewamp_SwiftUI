//
//  TimetableRoute.swift
//  Gradit
//
//  Screens pushed within the Timetable module.
//

import SwiftUI

enum TimetableRoute: Hashable {
    case setup
    case editor(String)                 // timetable id ("new" for a fresh one)
    case swapRequests
    case swapFlow(period: String)       // your period label, e.g. "P3 · DBMS"
    case incoming(SwapRequest)
}

struct TimetableRouteView: View {
    let route: TimetableRoute

    var body: some View {
        switch route {
        case .setup:
            TimetableSetupView()
        case .editor(let id):
            TimetableGridView(timetableID: id)
        case .swapRequests:
            SwapRequestsListView()
        case .swapFlow(let period):
            SwapRequestFlowView(yourPeriod: period)
        case .incoming(let request):
            IncomingSwapView(request: request)
        }
    }
}
