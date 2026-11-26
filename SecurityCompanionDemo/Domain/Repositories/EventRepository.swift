//
//  EventRepository.swift
//  SecurityCompanionDemo
//

import Foundation

nonisolated protocol EventRepository: Sendable {
    func fetchEvents() async throws -> [SecurityEvent]
}
