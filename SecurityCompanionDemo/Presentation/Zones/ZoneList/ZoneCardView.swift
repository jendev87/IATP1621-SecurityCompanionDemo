//
//  ZoneCardView.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 18/11/26.
//

import SwiftUI

struct ZoneCardView: View {
    let zone: Zone
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var onToggle: (() -> Void)? = nil
    var onSelect: (() -> Void)? = nil

    private var sensorCountText: String {
        let count = zone.sensors.count
        return count == 1 ? "1 sensor" : "\(count) sensors"
    }

    private var hasOfflineSensors: Bool {
        zone.sensors.contains { $0.status == .offline }
    }

    private var hasLowBatterySensors: Bool {
        zone.sensors.contains { $0.hasLowBattery }
    }

    private var cardAccessibilityLabel: String {
        "\(zone.name), Status: \(zone.state == .armed ? "Armed" : "Disarmed"), \(sensorCountText)"
    }

    var body: some View {
        AppCard(
            borderColor: zone.state == .armed ?
                AppTheme.Colors.success.opacity(AppTheme.Opacity.borderStroke) : nil
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Top section: Primary navigation header
                Button(action: { onSelect?() }) {
                    HStack(spacing: 12) {
                        // Shield status icon container
                        ZStack {
                            Circle()
                                .fill(
                                    zone.state == .armed ?
                                        AppTheme.Colors.success.opacity(AppTheme.Opacity.mediumBackground) :
                                        AppTheme.Colors.neutral.opacity(AppTheme.Opacity.subtleBackground)
                                )
                                .frame(width: 42, height: 42)

                            Image(systemName: zone.state == .armed ? "shield.fill" : "shield.slash")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(
                                    zone.state == .armed ?
                                        AppTheme.Colors.success :
                                        AppTheme.Colors.neutral
                                )
                        }
                        .accessibilityHidden(true)

                        // Zone title and sensor count
                        VStack(alignment: .leading, spacing: 2) {
                            Text(zone.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(sensorCountText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Chevron navigation affordance
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(cardAccessibilityLabel)
                .accessibilityHint("Double tap to view zone details")

                // Bottom section: Semantic badges & Arm/Disarm Toggle
                HStack(alignment: .center, spacing: 8) {
                    AppBadge(
                        zone.state == .armed ? "ARMED" : "DISARMED",
                        iconName: zone.state == .armed ? "shield.fill" : "shield.slash",
                        style: zone.state == .armed ? .success : .neutral,
                        isSmall: true
                    )

                    if hasOfflineSensors {
                        AppBadge("OFFLINE", iconName: "exclamationmark.octagon.fill", style: .critical, isSmall: true)
                    } else if hasLowBatterySensors {
                        AppBadge("LOW BATT", iconName: "battery.25", style: .warning, isSmall: true)
                    }

                    Spacer()

                    if let onToggle {
                        AppZoneToggle(
                            isArmed: zone.state == .armed,
                            isLoading: isLoading,
                            isEnabled: isEnabled,
                            onToggle: onToggle
                        )
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    VStack(spacing: 12) {
        ZoneCardView(
            zone: Zone(
                id: UUID(),
                name: "Front Entry & Porch",
                state: .armed,
                sensors: [
                    Sensor(name: "Door Contact", type: .doorContact, status: .online, batteryLevel: 90),
                    Sensor(name: "Porch Motion", type: .motion, status: .warning, batteryLevel: 15)
                ]
            ),
            onToggle: {}
        )
        ZoneCardView(
            zone: Zone(
                id: UUID(),
                name: "Living Room",
                state: .disarmed,
                sensors: [
                    Sensor(name: "Living Motion", type: .motion, status: .online, batteryLevel: 80)
                ]
            ),
            onToggle: {}
        )
    }
    .padding()
    .background(AppTheme.Colors.screenBackground)
}
