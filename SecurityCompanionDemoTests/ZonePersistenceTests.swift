//
//  ZonePersistenceTests.swift
//  SecurityCompanionDemoTests
//

import XCTest
import SwiftData
@testable import SecurityCompanionDemo

final class ZonePersistenceTests: XCTestCase {

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            ZoneModel.self,
            SensorModel.self,
            SecurityEventModel.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - 1. Insert and Retrieve Zones

    func testInsertAndRetrieveZones() async throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataZoneRepository(modelContainer: container)

        let zone1 = Zone(id: UUID(), name: "Front Porch", state: .armed)
        let zone2 = Zone(id: UUID(), name: "Living Room", state: .disarmed)

        try await repository.insertZone(zone1, orderIndex: 0)
        try await repository.insertZone(zone2, orderIndex: 1)

        let retrieved = try await repository.fetchZones()

        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved[0].name, "Front Porch")
        XCTAssertEqual(retrieved[0].state, .armed)
        XCTAssertEqual(retrieved[1].name, "Living Room")
        XCTAssertEqual(retrieved[1].state, .disarmed)
    }

    // MARK: - 2. Retrieve Zone by ID

    func testRetrieveZoneByID() async throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataZoneRepository(modelContainer: container)

        let targetID = UUID()
        let zone = Zone(id: targetID, name: "Master Bedroom", state: .armed)
        try await repository.insertZone(zone)

        let found = try await repository.fetchZone(id: targetID)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, targetID)
        XCTAssertEqual(found?.name, "Master Bedroom")
        XCTAssertEqual(found?.state, .armed)

        let notFound = try await repository.fetchZone(id: UUID())
        XCTAssertNil(notFound)
    }

    // MARK: - 3. Update Armed / Disarmed State

    func testUpdateArmedDisarmedState() async throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataZoneRepository(modelContainer: container)

        let zoneID = UUID()
        var zone = Zone(id: zoneID, name: "Garage", state: .disarmed)
        try await repository.insertZone(zone)

        // Verify initial state
        var fetched = try await repository.fetchZone(id: zoneID)
        XCTAssertEqual(fetched?.state, .disarmed)

        // Update to armed
        zone.state = .armed
        try await repository.updateZone(zone)

        fetched = try await repository.fetchZone(id: zoneID)
        XCTAssertEqual(fetched?.state, .armed)

        // Update back to disarmed
        zone.state = .disarmed
        try await repository.updateZone(zone)

        fetched = try await repository.fetchZone(id: zoneID)
        XCTAssertEqual(fetched?.state, .disarmed)
    }

    // MARK: - 4. Persist Associated Sensors

    func testPersistAssociatedSensors() async throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataZoneRepository(modelContainer: container)

        let sensor1 = Sensor(name: "Door Contact", type: .doorContact, status: .online, batteryLevel: 95)
        let sensor2 = Sensor(name: "Motion Detector", type: .motion, status: .warning, batteryLevel: 15)

        let zoneID = UUID()
        var zone = Zone(id: zoneID, name: "Front Entry", state: .armed, sensors: [sensor1, sensor2])
        try await repository.insertZone(zone)

        // Retrieve and verify sensors
        var fetched = try await repository.fetchZone(id: zoneID)
        XCTAssertEqual(fetched?.sensors.count, 2)

        let retrievedSensor1 = fetched?.sensors.first(where: { $0.id == sensor1.id })
        XCTAssertNotNil(retrievedSensor1)
        XCTAssertEqual(retrievedSensor1?.type, .doorContact)
        XCTAssertEqual(retrievedSensor1?.batteryLevel, 95)
        XCTAssertEqual(retrievedSensor1?.status, .online)

        // Update a sensor's properties
        zone.sensors[0].batteryLevel = 88
        zone.sensors[0].status = .warning
        try await repository.updateZone(zone)

        fetched = try await repository.fetchZone(id: zoneID)
        let updatedSensor1 = fetched?.sensors.first(where: { $0.id == sensor1.id })
        XCTAssertEqual(updatedSensor1?.batteryLevel, 88)
        XCTAssertEqual(updatedSensor1?.status, .warning)
    }

    // MARK: - 5. Cascade Delete of Sensors

    func testCascadeDeleteSensorsWhenZoneDeleted() async throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataZoneRepository(modelContainer: container)

        let sensor = Sensor(name: "Test Motion", type: .motion, status: .online, batteryLevel: 100)
        let zoneID = UUID()
        let zone = Zone(id: zoneID, name: "Storage Room", state: .disarmed, sensors: [sensor])
        try await repository.insertZone(zone)

        // Delete zone
        try await repository.deleteZone(id: zoneID)

        let fetchedZone = try await repository.fetchZone(id: zoneID)
        XCTAssertNil(fetchedZone)

        // Verify SensorModel is also deleted
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<SensorModel>()
        let remainingSensors = try context.fetch(descriptor)
        XCTAssertTrue(remainingSensors.isEmpty, "Sensors must be cascade-deleted when their zone is deleted")
    }

    // MARK: - 6. Verify Data Survives Reopening Persistent Store

    func testDataSurvivesReopeningPersistentStore() async throws {
        // Create a unique temporary SQLite store on disk
        let tempDir = FileManager.default.temporaryDirectory
        let storeURL = tempDir.appendingPathComponent("TestStore_\(UUID().uuidString).store")
        defer {
            try? FileManager.default.removeItem(at: storeURL)
        }

        let schema = Schema([
            ZoneModel.self,
            SensorModel.self,
            SecurityEventModel.self
        ])
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        let targetZoneID = UUID()
        let sensorID = UUID()

        // Scope 1: Insert zone in first container session
        do {
            let container1 = try ModelContainer(for: schema, configurations: [configuration])
            let repo1 = SwiftDataZoneRepository(modelContainer: container1)

            let sensor = Sensor(id: sensorID, name: "Patio Contact", type: .doorContact, status: .online, batteryLevel: 90)
            let zone = Zone(id: targetZoneID, name: "Backyard Garden", state: .armed, sensors: [sensor])
            try await repo1.insertZone(zone)
        }

        // Scope 2: Open second container session pointing to the exact same SQLite store
        do {
            let container2 = try ModelContainer(for: schema, configurations: [configuration])
            let repo2 = SwiftDataZoneRepository(modelContainer: container2)

            let retrieved = try await repo2.fetchZone(id: targetZoneID)
            XCTAssertNotNil(retrieved, "Zone must survive closing and reopening the persistent store")
            XCTAssertEqual(retrieved?.name, "Backyard Garden")
            XCTAssertEqual(retrieved?.state, .armed)
            XCTAssertEqual(retrieved?.sensors.count, 1)
            XCTAssertEqual(retrieved?.sensors.first?.id, sensorID)
            XCTAssertEqual(retrieved?.sensors.first?.name, "Patio Contact")
        }
    }

    // MARK: - 7. Seed Initial Data Only When Empty

    func testSeedInitialData_onlyRunsWhenEmpty() async throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataZoneRepository(modelContainer: container)

        let sample = [
            Zone(id: UUID(), name: "Zone 1", state: .disarmed),
            Zone(id: UUID(), name: "Zone 2", state: .disarmed)
        ]

        // 1. Initial seed populates
        try await repository.seedInitialDataIfNeeded(sampleZones: sample)
        var zones = try await repository.fetchZones()
        XCTAssertEqual(zones.count, 2)

        // 2. User changes Zone 1 to armed
        var modified = zones[0]
        modified.state = .armed
        try await repository.updateZone(modified)

        // 3. Second seed call does NOT overwrite or duplicate
        try await repository.seedInitialDataIfNeeded(sampleZones: sample)
        zones = try await repository.fetchZones()
        XCTAssertEqual(zones.count, 2, "Seeding must not duplicate records")
        let reloadedZone1 = zones.first(where: { $0.id == modified.id })
        XCTAssertEqual(reloadedZone1?.state, .armed, "User state changes must be preserved")
    }
}
