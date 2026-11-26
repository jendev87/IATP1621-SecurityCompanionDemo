//
//  Sensor.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 18/11/26.
//

import Foundation

nonisolated struct Sensor: Identifiable, Sendable, Equatable {
    let id: UUID
    var name: String
    var type: SensorType
    var status: SensorStatus
    var batteryLevel: Int // 0 - 100

    init(
        id: UUID = UUID(),
        name: String,
        type: SensorType,
        status: SensorStatus = .online,
        batteryLevel: Int = 100
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.batteryLevel = max(0, min(100, batteryLevel))
    }

    /// Battery is considered low when at or below 20%.
    var hasLowBattery: Bool {
        batteryLevel <= 20
    }

    /// Sensor requires attention if offline, warning, or low battery.
    var requiresAttention: Bool {
        status == .offline || status == .warning || hasLowBattery
    }
}
