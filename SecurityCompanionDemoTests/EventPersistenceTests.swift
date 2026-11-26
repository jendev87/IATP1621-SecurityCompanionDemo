//
//  EventPersistenceTests.swift
//  SecurityCompanionDemoTests
//

import XCTest
import SwiftData
@testable import SecurityCompanionDemo

final class EventPersistenceTests: XCTestCase {

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            ZoneModel.self,
            SensorModel.self,
            SecurityEventModel.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - 1. Insert and Retrieve Events

    func testInsertAndRetrieveEvents() async throws {
        let container = try makeInMemoryContainer()

        let sampleEvents = [
            SecurityEvent(
                id: "1",
                title: "Door Opened",
                description: "Front door contact opened",
                timestamp: Date(),
                severity: .info,
                type: .doorOpened,
                zoneName: "Front Entry"
            ),
            SecurityEvent(
                id: "2",
                title: "Motion Detected",
                description: "Motion detected in hallway",
                timestamp: Date().addingTimeInterval(-600),
                severity: .warning,
                type: .motionDetected,
                zoneName: "Hallway"
            )
        ]

        let mockRemote = MockEventRepository(events: sampleEvents)
        let repository = PersistentEventRepository(modelContainer: container, remoteRepository: mockRemote)

        let retrieved = try await repository.fetchEvents()

        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved.map { $0.id }, ["1", "2"])

        // Verify local cache has both
        let cached = try await repository.fetchCachedEvents()
        XCTAssertEqual(cached.count, 2)
    }

    // MARK: - 2. Upsert Events Without Duplicates

    func testUpsertEvents_doesNotCreateDuplicates() async throws {
        let container = try makeInMemoryContainer()

        let initialEvents = [
            SecurityEvent(
                id: "101",
                title: "Initial Title",
                description: "Initial description",
                timestamp: Date(),
                severity: .info,
                type: .systemArmed
            )
        ]

        let mockRemote = MockEventRepository(events: initialEvents)
        let repository = PersistentEventRepository(modelContainer: container, remoteRepository: mockRemote)

        // First fetch
        _ = try await repository.fetchEvents()
        let count1 = try await repository.fetchCachedEventCount()
        XCTAssertEqual(count1, 1)

        // Second fetch with updated title for the same event ID
        let updatedEvents = [
            SecurityEvent(
                id: "101",
                title: "Updated Title After Refresh",
                description: "Updated description",
                timestamp: Date(),
                severity: .warning,
                type: .systemArmed
            )
        ]
        await mockRemote.setEvents(updatedEvents)

        let refreshed = try await repository.fetchEvents()
        let count2 = try await repository.fetchCachedEventCount()

        XCTAssertEqual(count2, 1, "Duplicate records must not be created for the same ID")
        XCTAssertEqual(refreshed.first?.title, "Updated Title After Refresh")
        XCTAssertEqual(refreshed.first?.severity, .warning)
    }

    // MARK: - 3. Return Cached Events When Remote Fails

    func testReturnCachedEventsWhenRemoteFails() async throws {
        let container = try makeInMemoryContainer()

        let cachedEvents = [
            SecurityEvent(
                id: "201",
                title: "Cached Warning",
                description: "Offline sensor alert",
                timestamp: Date(),
                severity: .critical,
                type: .sensorOffline,
                zoneName: "Garage"
            )
        ]

        let mockRemote = MockEventRepository(events: cachedEvents)
        let repository = PersistentEventRepository(modelContainer: container, remoteRepository: mockRemote)

        // 1. Initial successful fetch caches the data
        let initial = try await repository.fetchEvents()
        XCTAssertEqual(initial.count, 1)

        // 2. Subsequent remote call fails with network unavailable
        await mockRemote.setShouldThrow(true, error: DataError.networkUnavailable)

        // 3. Repository should gracefully fallback to cached events
        let fallbackEvents = try await repository.fetchEvents()
        XCTAssertEqual(fallbackEvents.count, 1)
        XCTAssertEqual(fallbackEvents.first?.id, "201")
        XCTAssertEqual(fallbackEvents.first?.title, "Cached Warning")
    }

    // MARK: - 4. Propagate Error When Neither Remote Nor Cached Data Is Available

    func testPropagateErrorWhenNeitherRemoteNorCachedDataIsAvailable() async throws {
        let container = try makeInMemoryContainer()

        let mockRemote = MockEventRepository()
        await mockRemote.setShouldThrow(true, error: DataError.networkUnavailable)

        let repository = PersistentEventRepository(modelContainer: container, remoteRepository: mockRemote)

        do {
            _ = try await repository.fetchEvents()
            XCTFail("Expected DataError.networkUnavailable, but fetchEvents succeeded")
        } catch let error as DataError {
            XCTAssertEqual(error, DataError.networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - 5. Event Sorting Chronological Newest First

    func testCachedEventSorting_newestFirst() async throws {
        let container = try makeInMemoryContainer()

        let baseDate = Date()
        let oldEvent = SecurityEvent(
            id: "1",
            title: "Old Event",
            description: "D",
            timestamp: baseDate.addingTimeInterval(-3600),
            severity: .info,
            type: .systemArmed
        )
        let newEvent = SecurityEvent(
            id: "2",
            title: "New Event",
            description: "D",
            timestamp: baseDate,
            severity: .critical,
            type: .sensorOffline
        )

        let mockRemote = MockEventRepository(events: [oldEvent, newEvent])
        let repository = PersistentEventRepository(modelContainer: container, remoteRepository: mockRemote)

        let retrieved = try await repository.fetchEvents()

        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved[0].id, "2", "Newest event must be first")
        XCTAssertEqual(retrieved[1].id, "1", "Older event must be second")
        XCTAssertTrue(retrieved[0].timestamp > retrieved[1].timestamp)
    }
}
