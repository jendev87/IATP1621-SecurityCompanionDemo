//
//  SensorModel.swift
//  SecurityCompanionDemo
//

import Foundation
import SwiftData

@Model
final class SensorModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRawValue: String
    var statusRawValue: String
    var batteryLevel: Int

    var zone: ZoneModel?

    init(
        id: UUID,
        name: String,
        typeRawValue: String,
        statusRawValue: String,
        batteryLevel: Int,
        zone: ZoneModel? = nil
    ) {
        self.id = id
        self.name = name
        self.typeRawValue = typeRawValue
        self.statusRawValue = statusRawValue
        self.batteryLevel = batteryLevel
        self.zone = zone
    }

    convenience init(from domain: Sensor, zone: ZoneModel? = nil) {
        self.init(
            id: domain.id,
            name: domain.name,
            typeRawValue: domain.type.rawValue,
            statusRawValue: domain.status.rawValue,
            batteryLevel: domain.batteryLevel,
            zone: zone
        )
    }

    var sensorType: SensorType {
        SensorType(rawValue: typeRawValue) ?? .motion
    }

    var sensorStatus: SensorStatus {
        SensorStatus(rawValue: statusRawValue) ?? .online
    }

    func toDomain() -> Sensor {
        Sensor(
            id: id,
            name: name,
            type: sensorType,
            status: sensorStatus,
            batteryLevel: batteryLevel
        )
    }
}
