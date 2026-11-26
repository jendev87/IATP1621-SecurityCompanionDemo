//
//  SecurityEventMapper.swift
//  SecurityCompanionDemo
//

import Foundation

nonisolated struct SecurityEventMapper: Sendable {

    /// Reference date anchor for deterministic demo timestamps: Nov 24, 2026 12:00:00 UTC
    static let defaultReferenceDate = Date(timeIntervalSince1970: 1795521600)

    private let referenceDate: Date

    init(referenceDate: Date = SecurityEventMapper.defaultReferenceDate) {
        self.referenceDate = referenceDate
    }

    private static let simulatedZones: [String?] = [
        "Front Entry & Porch",
        "Living Room",
        "Backyard & Patio",
        "Master Bedroom",
        "Garage",
        nil // System-wide events without zone
    ]

    private static let eventTypes: [EventType] = [
        .motionDetected,
        .doorOpened,
        .systemArmed,
        .systemDisarmed,
        .sensorOffline,
        .lowBattery
    ]

    func map(dto: PostDTO) -> SecurityEvent {
        let postID = dto.id

        // 1. Deterministic EventType selection
        let typeIndex = abs(postID) % Self.eventTypes.count
        let eventType = Self.eventTypes[typeIndex]

        // 2. Deterministic Zone selection
        // System-wide arm/disarm events are system-level without a specific zone
        let zoneName: String?
        if eventType == .systemArmed || eventType == .systemDisarmed {
            zoneName = nil
        } else {
            let zoneIndex = abs(postID) % (Self.simulatedZones.count - 1)
            zoneName = Self.simulatedZones[zoneIndex]
        }

        // 3. Deterministic Severity selection
        let severity: EventSeverity
        switch eventType {
        case .systemArmed, .systemDisarmed:
            severity = .info
        case .motionDetected, .doorOpened:
            severity = (postID % 3 == 0) ? .warning : .info
        case .lowBattery:
            severity = .warning
        case .sensorOffline:
            severity = .critical
        }

        // 4. Deterministic Title and Description (Simulated security text, not lorem ipsum)
        let (title, description) = Self.generateEventText(for: eventType, zoneName: zoneName)

        // 5. Deterministic Timestamp (Newest first when postID is lowest: 15 min intervals)
        let timeOffset = Double(postID) * 900.0 // 15 minutes spacing
        let timestamp = referenceDate.addingTimeInterval(-timeOffset)

        return SecurityEvent(
            id: "\(postID)",
            title: title,
            description: description,
            timestamp: timestamp,
            severity: severity,
            type: eventType,
            zoneName: zoneName
        )
    }

    private static func generateEventText(for type: EventType, zoneName: String?) -> (String, String) {
        switch type {
        case .motionDetected:
            let location = zoneName ?? "Monitored Zone"
            return (
                "Motion Detected",
                "Motion detector triggered in \(location)."
            )
        case .doorOpened:
            let location = zoneName ?? "Main Entry"
            return (
                "Entry Door Opened",
                "Contact sensor opened at \(location)."
            )
        case .systemArmed:
            return (
                "System Armed",
                "Security system armed successfully in Away mode."
            )
        case .systemDisarmed:
            return (
                "System Disarmed",
                "Security system disarmed by authorized user."
            )
        case .sensorOffline:
            let location = zoneName ?? "Perimeter"
            return (
                "Sensor Offline Alert",
                "Sensor in \(location) failed heartbeat and is unreachable."
            )
        case .lowBattery:
            let location = zoneName ?? "Device"
            return (
                "Low Battery Warning",
                "Sensor in \(location) reached critical battery level (< 20%)."
            )
        }
    }
}
