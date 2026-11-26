//
//  SecurityCompanionDemoTests.swift
//  SecurityCompanionDemoTests
//
//  Created by thinkpalm on 10/11/26.
//

import XCTest
@testable import SecurityCompanionDemo

// MARK: - Mock Zone Repository for Testing

actor MockZoneRepository: ZoneRepository {
    private var zones: [Zone]
    var shouldThrow: Bool = false
    var errorToThrow: Error = DataError.zoneNotFound

    init(zones: [Zone] = []) {
        self.zones = zones
    }

    func setShouldThrow(_ value: Bool, error: Error = DataError.zoneNotFound) {
        self.shouldThrow = value
        self.errorToThrow = error
    }

    func setZones(_ newZones: [Zone]) {
        self.zones = newZones
    }

    func fetchZones() throws -> [Zone] {
        if shouldThrow {
            throw errorToThrow
        }
        return zones
    }

    func updateZone(_ zone: Zone) throws {
        if shouldThrow {
            throw errorToThrow
        }
        guard let index = zones.firstIndex(where: { $0.id == zone.id }) else {
            throw DataError.zoneNotFound
        }
        zones[index] = zone
    }

    func fetchZone(id: UUID) throws -> Zone? {
        if shouldThrow {
            throw errorToThrow
        }
        return zones.first(where: { $0.id == id })
    }
}

// MARK: - Unit Tests

final class SecurityCompanionDemoTests: XCTestCase {

    // MARK: - GetZonesUseCase Tests

    func testGetZonesUseCase_returnsZonesFromRepository() async throws {
        let sampleZones = [
            Zone(id: UUID(), name: "Front Entry", state: .armed),
            Zone(id: UUID(), name: "Living Room", state: .disarmed)
        ]
        let mockRepo = MockZoneRepository(zones: sampleZones)
        let useCase = GetZonesUseCase(zoneRepository: mockRepo)

        let result = try await useCase.execute()

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result, sampleZones)
    }

    func testGetZonesUseCase_propagatesErrorWhenRepositoryFails() async {
        let mockRepo = MockZoneRepository()
        await mockRepo.setShouldThrow(true, error: DataError.zoneNotFound)
        let useCase = GetZonesUseCase(zoneRepository: mockRepo)

        do {
            _ = try await useCase.execute()
            XCTFail("Expected error to be propagated, but call succeeded")
        } catch let error as DataError {
            XCTAssertEqual(error, DataError.zoneNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGetZonesUseCase_returnsEmptyArrayWhenNoZonesExist() async throws {
        let mockRepo = MockZoneRepository(zones: [])
        let useCase = GetZonesUseCase(zoneRepository: mockRepo)

        let result = try await useCase.execute()

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - ZoneListViewModel Dashboard State & Derivation Tests

    @MainActor
    func testOverallStatus_whenAllZonesArmed_returnsAllArmed() async {
        let allArmedZones = [
            Zone(id: UUID(), name: "Front Door", state: .armed),
            Zone(id: UUID(), name: "Backyard", state: .armed)
        ]
        let mockRepo = MockZoneRepository(zones: allArmedZones)
        let useCase = GetZonesUseCase(zoneRepository: mockRepo)
        let viewModel = ZoneListViewModel(getZonesUseCase: useCase)

        await viewModel.loadZones()

        XCTAssertEqual(viewModel.overallStatus, .allArmed)
        XCTAssertEqual(viewModel.overallStatus.title, "All Zones Armed")
        XCTAssertEqual(viewModel.armedCount, 2)
        XCTAssertEqual(viewModel.disarmedCount, 0)
        XCTAssertEqual(viewModel.totalCount, 2)
    }

    @MainActor
    func testOverallStatus_whenAllZonesDisarmed_returnsAllDisarmed() async {
        let allDisarmedZones = [
            Zone(id: UUID(), name: "Living Room", state: .disarmed),
            Zone(id: UUID(), name: "Kitchen", state: .disarmed)
        ]
        let mockRepo = MockZoneRepository(zones: allDisarmedZones)
        let useCase = GetZonesUseCase(zoneRepository: mockRepo)
        let viewModel = ZoneListViewModel(getZonesUseCase: useCase)

        await viewModel.loadZones()

        XCTAssertEqual(viewModel.overallStatus, .allDisarmed)
        XCTAssertEqual(viewModel.overallStatus.title, "All Zones Disarmed")
        XCTAssertEqual(viewModel.armedCount, 0)
        XCTAssertEqual(viewModel.disarmedCount, 2)
        XCTAssertEqual(viewModel.totalCount, 2)
    }

    @MainActor
    func testOverallStatus_whenMixedZones_returnsPartiallyArmed() async {
        let mixedZones = [
            Zone(id: UUID(), name: "Front Door", state: .armed),
            Zone(id: UUID(), name: "Living Room", state: .disarmed),
            Zone(id: UUID(), name: "Garage", state: .armed)
        ]
        let mockRepo = MockZoneRepository(zones: mixedZones)
        let useCase = GetZonesUseCase(zoneRepository: mockRepo)
        let viewModel = ZoneListViewModel(getZonesUseCase: useCase)

        await viewModel.loadZones()

        XCTAssertEqual(viewModel.overallStatus, .partiallyArmed)
        XCTAssertEqual(viewModel.overallStatus.title, "Partially Armed")
        XCTAssertEqual(viewModel.armedCount, 2)
        XCTAssertEqual(viewModel.disarmedCount, 1)
        XCTAssertEqual(viewModel.totalCount, 3)
    }

    @MainActor
    func testOverallStatus_whenNoZones_returnsNoZones() async {
        let mockRepo = MockZoneRepository(zones: [])
        let useCase = GetZonesUseCase(zoneRepository: mockRepo)
        let viewModel = ZoneListViewModel(getZonesUseCase: useCase)

        await viewModel.loadZones()

        XCTAssertEqual(viewModel.overallStatus, .noZones)
        XCTAssertEqual(viewModel.overallStatus.title, "No Zones Configured")
        XCTAssertEqual(viewModel.totalCount, 0)
        XCTAssertEqual(viewModel.uiState, .empty)
    }

    @MainActor
    func testLoadZones_failureTransition_setsErrorStateAndRetryRecovers() async {
        let mockRepo = MockZoneRepository(zones: [
            Zone(id: UUID(), name: "Front Door", state: .armed)
        ])
        await mockRepo.setShouldThrow(true)
        let useCase = GetZonesUseCase(zoneRepository: mockRepo)
        let viewModel = ZoneListViewModel(getZonesUseCase: useCase)

        // Initial load fails
        await viewModel.loadZones()

        if case .error(let message) = viewModel.uiState {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected .error state, but got \(viewModel.uiState)")
        }

        // Fix failure and retry
        await mockRepo.setShouldThrow(false)
        await viewModel.loadZones()

        if case .loaded(let zones) = viewModel.uiState {
            XCTAssertEqual(zones.count, 1)
            XCTAssertEqual(zones.first?.name, "Front Door")
        } else {
            XCTFail("Expected .loaded state after retry, but got \(viewModel.uiState)")
        }
    }

    // MARK: - ArmZoneUseCase & DisarmZoneUseCase Business Logic Tests

    func testArmZoneUseCase_whenDisarmed_successfullyArmsZone() async throws {
        let zoneID = UUID()
        let initialZone = Zone(id: zoneID, name: "Living Room", state: .disarmed)
        let mockRepo = MockZoneRepository(zones: [initialZone])
        let useCase = ArmZoneUseCase(zoneRepository: mockRepo)

        let updatedZone = try await useCase.execute(zoneID: zoneID)

        XCTAssertEqual(updatedZone.state, .armed)
        let repoZone = try await mockRepo.fetchZone(id: zoneID)
        XCTAssertEqual(repoZone?.state, .armed)
    }

    func testArmZoneUseCase_whenAlreadyArmed_throwsAlreadyArmedError() async throws {
        let zoneID = UUID()
        let initialZone = Zone(id: zoneID, name: "Living Room", state: .armed)
        let mockRepo = MockZoneRepository(zones: [initialZone])
        let useCase = ArmZoneUseCase(zoneRepository: mockRepo)

        do {
            _ = try await useCase.execute(zoneID: zoneID)
            XCTFail("Expected DomainError.alreadyArmed, but call succeeded")
        } catch let error as DomainError {
            XCTAssertEqual(error, DomainError.alreadyArmed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testArmZoneUseCase_whenZoneNotFound_throwsNotFoundError() async throws {
        let mockRepo = MockZoneRepository(zones: [])
        let useCase = ArmZoneUseCase(zoneRepository: mockRepo)

        do {
            _ = try await useCase.execute(zoneID: UUID())
            XCTFail("Expected DomainError.notFound, but call succeeded")
        } catch let error as DomainError {
            XCTAssertEqual(error, DomainError.notFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDisarmZoneUseCase_whenArmed_successfullyDisarmsZone() async throws {
        let zoneID = UUID()
        let initialZone = Zone(id: zoneID, name: "Kitchen", state: .armed)
        let mockRepo = MockZoneRepository(zones: [initialZone])
        let useCase = DisarmZoneUseCase(zoneRepository: mockRepo)

        let updatedZone = try await useCase.execute(zoneID: zoneID)

        XCTAssertEqual(updatedZone.state, .disarmed)
        let repoZone = try await mockRepo.fetchZone(id: zoneID)
        XCTAssertEqual(repoZone?.state, .disarmed)
    }

    func testDisarmZoneUseCase_whenAlreadyDisarmed_throwsAlreadyDisarmedError() async throws {
        let zoneID = UUID()
        let initialZone = Zone(id: zoneID, name: "Kitchen", state: .disarmed)
        let mockRepo = MockZoneRepository(zones: [initialZone])
        let useCase = DisarmZoneUseCase(zoneRepository: mockRepo)

        do {
            _ = try await useCase.execute(zoneID: zoneID)
            XCTFail("Expected DomainError.alreadyDisarmed, but call succeeded")
        } catch let error as DomainError {
            XCTAssertEqual(error, DomainError.alreadyDisarmed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDisarmZoneUseCase_whenZoneNotFound_throwsNotFoundError() async throws {
        let mockRepo = MockZoneRepository(zones: [])
        let useCase = DisarmZoneUseCase(zoneRepository: mockRepo)

        do {
            _ = try await useCase.execute(zoneID: UUID())
            XCTFail("Expected DomainError.notFound, but call succeeded")
        } catch let error as DomainError {
            XCTAssertEqual(error, DomainError.notFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Sensor Health & Monitoring Tests

    func testSensor_lowBatteryThreshold() {
        let criticalSensor = Sensor(name: "Porch Motion", type: .motion, status: .online, batteryLevel: 20)
        let depletedSensor = Sensor(name: "Basement Contact", type: .doorContact, status: .online, batteryLevel: 0)
        let healthySensor = Sensor(name: "Door Sensor", type: .doorContact, status: .online, batteryLevel: 21)
        let fullSensor = Sensor(name: "Glass Break", type: .glassBreak, status: .online, batteryLevel: 100)

        // Threshold <= 20% triggers low battery warning
        XCTAssertTrue(criticalSensor.hasLowBattery, "Sensor at exactly 20% must trigger low-battery warning")
        XCTAssertTrue(depletedSensor.hasLowBattery, "Sensor at 0% must trigger low-battery warning")
        XCTAssertFalse(healthySensor.hasLowBattery, "Sensor at 21% must not trigger low-battery warning")
        XCTAssertFalse(fullSensor.hasLowBattery, "Sensor at 100% must not trigger low-battery warning")
    }

    func testSensor_offlineAndAttentionIdentification() {
        let onlineHealthy = Sensor(name: "Living Room Motion", type: .motion, status: .online, batteryLevel: 80)
        let offlineSensor = Sensor(name: "Garage Motion", type: .motion, status: .offline, batteryLevel: 100)
        let warningSensor = Sensor(name: "Patio Glass Break", type: .glassBreak, status: .warning, batteryLevel: 90)
        let onlineLowBattery = Sensor(name: "Smoke Detector", type: .smoke, status: .online, batteryLevel: 15)

        XCTAssertFalse(onlineHealthy.requiresAttention, "Online healthy sensor should not require attention")
        XCTAssertTrue(offlineSensor.requiresAttention, "Offline sensor must require attention")
        XCTAssertTrue(warningSensor.requiresAttention, "Warning status sensor must require attention")
        XCTAssertTrue(onlineLowBattery.requiresAttention, "Sensor with low battery must require attention even if online")
    }

    @MainActor
    func testZoneDetailViewModel_sensorSummaryCounts() {
        let sensors = [
            Sensor(name: "Front Door Contact", type: .doorContact, status: .online, batteryLevel: 90),
            Sensor(name: "Living Room Motion", type: .motion, status: .online, batteryLevel: 85),
            Sensor(name: "Patio Glass Break", type: .glassBreak, status: .offline, batteryLevel: 0),
            Sensor(name: "Smoke Detector", type: .smoke, status: .warning, batteryLevel: 18)
        ]
        let zone = Zone(id: UUID(), name: "Main Zone", state: .disarmed, sensors: sensors)
        let mockRepo = MockZoneRepository(zones: [zone])
        let armUseCase = ArmZoneUseCase(zoneRepository: mockRepo)
        let disarmUseCase = DisarmZoneUseCase(zoneRepository: mockRepo)
        let viewModel = ZoneDetailViewModel(zone: zone, armZoneUseCase: armUseCase, disarmZoneUseCase: disarmUseCase)

        XCTAssertEqual(viewModel.totalSensorsCount, 4)
        XCTAssertEqual(viewModel.onlineSensorsCount, 2)
        XCTAssertEqual(viewModel.offlineSensorsCount, 1)
        // Attention needed for Patio Glass Break (offline) + Smoke Detector (warning & low battery)
        XCTAssertEqual(viewModel.attentionSensorsCount, 2)
        XCTAssertTrue(viewModel.hasAttentionSensors)
        XCTAssertTrue(viewModel.hasSensors)
    }

    func testZoneSecurityState_remainsIndependentOfSensorHealth() async throws {
        // A zone with offline and depleted sensors should still be armable & disarmable
        let degradedSensors = [
            Sensor(name: "Offline Contact", type: .doorContact, status: .offline, batteryLevel: 0),
            Sensor(name: "Critical Battery Motion", type: .motion, status: .warning, batteryLevel: 5)
        ]
        let zoneID = UUID()
        let initialZone = Zone(id: zoneID, name: "Storage Yard", state: .disarmed, sensors: degradedSensors)
        let mockRepo = MockZoneRepository(zones: [initialZone])
        let armUseCase = ArmZoneUseCase(zoneRepository: mockRepo)
        let disarmUseCase = DisarmZoneUseCase(zoneRepository: mockRepo)

        // 1. Arming succeeds despite offline / low-battery sensors
        let armedZone = try await armUseCase.execute(zoneID: zoneID)
        XCTAssertEqual(armedZone.state, .armed)
        XCTAssertEqual(armedZone.sensors.count, 2, "Sensors collection must be preserved across arming")
        XCTAssertEqual(armedZone.sensors.first?.status, .offline)
        XCTAssertEqual(armedZone.sensors.last?.batteryLevel, 5)

        // 2. Disarming succeeds despite degraded sensors
        let disarmedZone = try await disarmUseCase.execute(zoneID: zoneID)
        XCTAssertEqual(disarmedZone.state, .disarmed)
        XCTAssertEqual(disarmedZone.sensors.count, 2, "Sensors collection must be preserved across disarming")
    }
}

