//
//  Zone.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 10/11/26.
//

import Foundation

nonisolated struct Zone: Identifiable, Sendable, Equatable {
    let id: UUID
    var name: String
    var state: SecurityState
    var sensors: [Sensor]

    init(
        id: UUID,
        name: String,
        state: SecurityState,
        sensors: [Sensor] = []
    ) {
        self.id = id
        self.name = name
        self.state = state
        self.sensors = sensors
    }
}
