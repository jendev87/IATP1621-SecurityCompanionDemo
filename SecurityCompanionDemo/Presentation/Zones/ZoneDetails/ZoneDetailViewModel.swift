//
//  ZoneDetailViewModel.swift
//  SecurityCompanionDemo
//

import Foundation
import Observation

enum ZoneOperationState: Equatable {
    case idle
    case loading
    case error(String)
}

@MainActor
@Observable
final class ZoneDetailViewModel {

    var zone: Zone
    var operationState: ZoneOperationState = .idle

    private let armZoneUseCase: ArmZoneUseCase
    private let disarmZoneUseCase: DisarmZoneUseCase

    init(
        zone: Zone,
        armZoneUseCase: ArmZoneUseCase,
        disarmZoneUseCase: DisarmZoneUseCase
    ) {
        self.zone = zone
        self.armZoneUseCase = armZoneUseCase
        self.disarmZoneUseCase = disarmZoneUseCase
    }

    // MARK: - Security State Properties

    var statusText: String {
        zone.state == .armed ? "Armed" : "Disarmed"
    }

    var isLoading: Bool {
        operationState == .loading
    }

    // MARK: - Sensor Overview & Health Metrics

    var sensors: [Sensor] {
        zone.sensors
    }

    var totalSensorsCount: Int {
        zone.sensors.count
    }

    var onlineSensorsCount: Int {
        zone.sensors.filter { $0.status == .online }.count
    }

    var offlineSensorsCount: Int {
        zone.sensors.filter { $0.status == .offline }.count
    }

    var attentionSensorsCount: Int {
        zone.sensors.filter { $0.requiresAttention }.count
    }

    var hasSensors: Bool {
        !zone.sensors.isEmpty
    }

    var hasAttentionSensors: Bool {
        attentionSensorsCount > 0
    }

    // MARK: - User Operations

    func toggleSecurity() async {
        // Prevent duplicate operations while loading.
        guard !isLoading else { return }

        operationState = .loading

        do {
            if zone.state == .armed {
                zone = try await disarmZoneUseCase.execute(
                    zoneID: zone.id
                )
            } else {
                zone = try await armZoneUseCase.execute(
                    zoneID: zone.id
                )
            }

            operationState = .idle

        } catch let domainError as DomainError {
            operationState = .error(domainError.localizedDescription)
        } catch {
            operationState = .error(
                "Unable to update the zone. Please try again."
            )
        }
    }
}
