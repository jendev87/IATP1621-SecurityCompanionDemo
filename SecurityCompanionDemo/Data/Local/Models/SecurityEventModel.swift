//
//  SecurityEventModel.swift
//  SecurityCompanionDemo
//

import Foundation
import SwiftData

@Model
final class SecurityEventModel {
    @Attribute(.unique) var id: String
    var title: String
    var eventDescription: String
    var timestamp: Date
    var severityRawValue: String
    var typeRawValue: String
    var zoneName: String?

    init(
        id: String,
        title: String,
        eventDescription: String,
        timestamp: Date,
        severityRawValue: String,
        typeRawValue: String,
        zoneName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.timestamp = timestamp
        self.severityRawValue = severityRawValue
        self.typeRawValue = typeRawValue
        self.zoneName = zoneName
    }

    convenience init(from domain: SecurityEvent) {
        self.init(
            id: domain.id,
            title: domain.title,
            eventDescription: domain.description,
            timestamp: domain.timestamp,
            severityRawValue: domain.severity.rawValue,
            typeRawValue: domain.type.rawValue,
            zoneName: domain.zoneName
        )
    }

    var severity: EventSeverity {
        EventSeverity(rawValue: severityRawValue) ?? .info
    }

    var eventType: EventType {
        EventType(rawValue: typeRawValue) ?? .motionDetected
    }

    func toDomain() -> SecurityEvent {
        SecurityEvent(
            id: id,
            title: title,
            description: eventDescription,
            timestamp: timestamp,
            severity: severity,
            type: eventType,
            zoneName: zoneName
        )
    }
}
