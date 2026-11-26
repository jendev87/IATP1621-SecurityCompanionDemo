//
//  EventSeverity.swift
//  SecurityCompanionDemo
//

import Foundation

enum EventSeverity: String, Sendable, Equatable, CaseIterable {
    case info
    case warning
    case critical

    var displayName: String {
        switch self {
        case .info:
            return "Info"
        case .warning:
            return "Warning"
        case .critical:
            return "Critical"
        }
    }
}
