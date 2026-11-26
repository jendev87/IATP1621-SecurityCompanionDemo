//
//  ZoneRepository.swift
//  SecurityCompanionDemo
//
import Foundation

nonisolated protocol ZoneRepository: Sendable {
    func fetchZones() async throws -> [Zone]
    func updateZone(_ zone: Zone) async throws
    func fetchZone(id: UUID) async throws -> Zone?
}
