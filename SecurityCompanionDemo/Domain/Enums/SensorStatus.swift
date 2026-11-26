//
//  SensorStatus.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 18/11/26.
//

import Foundation

nonisolated enum SensorStatus: String, Sendable, Equatable, CaseIterable {
    case online
    case offline
    case warning

    var displayName: String {
        switch self {
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        case .warning:
            return "Warning"
        }
    }
}
