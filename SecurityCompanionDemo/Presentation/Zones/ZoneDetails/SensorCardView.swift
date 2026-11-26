//
//  SensorCardView.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 18/11/26.
//

import SwiftUI

struct SensorCardView: View {
    let sensor: Sensor
    var showWarnings: Bool = true

    private var cardAccessibilityLabel: String {
        var label = "\(sensor.name), \(sensor.status.displayName), Battery \(sensor.batteryLevel) percent"
        if showWarnings && sensor.requiresAttention {
            label += ", Warning: \(warningMessage)"
        }
        return label
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header: Type icon, Name/Type, Status Badge
            HStack(spacing: 12) {
                // Sensor Type Icon Container
                ZStack {
                    Circle()
                        .fill(typeIconBackgroundColor)
                        .frame(width: 40, height: 40)

                    Image(systemName: sensor.type.systemImageName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(typeIconForegroundColor)
                }
                .accessibilityHidden(true)

                // Sensor Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(sensor.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(sensor.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status Badge
                statusBadge
            }

            Divider()
                .accessibilityHidden(true)

            // Battery Level & Indicator
            HStack(spacing: 8) {
                Image(systemName: batteryIconName)
                    .font(.caption)
                    .foregroundStyle(batteryColor)
                    .accessibilityHidden(true)

                // Linear Battery Level Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(uiColor: .tertiarySystemFill))
                            .frame(height: 6)

                        Capsule()
                            .fill(batteryColor)
                            .frame(
                                width: max(0, geometry.size.width * CGFloat(sensor.batteryLevel) / 100.0),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
                .accessibilityHidden(true)

                Text("\(sensor.batteryLevel)%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(batteryColor)
                    .frame(minWidth: 32, alignment: .trailing)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Battery level")
            .accessibilityValue("\(sensor.batteryLevel) percent")

            // Warning Notice if Attention Needed (Offline or Low Battery)
            if showWarnings && sensor.requiresAttention {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(warningColor)
                        .accessibilityHidden(true)

                    Text(warningMessage)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(warningColor)

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(warningColor.opacity(0.12))
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    (showWarnings && sensor.requiresAttention) ? warningColor.opacity(0.25) : Color.clear,
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cardAccessibilityLabel)
    }

    // MARK: - Visual Helpers

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusDotColor)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)

            Text(sensor.status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(statusDotColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusDotColor.opacity(0.12))
        )
    }

    private var statusDotColor: Color {
        switch sensor.status {
        case .online:
            return .green
        case .offline:
            return .red
        case .warning:
            return .orange
        }
    }

    private var batteryColor: Color {
        if sensor.batteryLevel <= 20 {
            return .red
        } else if sensor.batteryLevel <= 50 {
            return .orange
        } else {
            return .green
        }
    }

    private var batteryIconName: String {
        if sensor.batteryLevel <= 10 {
            return "battery.0percent"
        } else if sensor.batteryLevel <= 25 {
            return "battery.25percent"
        } else if sensor.batteryLevel <= 50 {
            return "battery.50percent"
        } else if sensor.batteryLevel <= 75 {
            return "battery.75percent"
        } else {
            return "battery.100percent"
        }
    }

    private var warningColor: Color {
        if sensor.status == .offline {
            return .red
        } else {
            return .orange
        }
    }

    private var warningMessage: String {
        if sensor.status == .offline && sensor.hasLowBattery {
            return "Device offline • Critical battery (\(sensor.batteryLevel)%)"
        } else if sensor.status == .offline {
            return "Device offline • Check power & network connection"
        } else if sensor.hasLowBattery {
            return "Low battery warning (\(sensor.batteryLevel)%) • Replacement recommended"
        } else {
            return "Sensor reporting warning status"
        }
    }

    private var typeIconBackgroundColor: Color {
        Color.blue.opacity(0.12)
    }

    private var typeIconForegroundColor: Color {
        Color.blue
    }
}

#Preview {
    VStack(spacing: 16) {
        SensorCardView(
            sensor: Sensor(
                name: "Front Door Contact",
                type: .doorContact,
                status: .online,
                batteryLevel: 92
            )
        )
        SensorCardView(
            sensor: Sensor(
                name: "Porch Motion Detector",
                type: .motion,
                status: .warning,
                batteryLevel: 18
            )
        )
        SensorCardView(
            sensor: Sensor(
                name: "Patio Glass Break",
                type: .glassBreak,
                status: .offline,
                batteryLevel: 0
            )
        )
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
