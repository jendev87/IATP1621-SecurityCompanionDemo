//
//  AppContainer.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 18/11/26.
//

import Foundation
import SwiftData

@MainActor
final class AppContainer {

    // MARK: - Long-Lived Shared Dependencies

    let modelContainer: ModelContainer?

    let zoneRepository: ZoneRepository
    let getZonesUseCase: GetZonesUseCase
    let armZoneUseCase: ArmZoneUseCase
    let disarmZoneUseCase: DisarmZoneUseCase

    let eventRepository: EventRepository
    let getEventsUseCase: GetEventsUseCase

    let sessionManager: AuthSessionManager
    let preferences: UserPreferences

    // MARK: - Initializers

    /// Primary production initializer using SwiftData persistence.
    init(
        modelContainer: ModelContainer,
        remoteEventRepository: EventRepository = RemoteEventRepository(),
        sessionManager: AuthSessionManager? = nil,
        preferences: UserPreferences? = nil
    ) {
        self.modelContainer = modelContainer
        self.sessionManager = sessionManager ?? .shared
        self.preferences = preferences ?? .shared

        let zoneRepo = SwiftDataZoneRepository(modelContainer: modelContainer)
        let eventRepo = PersistentEventRepository(
            modelContainer: modelContainer,
            remoteRepository: remoteEventRepository
        )

        self.zoneRepository = zoneRepo
        self.eventRepository = eventRepo

        self.getZonesUseCase = GetZonesUseCase(zoneRepository: zoneRepo)
        self.armZoneUseCase = ArmZoneUseCase(zoneRepository: zoneRepo)
        self.disarmZoneUseCase = DisarmZoneUseCase(zoneRepository: zoneRepo)

        self.getEventsUseCase = GetEventsUseCase(eventRepository: eventRepo)

        // Seed sample zones if persistent store contains no zones
        Task {
            do {
                try await zoneRepo.seedInitialDataIfNeeded(sampleZones: AppContainer.sampleZones)
            } catch {
                print("AppContainer: Failed to seed initial zones: \(error)")
            }
        }
    }

    /// Flexible initializer for injecting custom repositories (e.g. In-Memory or Mocks for testing).
    init(
        zoneRepository: ZoneRepository,
        eventRepository: EventRepository = RemoteEventRepository(),
        modelContainer: ModelContainer? = nil,
        sessionManager: AuthSessionManager? = nil,
        preferences: UserPreferences? = nil
    ) {
        self.modelContainer = modelContainer
        self.sessionManager = sessionManager ?? .shared
        self.preferences = preferences ?? .shared
        self.zoneRepository = zoneRepository
        self.getZonesUseCase = GetZonesUseCase(zoneRepository: zoneRepository)
        self.armZoneUseCase = ArmZoneUseCase(zoneRepository: zoneRepository)
        self.disarmZoneUseCase = DisarmZoneUseCase(zoneRepository: zoneRepository)

        self.eventRepository = eventRepository
        self.getEventsUseCase = GetEventsUseCase(eventRepository: eventRepository)
    }

    /// Default convenience initializer using the shared persistent SwiftData store.
    convenience init() {
        let container = AppContainer.createDefaultModelContainer(inMemory: false)
        self.init(modelContainer: container)
    }

    // MARK: - Container Creation & Fallback

    static func createDefaultModelContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            ZoneModel.self,
            SensorModel.self,
            SecurityEventModel.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("AppContainer: Failed to create persistent ModelContainer (\(error.localizedDescription)). Falling back to in-memory store.")
            let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [inMemoryConfig])
            } catch {
                fatalError("AppContainer: Fatal error creating fallback ModelContainer: \(error)")
            }
        }
    }

    /// Helper for SwiftUI previews or isolated testing.
    static func inMemory() -> AppContainer {
        let container = AppContainer.createDefaultModelContainer(inMemory: true)
        return AppContainer(modelContainer: container)
    }

    // MARK: - Factory Methods

    func makeZoneListViewModel() -> ZoneListViewModel {
        ZoneListViewModel(getZonesUseCase: getZonesUseCase)
    }

    func makeZoneDetailViewModel(zone: Zone) -> ZoneDetailViewModel {
        ZoneDetailViewModel(
            zone: zone,
            armZoneUseCase: armZoneUseCase,
            disarmZoneUseCase: disarmZoneUseCase
        )
    }

    func makeEventListViewModel() -> EventListViewModel {
        EventListViewModel(getEventsUseCase: getEventsUseCase)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(session: sessionManager, preferences: preferences)
    }

    // MARK: - Sample Seed Data

    static let sampleZones: [Zone] = [
        Zone(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Front Entry & Porch",
            state: .armed,
            sensors: [
                Sensor(
                    id: UUID(uuidString: "a1111111-1111-1111-1111-111111111111")!,
                    name: "Front Door Contact",
                    type: .doorContact,
                    status: .online,
                    batteryLevel: 92
                ),
                Sensor(
                    id: UUID(uuidString: "a1111111-2222-2222-2222-222222222222")!,
                    name: "Porch Motion Detector",
                    type: .motion,
                    status: .warning,
                    batteryLevel: 18
                )
            ]
        ),
        Zone(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            name: "Living Room",
            state: .disarmed,
            sensors: [
                Sensor(
                    id: UUID(uuidString: "a2222222-1111-1111-1111-111111111111")!,
                    name: "Main Living Motion",
                    type: .motion,
                    status: .online,
                    batteryLevel: 85
                ),
                Sensor(
                    id: UUID(uuidString: "a2222222-2222-2222-2222-222222222222")!,
                    name: "Patio Glass Break",
                    type: .glassBreak,
                    status: .offline,
                    batteryLevel: 0
                ),
                Sensor(
                    id: UUID(uuidString: "a2222222-3333-3333-3333-333333333333")!,
                    name: "Ambient Temperature",
                    type: .temperature,
                    status: .online,
                    batteryLevel: 74
                )
            ]
        ),
        Zone(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            name: "Backyard & Patio",
            state: .armed,
            sensors: [
                Sensor(
                    id: UUID(uuidString: "a3333333-1111-1111-1111-111111111111")!,
                    name: "Patio Sliding Contact",
                    type: .doorContact,
                    status: .online,
                    batteryLevel: 95
                ),
                Sensor(
                    id: UUID(uuidString: "a3333333-2222-2222-2222-222222222222")!,
                    name: "Yard Perimeter Motion",
                    type: .motion,
                    status: .online,
                    batteryLevel: 45
                )
            ]
        ),
        Zone(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            name: "Master Bedroom",
            state: .disarmed,
            sensors: [
                Sensor(
                    id: UUID(uuidString: "a4444444-1111-1111-1111-111111111111")!,
                    name: "Window Contact Sensor",
                    type: .doorContact,
                    status: .online,
                    batteryLevel: 68
                ),
                Sensor(
                    id: UUID(uuidString: "a4444444-2222-2222-2222-222222222222")!,
                    name: "Smoke & CO Detector",
                    type: .smoke,
                    status: .warning,
                    batteryLevel: 15
                )
            ]
        ),
        Zone(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            name: "Garage",
            state: .armed,
            sensors: [
                Sensor(
                    id: UUID(uuidString: "a5555555-1111-1111-1111-111111111111")!,
                    name: "Overhead Door Contact",
                    type: .doorContact,
                    status: .online,
                    batteryLevel: 88
                ),
                Sensor(
                    id: UUID(uuidString: "a5555555-2222-2222-2222-222222222222")!,
                    name: "Side Entry Motion",
                    type: .motion,
                    status: .offline,
                    batteryLevel: 10
                )
            ]
        )
    ]
}
