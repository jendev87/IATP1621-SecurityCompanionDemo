//
//  PersistentEventRepository.swift
//  SecurityCompanionDemo
//

import Foundation
import SwiftData

actor PersistentEventRepository: ModelActor, EventRepository {

    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor
    private let remoteRepository: EventRepository

    init(modelContainer: ModelContainer, remoteRepository: EventRepository) {
        let modelContext = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
        self.remoteRepository = remoteRepository
    }

    func fetchEvents() async throws -> [SecurityEvent] {
        do {
            // 1. Attempt remote fetch
            let remoteEvents = try await remoteRepository.fetchEvents()

            // 2. Persist / upsert returned events
            try upsertEvents(remoteEvents)

            // 3. Return remote events (sorted newest first)
            return remoteEvents.sorted { $0.timestamp > $1.timestamp }

        } catch let remoteError {
            // 4. On failure, attempt to retrieve cached events
            let cached = try fetchCachedEvents()

            // 5. If cached events exist, return them
            if !cached.isEmpty {
                return cached
            }

            // 6. If no cached events, propagate the remote error
            throw remoteError
        }
    }

    func upsertEvents(_ events: [SecurityEvent]) throws {
        for event in events {
            let targetID = event.id
            let descriptor = FetchDescriptor<SecurityEventModel>(
                predicate: #Predicate<SecurityEventModel> { $0.id == targetID }
            )
            if let existing = try modelContext.fetch(descriptor).first {
                existing.title = event.title
                existing.eventDescription = event.description
                existing.timestamp = event.timestamp
                existing.severityRawValue = event.severity.rawValue
                existing.typeRawValue = event.type.rawValue
                existing.zoneName = event.zoneName
            } else {
                let model = SecurityEventModel(from: event)
                modelContext.insert(model)
            }
        }
        try modelContext.save()
    }

    func fetchCachedEvents() throws -> [SecurityEvent] {
        let descriptor = FetchDescriptor<SecurityEventModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    func fetchCachedEventCount() throws -> Int {
        let descriptor = FetchDescriptor<SecurityEventModel>()
        return try modelContext.fetchCount(descriptor)
    }

    func deleteAllCachedEvents() throws {
        let descriptor = FetchDescriptor<SecurityEventModel>()
        let all = try modelContext.fetch(descriptor)
        for event in all {
            modelContext.delete(event)
        }
        try modelContext.save()
    }
}
