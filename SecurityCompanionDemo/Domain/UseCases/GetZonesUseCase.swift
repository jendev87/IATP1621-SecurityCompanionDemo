//
//  GetZonesUseCase.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 18/11/26.
//

import Foundation

struct GetZonesUseCase: Sendable {
    private let zoneRepository: ZoneRepository

    init(zoneRepository: ZoneRepository) {
        self.zoneRepository = zoneRepository
    }

    func execute() async throws -> [Zone] {
        try await zoneRepository.fetchZones()
    }
}
