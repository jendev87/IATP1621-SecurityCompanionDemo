//
//  ArmZoneUseCase.swift
//  SecurityCompanionDemo
//
import Foundation

struct ArmZoneUseCase: Sendable {
    private let zoneRepository: ZoneRepository

    init(zoneRepository: ZoneRepository) {
        self.zoneRepository = zoneRepository
    }

    func execute(zoneID: UUID) async throws -> Zone {
        guard var zone = try await zoneRepository.fetchZone(id: zoneID) else {
            throw DomainError.notFound
        }

        guard zone.state == .disarmed else {
            throw DomainError.alreadyArmed
        }

        zone.state = .armed

        try await zoneRepository.updateZone(zone)
        return zone
    }
}
