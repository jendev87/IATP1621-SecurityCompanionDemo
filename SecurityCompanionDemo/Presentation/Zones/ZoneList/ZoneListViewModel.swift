//
//  ZoneListViewModel.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 18/11/26.
//

import Foundation
import Observation

enum OverallSecurityStatus: Equatable, Sendable {
    case allArmed
    case allDisarmed
    case partiallyArmed
    case noZones

    var title: String {
        switch self {
        case .allArmed:
            return "All Zones Armed"
        case .allDisarmed:
            return "All Zones Disarmed"
        case .partiallyArmed:
            return "Partially Armed"
        case .noZones:
            return "No Zones Configured"
        }
    }

    var iconName: String {
        switch self {
        case .allArmed:
            return "shield.fill"
        case .allDisarmed:
            return "shield.slash"
        case .partiallyArmed:
            return "shield.lefthalf.filled"
        case .noZones:
            return "shield"
        }
    }
}

enum ZoneListUiState: Equatable {
    case idle
    case loading
    case loaded([Zone])
    case empty
    case error(String)
}

@MainActor
@Observable
final class ZoneListViewModel {

    var uiState: ZoneListUiState = .idle
    var togglingZoneIDs: Set<UUID> = []
    var operationErrorMessage: String?

    private let getZonesUseCase: GetZonesUseCase
    private let armZoneUseCase: ArmZoneUseCase
    private let disarmZoneUseCase: DisarmZoneUseCase

    init(
        getZonesUseCase: GetZonesUseCase,
        armZoneUseCase: ArmZoneUseCase,
        disarmZoneUseCase: DisarmZoneUseCase
    ) {
        self.getZonesUseCase = getZonesUseCase
        self.armZoneUseCase = armZoneUseCase
        self.disarmZoneUseCase = disarmZoneUseCase
    }

    func isZoneLoading(_ zoneID: UUID) -> Bool {
        togglingZoneIDs.contains(zoneID)
    }

    func toggleSecurity(for zone: Zone) async {
        guard !togglingZoneIDs.contains(zone.id) else { return }

        togglingZoneIDs.insert(zone.id)
        defer { togglingZoneIDs.remove(zone.id) }

        do {
            let updatedZone: Zone
            if zone.state == .armed {
                updatedZone = try await disarmZoneUseCase.execute(zoneID: zone.id)
            } else {
                updatedZone = try await armZoneUseCase.execute(zoneID: zone.id)
            }

            if case .loaded(var currentZones) = uiState {
                if let index = currentZones.firstIndex(where: { $0.id == zone.id }) {
                    currentZones[index] = updatedZone
                    uiState = .loaded(currentZones)
                }
            }
        } catch let domainError as DomainError {
            operationErrorMessage = domainError.localizedDescription
        } catch {
            operationErrorMessage = "Unable to update the zone security state. Please try again."
        }
    }

    var zones: [Zone] {
        if case .loaded(let zones) = uiState {
            return zones
        }
        return []
    }

    var totalCount: Int {
        zones.count
    }

    var armedCount: Int {
        zones.filter { $0.state == .armed }.count
    }

    var disarmedCount: Int {
        zones.filter { $0.state == .disarmed }.count
    }

    var overallStatus: OverallSecurityStatus {
        guard !zones.isEmpty else { return .noZones }
        if armedCount == zones.count {
            return .allArmed
        } else if armedCount == 0 {
            return .allDisarmed
        } else {
            return .partiallyArmed
        }
    }

    func loadZones() async {
        if zones.isEmpty {
            uiState = .loading
        }

        do {
            let fetchedZones = try await getZonesUseCase.execute()
            if fetchedZones.isEmpty {
                uiState = .empty
            } else {
                uiState = .loaded(fetchedZones)
            }
        } catch {
            uiState = .error("Unable to load security zones. Please check your connection and try again.")
        }
    }
}
