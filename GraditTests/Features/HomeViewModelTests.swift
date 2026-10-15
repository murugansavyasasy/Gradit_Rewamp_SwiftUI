//
//  HomeViewModelTests.swift
//  GraditTests
//

import Testing
@testable import Gradit

@MainActor
struct HomeViewModelTests {

    @Test func loadSucceeds() async {
        let viewModel = HomeViewModel(userService: MockUserService())
        await viewModel.load()
        #expect(viewModel.state.value?.count == User.samples.count)
    }

    @Test func loadFails() async {
        let viewModel = HomeViewModel(userService: MockUserService(result: .failure(APIError.invalidResponse)))
        await viewModel.load()
        if case .failed = viewModel.state {} else {
            Issue.record("Expected failed state")
        }
    }

    @Test func searchFiltersByName() async {
        let viewModel = HomeViewModel(userService: MockUserService())
        await viewModel.load()
        viewModel.searchText = "ravi"
        #expect(viewModel.filteredUsers.map(\.name) == ["Ravi Shankar"])
    }
}
