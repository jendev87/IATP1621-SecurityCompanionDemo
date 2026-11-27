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

    private var borderColor: Color? {
        switch event.severity {
        case .critical:
            return AppTheme.Colors.critical.opacity(AppTheme.Opacity.borderStroke)
        case .warning:
            return AppTheme.Colors.warning.opacity(0.2)
        case .info:
            return nil
        }
    }

    private var severityColor: Color {
        switch event.severity {
        case .info:
            return AppTheme.Colors.info
        case .warning:
            return AppTheme.Colors.warning
        case .critical:
            return AppTheme.Colors.critical
        }
    }

    private var badgeStyle: AppBadgeStyle {
        switch event.severity {
        case .info:
            return .info
        case .warning:
            return .warning
        case .critical:
            return .critical
        }
    }

    var body: some View {
        AppCard(
            padding: 14,
            borderColor: borderColor
        ) {
            HStack(alignment: .top, spacing: 14) {
                // Severity & Type Icon
                ZStack {
                    Circle()
                        .fill(severityColor.opacity(AppTheme.Opacity.subtleBackground))
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

                        AppBadge(
                            event.severity.displayName.uppercased(),
                            style: badgeStyle,
                            isSmall: true,
                            showDot: true
                        )
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
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityValue(accessibilityDetails)
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
    .background(AppTheme.Colors.screenBackground)
}
