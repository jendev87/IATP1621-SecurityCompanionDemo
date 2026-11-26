//
//  SensorType.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 18/11/26.
//

import Foundation

nonisolated enum SensorType: String, Sendable, Equatable, CaseIterable {
    case motion
    case doorContact
    case glassBreak
    case smoke
    case temperature

    var displayName: String {
        switch self {
        case .motion:
            return "Motion Detector"
        case .doorContact:
            return "Entry Contact"
        case .glassBreak:
            return "Glass Break Sensor"
        case .smoke:
            return "Smoke Detector"
        case .temperature:
            return "Temperature Sensor"
        }
    }

    var systemImageName: String {
        switch self {
        case .motion:
            return "figure.walk.motion"
        case .doorContact:
            return "door.left.hand.closed"
        case .glassBreak:
            return "waveform.path.badge.exclamationmark"
        case .smoke:
            return "smoke.fill"
        case .temperature:
            return "thermometer.medium"
        }
    }
}
