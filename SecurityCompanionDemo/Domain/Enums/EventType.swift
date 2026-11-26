//
//  EventType.swift
//  SecurityCompanionDemo
//

import Foundation

enum EventType: String, Sendable, Equatable, CaseIterable {
    case motionDetected
    case doorOpened
    case systemArmed
    case systemDisarmed
    case sensorOffline
    case lowBattery

    var displayName: String {
        switch self {
        case .motionDetected:
            return "Motion Detected"
        case .doorOpened:
            return "Door Opened"
        case .systemArmed:
            return "System Armed"
        case .systemDisarmed:
            return "System Disarmed"
        case .sensorOffline:
            return "Sensor Offline"
        case .lowBattery:
            return "Low Battery"
        }
    }

    var systemImageName: String {
        switch self {
        case .motionDetected:
            return "figure.walk.motion"
        case .doorOpened:
            return "door.left.hand.open"
        case .systemArmed:
            return "shield.fill"
        case .systemDisarmed:
            return "shield.slash"
        case .sensorOffline:
            return "wifi.slash"
        case .lowBattery:
            return "battery.25percent"
        }
    }
}
