//
//  EventRowView.swift
//  SecurityCompanionDemo
//

import SwiftUI

struct EventRowView: View {
    let event: SecurityEvent

    private var accessibilitySummary: String {
        if let zoneName = event.zoneName {
            return "\(event.title), \(zoneName), \(event.severity.displayName)"
        } else {
            return "\(event.title), \(event.severity.displayName)"
        }
    }

    private var accessibilityDetails: String {
        "\(event.description), \(event.timestamp.formatted(date: .abbreviated, time: .shortened))"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Severity & Type Icon
            ZStack {
                Circle()
                    .fill(severityBackgroundColor)
                    .frame(width: 44, height: 44)

                Image(systemName: event.type.systemImageName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(severityColor)
            }
            .accessibilityHidden(true)

            // Event Details
            VStack(alignment: .leading, spacing: 6) {
                // Top row: Title + Severity Badge
                HStack(alignment: .center, spacing: 8) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    severityBadge
                }

                // Description
                Text(event.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Bottom row: Associated Zone (if present) & Formatted Timestamp
                HStack(spacing: 8) {
                    if let zoneName = event.zoneName {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.caption2)
                                .accessibilityHidden(true)
                            Text(zoneName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                        )
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }
                .padding(.top, 2)
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
                    event.severity == .critical ? Color.red.opacity(0.3) :
                        event.severity == .warning ? Color.orange.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityValue(accessibilityDetails)
    }

    // MARK: - Visual Helpers

    private var severityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(severityColor)
                .frame(width: 5, height: 5)
                .accessibilityHidden(true)

            Text(event.severity.displayName.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(severityColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(severityBackgroundColor)
        )
    }

    private var severityColor: Color {
        switch event.severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }

    private var severityBackgroundColor: Color {
        severityColor.opacity(0.12)
    }
}

#Preview {
    VStack(spacing: 12) {
        EventRowView(
            event: SecurityEvent(
                id: "1",
                title: "Sensor Offline Alert",
                description: "Sensor in Living Room failed heartbeat and is unreachable.",
                timestamp: Date(),
                severity: .critical,
                type: .sensorOffline,
                zoneName: "Living Room"
            )
        )
        EventRowView(
            event: SecurityEvent(
                id: "2",
                title: "Low Battery Warning",
                description: "Sensor in Front Entry reached critical battery level (< 20%).",
                timestamp: Date().addingTimeInterval(-1800),
                severity: .warning,
                type: .lowBattery,
                zoneName: "Front Entry & Porch"
            )
        )
        EventRowView(
            event: SecurityEvent(
                id: "3",
                title: "System Armed",
                description: "Security system armed successfully in Away mode.",
                timestamp: Date().addingTimeInterval(-3600),
                severity: .info,
                type: .systemArmed,
                zoneName: nil
            )
        )
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
