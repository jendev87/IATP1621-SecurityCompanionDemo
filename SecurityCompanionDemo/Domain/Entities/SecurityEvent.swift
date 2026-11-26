//
//  SecurityEvent.swift
//  SecurityCompanionDemo
//

import Foundation

nonisolated struct SecurityEvent: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let description: String
    let timestamp: Date
    let severity: EventSeverity
    let type: EventType
    let zoneName: String?

    init(
        id: String,
        title: String,
        description: String,
        timestamp: Date,
        severity: EventSeverity,
        type: EventType,
        zoneName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.severity = severity
        self.type = type
        self.zoneName = zoneName
    }
}
