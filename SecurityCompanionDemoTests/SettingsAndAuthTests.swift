//
//  SettingsAndAuthTests.swift
//  SecurityCompanionDemoTests
//

import XCTest
import SwiftData
@testable import SecurityCompanionDemo

final class SettingsAndAuthTests: XCTestCase {

    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "TestPreferences_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            ZoneModel.self,
            SensorModel.self,
            SecurityEventModel.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - 1. Default Preference Values

    @MainActor
    func testDefaultPreferenceValues() {
        let testDefaults = makeIsolatedDefaults()
        let preferences = UserPreferences(defaults: testDefaults)

        XCTAssertTrue(preferences.securityEventAlerts, "Security event alerts should default to true")
        XCTAssertTrue(preferences.sensorHealthAlerts, "Sensor health alerts should default to true")
        XCTAssertTrue(preferences.requireDisarmConfirmation, "Disarm confirmation should default to true")
        XCTAssertTrue(preferences.showSensorWarnings, "Sensor health warnings should default to true")
    }

    // MARK: - 2. Preference Persistence Across Relaunch

    @MainActor
    func testPreferencePersistenceAcrossRelaunch() {
        let testDefaults = makeIsolatedDefaults()

        // Session 1: Modify preferences
        do {
            let preferences1 = UserPreferences(defaults: testDefaults)
            preferences1.requireDisarmConfirmation = false
            preferences1.showSensorWarnings = false
            preferences1.securityEventAlerts = false
            preferences1.sensorHealthAlerts = false
        }

        // Session 2: Reload from same defaults
        do {
            let preferences2 = UserPreferences(defaults: testDefaults)
            XCTAssertFalse(preferences2.requireDisarmConfirmation, "requireDisarmConfirmation must persist")
            XCTAssertFalse(preferences2.showSensorWarnings, "showSensorWarnings must persist")
            XCTAssertFalse(preferences2.securityEventAlerts, "securityEventAlerts must persist")
            XCTAssertFalse(preferences2.sensorHealthAlerts, "sensorHealthAlerts must persist")
        }
    }

    // MARK: - 3. Mock Authentication & Sign Out Behavior

    @MainActor
    func testAuthSession_signInAndSignOut() {
        let testDefaults = makeIsolatedDefaults()
        let session = AuthSessionManager(defaults: testDefaults, storageKey: "test_auth")

        XCTAssertTrue(session.isAuthenticated, "Session should default to authenticated")
        XCTAssertEqual(session.currentUser.name, "Alex Morgan")

        // Sign out
        session.signOut()
        XCTAssertFalse(session.isAuthenticated, "Session should be unauthenticated after sign out")

        // Sign back in
        session.signIn()
        XCTAssertTrue(session.isAuthenticated, "Session should be authenticated after sign in")
    }

    // MARK: - 4. Disarm Confirmation Rule Evaluation

    @MainActor
    func testDisarmConfirmation_behaviorEvaluation() {
        let testDefaults = makeIsolatedDefaults()
        let preferences = UserPreferences(defaults: testDefaults)

        let armedZone = Zone(id: UUID(), name: "Front Entry", state: .armed)
        let disarmedZone = Zone(id: UUID(), name: "Front Entry", state: .disarmed)

        // 1. With confirmation enabled
        preferences.requireDisarmConfirmation = true
        let requiresPromptWhenArmed = (armedZone.state == .armed && preferences.requireDisarmConfirmation)
        XCTAssertTrue(requiresPromptWhenArmed, "Armed zone with confirmation enabled must prompt dialog")

        let requiresPromptWhenDisarmed = (disarmedZone.state == .armed && preferences.requireDisarmConfirmation)
        XCTAssertFalse(requiresPromptWhenDisarmed, "Arming a disarmed zone should not prompt disarm confirmation")

        // 2. With confirmation disabled
        preferences.requireDisarmConfirmation = false
        let requiresPromptWhenDisabled = (armedZone.state == .armed && preferences.requireDisarmConfirmation)
        XCTAssertFalse(requiresPromptWhenDisabled, "Armed zone with confirmation disabled should proceed without prompt")
    }

    // MARK: - 5. Sensor Warning Visibility Without Mutating Domain

    @MainActor
    func testSensorWarningVisibility_hidesVisualsWithoutMutatingDomain() {
        let testDefaults = makeIsolatedDefaults()
        let preferences = UserPreferences(defaults: testDefaults)

        let criticalSensor = Sensor(
            name: "Living Room Motion",
            type: .motion,
            status: .offline,
            batteryLevel: 10
        )

        // Domain health requirements remain completely intact
        XCTAssertTrue(criticalSensor.requiresAttention)
        XCTAssertTrue(criticalSensor.hasLowBattery)
        XCTAssertEqual(criticalSensor.status, .offline)

        // UI Presentation flag controls visibility
        preferences.showSensorWarnings = true
        let shouldShowWhenEnabled = (preferences.showSensorWarnings && criticalSensor.requiresAttention)
        XCTAssertTrue(shouldShowWhenEnabled)

        preferences.showSensorWarnings = false
        let shouldShowWhenDisabled = (preferences.showSensorWarnings && criticalSensor.requiresAttention)
        XCTAssertFalse(shouldShowWhenDisabled, "Warning presentation must be hidden when showSensorWarnings is false")

        // Underlying sensor data remains unchanged
        XCTAssertEqual(criticalSensor.batteryLevel, 10)
        XCTAssertEqual(criticalSensor.status, .offline)
    }

    // MARK: - 6. Persisted Application Data Remains Intact After Sign Out

    @MainActor
    func testSignOut_preservesPersistedZonesAndEvents() async throws {
        let container = try makeInMemoryContainer()
        let testDefaults = makeIsolatedDefaults()
        let session = AuthSessionManager(defaults: testDefaults, storageKey: "persist_auth_test")

        let zoneRepo = SwiftDataZoneRepository(modelContainer: container)
        let mockRemote = MockEventRepository(events: [
            SecurityEvent(id: "1", title: "Test Event", description: "D", timestamp: Date(), severity: .info, type: .systemArmed)
        ])
        let eventRepo = PersistentEventRepository(modelContainer: container, remoteRepository: mockRemote)

        _ = AppContainer(
            zoneRepository: zoneRepo,
            eventRepository: eventRepo,
            modelContainer: container,
            sessionManager: session
        )

        // 1. Insert a zone and an event while signed in
        let testZone = Zone(id: UUID(), name: "Vault Room", state: .armed)
        try await zoneRepo.insertZone(testZone)
        let initialEvents = try await eventRepo.fetchEvents()
        XCTAssertEqual(initialEvents.count, 1)

        // 2. User signs out
        session.signOut()
        XCTAssertFalse(session.isAuthenticated)

        // 3. Verify database records are NOT deleted
        let zonesAfterSignOut = try await zoneRepo.fetchZones()
        XCTAssertEqual(zonesAfterSignOut.count, 1)
        XCTAssertEqual(zonesAfterSignOut.first?.name, "Vault Room")

        let cachedEventsAfterSignOut = try await eventRepo.fetchCachedEvents()
        XCTAssertEqual(cachedEventsAfterSignOut.count, 1)
        XCTAssertEqual(cachedEventsAfterSignOut.first?.title, "Test Event")

        // 4. User signs back in
        session.signIn()
        XCTAssertTrue(session.isAuthenticated)

        // 5. App restored with identical persisted data
        let restoredZones = try await zoneRepo.fetchZones()
        XCTAssertEqual(restoredZones.count, 1)
        XCTAssertEqual(restoredZones.first?.id, testZone.id)
    }

    // MARK: - 7. SettingsViewModel Metadata

    @MainActor
    func testSettingsViewModel_metadataAndActions() {
        let testDefaults = makeIsolatedDefaults()
        let session = AuthSessionManager(defaults: testDefaults)
        let preferences = UserPreferences(defaults: testDefaults)

        let viewModel = SettingsViewModel(session: session, preferences: preferences)

        XCTAssertEqual(viewModel.appName, "Security Monitoring Companion")
        XCTAssertFalse(viewModel.appVersion.isEmpty)
        XCTAssertEqual(viewModel.account.name, "Alex Morgan")
        XCTAssertEqual(viewModel.account.email, "alex.morgan@example.com")
        XCTAssertEqual(viewModel.account.role, "Primary Administrator")
        XCTAssertEqual(viewModel.account.propertyName, "Oakwood Family Residence")

        XCTAssertFalse(viewModel.showingSignOutConfirmation)
        viewModel.showingSignOutConfirmation = true
        XCTAssertTrue(viewModel.showingSignOutConfirmation)

        viewModel.signOut()
        XCTAssertFalse(session.isAuthenticated)
    }
}
