//
//  ZoneModel.swift
//  SecurityCompanionDemo
//

import Foundation
import SwiftData

@Model
final class ZoneModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var stateRawValue: String
    var orderIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \SensorModel.zone)
    var sensors: [SensorModel] = []

    init(
        id: UUID,
        name: String,
        stateRawValue: String,
        orderIndex: Int = 0,
        sensors: [SensorModel] = []
    ) {
        self.id = id
        self.name = name
        self.stateRawValue = stateRawValue
        self.orderIndex = orderIndex
        self.sensors = sensors
    }

    convenience init(from domain: Zone, orderIndex: Int = 0) {
        self.init(
            id: domain.id,
            name: domain.name,
            stateRawValue: domain.state.rawValue,
            orderIndex: orderIndex
        )
        self.sensors = domain.sensors.map { SensorModel(from: $0, zone: self) }
    }

    var securityState: SecurityState {
        get {
            SecurityState(rawValue: stateRawValue) ?? .disarmed
        }
        set {
            stateRawValue = newValue.rawValue
        }
    }

    func toDomain() -> Zone {
        Zone(
            id: id,
            name: name,
            state: securityState,
            sensors: sensors.map { $0.toDomain() }
        )
    }
}
