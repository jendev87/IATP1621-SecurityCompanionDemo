//
//  SwiftDataZoneRepository.swift
//  SecurityCompanionDemo
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataZoneRepository: ZoneRepository {

    func fetchZones() throws -> [Zone] {
        let descriptor = FetchDescriptor<ZoneModel>(
            sortBy: [SortDescriptor(\.orderIndex, order: .forward), SortDescriptor(\.name, order: .forward)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    func fetchZone(id: UUID) throws -> Zone? {
        let targetID = id
        let descriptor = FetchDescriptor<ZoneModel>(
            predicate: #Predicate<ZoneModel> { $0.id == targetID }
        )
        let matches = try modelContext.fetch(descriptor)
        return matches.first?.toDomain()
    }

    func updateZone(_ zone: Zone) throws {
        let targetID = zone.id
        let descriptor = FetchDescriptor<ZoneModel>(
            predicate: #Predicate<ZoneModel> { $0.id == targetID }
        )
        guard let zoneModel = try modelContext.fetch(descriptor).first else {
            throw DataError.zoneNotFound
        }

        zoneModel.name = zone.name
        zoneModel.securityState = zone.state

        // Synchronize sensors
        let updatedSensorIDs = Set(zone.sensors.map { $0.id })
        for existingSensor in zoneModel.sensors where !updatedSensorIDs.contains(existingSensor.id) {
            modelContext.delete(existingSensor)
        }

        var updatedSensors: [SensorModel] = []
        for domainSensor in zone.sensors {
            if let existing = zoneModel.sensors.first(where: { $0.id == domainSensor.id }) {
                existing.name = domainSensor.name
                existing.typeRawValue = domainSensor.type.rawValue
                existing.statusRawValue = domainSensor.status.rawValue
                existing.batteryLevel = domainSensor.batteryLevel
                updatedSensors.append(existing)
            } else {
                let newModel = SensorModel(from: domainSensor, zone: zoneModel)
                modelContext.insert(newModel)
                updatedSensors.append(newModel)
            }
        }
        zoneModel.sensors = updatedSensors

        try modelContext.save()
    }

    func insertZone(_ zone: Zone, orderIndex: Int = 0) throws {
        let targetID = zone.id
        let descriptor = FetchDescriptor<ZoneModel>(
            predicate: #Predicate<ZoneModel> { $0.id == targetID }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.orderIndex = orderIndex
            try updateZone(zone)
        } else {
            let model = ZoneModel(from: zone, orderIndex: orderIndex)
            modelContext.insert(model)
            try modelContext.save()
        }
    }

    func deleteZone(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<ZoneModel>(
            predicate: #Predicate<ZoneModel> { $0.id == targetID }
        )
        if let model = try modelContext.fetch(descriptor).first {
            modelContext.delete(model)
            try modelContext.save()
        }
    }

    func seedInitialDataIfNeeded(sampleZones: [Zone]) throws {
        let descriptor = FetchDescriptor<ZoneModel>()
        let count = try modelContext.fetchCount(descriptor)
        guard count == 0 else { return }

        for (index, zone) in sampleZones.enumerated() {
            let model = ZoneModel(from: zone, orderIndex: index)
            modelContext.insert(model)
        }
        try modelContext.save()
    }

    func fetchZoneCount() throws -> Int {
        let descriptor = FetchDescriptor<ZoneModel>()
        return try modelContext.fetchCount(descriptor)
    }

    func deleteAllZones() throws {
        let descriptor = FetchDescriptor<ZoneModel>()
        let all = try modelContext.fetch(descriptor)
        for zone in all {
            modelContext.delete(zone)
        }
        try modelContext.save()
    }
}
