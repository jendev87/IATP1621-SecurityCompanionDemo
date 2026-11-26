//
//  DisarmZoneUseCase.swift
//  SecurityCompanionDemo
//
import Foundation

struct DisarmZoneUseCase: Sendable {
    private let zoneRepository: ZoneRepository

    init(zoneRepository: ZoneRepository) {
        self.zoneRepository = zoneRepository
    }

    func execute(zoneID: UUID) async throws -> Zone{
        guard var zone = try await zoneRepository.fetchZone(id: zoneID) else {
            throw DomainError.notFound
        }

        guard zone.state == .armed else {
            throw DomainError.alreadyDisarmed
        }

        zone.state = .disarmed

        try await zoneRepository.updateZone(zone)
        return zone
    }
}


