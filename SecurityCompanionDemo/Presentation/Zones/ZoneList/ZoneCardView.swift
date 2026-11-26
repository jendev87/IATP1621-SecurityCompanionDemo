//
//  ZoneCardView.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 18/11/26.
//

import SwiftUI

struct ZoneCardView: View {
    let zone: Zone

    private var sensorCountText: String {
        let count = zone.sensors.count
        return count == 1 ? "1 sensor" : "\(count) sensors"
    }

    private var cardAccessibilityLabel: String {
        "\(zone.name), Status: \(zone.state == .armed ? "Armed" : "Disarmed"), \(sensorCountText)"
    }

    var body: some View {
        HStack(spacing: 16) {
            // Shield status icon container
            ZStack {
                Circle()
                    .fill(zone.state == .armed ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12))
                    .frame(width: 46, height: 46)

                Image(systemName: zone.state == .armed ? "shield.fill" : "shield.slash")
                    .font(.system(size: 22))
                    .foregroundStyle(zone.state == .armed ? Color.green : Color.secondary)
            }
            .accessibilityHidden(true)

            // Zone details
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(zone.state == .armed ? Color.green : Color.secondary)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)

                    Text(zone.state == .armed ? "Armed" : "Disarmed")
                        .font(.subheadline)
                        .foregroundStyle(zone.state == .armed ? Color.green : Color.secondary)
                }
            }

            Spacer()

            // Navigation Chevron Affordance
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    zone.state == .armed ? Color.green.opacity(0.25) : Color.clear,
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cardAccessibilityLabel)
        .accessibilityHint("Double tap to view zone details")
    }
}

#Preview {
    VStack(spacing: 12) {
        ZoneCardView(zone: Zone(id: UUID(), name: "Front Entry & Porch", state: .armed))
        ZoneCardView(zone: Zone(id: UUID(), name: "Living Room", state: .disarmed))
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
