//
//  GetEventsUseCase.swift
//  SecurityCompanionDemo
//

import Foundation

nonisolated struct GetEventsUseCase: Sendable {
    private let eventRepository: EventRepository

    init(eventRepository: EventRepository) {
        self.eventRepository = eventRepository
    }

    func execute() async throws -> [SecurityEvent] {
        try await eventRepository.fetchEvents()
    }
}
