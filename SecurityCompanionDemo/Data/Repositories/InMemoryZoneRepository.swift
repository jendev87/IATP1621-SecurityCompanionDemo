//
//  InMemoryZoneRepository.swift
//  SecurityCompanionDemo
//

import Foundation

actor InMemoryZoneRepository: ZoneRepository {
    
    private var zones: [Zone]
    
    init(zones: [Zone] = []) {
        self.zones = zones
    }
    
    func fetchZones() throws -> [Zone] {
        return zones
    }
    
    func updateZone(_ zone: Zone) throws {
        guard let index = zones.firstIndex(where: { $0.id == zone.id }) else {
            throw DataError.zoneNotFound
        }
        zones[index] = zone
    }
    
    func fetchZone(id: UUID) throws -> Zone? {
        return zones.first(where: { $0.id == id })
    }
}

