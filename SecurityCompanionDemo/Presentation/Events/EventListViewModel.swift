//
//  EventListViewModel.swift
//  SecurityCompanionDemo
//

import Foundation
import Observation

enum EventListUiState: Equatable {
    case idle
    case loading
    case loaded([SecurityEvent])
    case empty
    case error(String)
}

@MainActor
@Observable
final class EventListViewModel {

    var uiState: EventListUiState = .idle
    private(set) var isFetching: Bool = false
    var refreshErrorMessage: String? = nil

    private let getEventsUseCase: GetEventsUseCase

    init(getEventsUseCase: GetEventsUseCase) {
        self.getEventsUseCase = getEventsUseCase
    }

    var events: [SecurityEvent] {
        if case .loaded(let list) = uiState {
            return list
        }
        return []
    }

    var totalCount: Int {
        events.count
    }

    var criticalCount: Int {
        events.filter { $0.severity == .critical }.count
    }

    var warningCount: Int {
        events.filter { $0.severity == .warning }.count
    }

    var infoCount: Int {
        events.filter { $0.severity == .info }.count
    }

    func loadEvents(isPullToRefresh: Bool = false) async {
        // Prevent concurrent duplicate requests
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }

        // Keep existing events visible during pull-to-refresh; only show full-screen spinner if empty
        if events.isEmpty && !isPullToRefresh {
            uiState = .loading
        }

        refreshErrorMessage = nil

        do {
            let fetchedEvents = try await getEventsUseCase.execute()
            if fetchedEvents.isEmpty {
                uiState = .empty
            } else {
                uiState = .loaded(fetchedEvents)
            }
        } catch let dataError as DataError {
            let message = dataError.localizedDescription
            if events.isEmpty || !isPullToRefresh {
                uiState = .error(message)
            } else {
                refreshErrorMessage = message
            }
        } catch {
            let message = "Unable to load security events. Please try again."
            if events.isEmpty || !isPullToRefresh {
                uiState = .error(message)
            } else {
                refreshErrorMessage = message
            }
        }
    }

    func dismissRefreshError() {
        refreshErrorMessage = nil
    }
}
