//
//  ZoneDetailView.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 10/11/26.
//

import SwiftUI

struct ZoneDetailView: View {

    @Bindable var viewModel: ZoneDetailViewModel
    @Bindable var preferences: UserPreferences = .shared
    @State private var showingDisarmConfirmation: Bool = false

    init(viewModel: ZoneDetailViewModel, preferences: UserPreferences? = nil) {
        self.viewModel = viewModel
        self.preferences = preferences ?? .shared
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Security Status & Action Card
                securityControlCard

                // MARK: - Sensor Overview Summary
                if viewModel.hasSensors {
                    sensorOverviewSection
                }

                // MARK: - Sensors List
                sensorListSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(viewModel.zone.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Security Control Card

    private var securityControlCard: some View {
        VStack(spacing: 16) {
            // Shield & Status
            VStack(spacing: 8) {
                Image(systemName: viewModel.zone.state == .armed ? "shield.fill" : "shield.slash")
                    .font(.system(size: 56))
                    .foregroundStyle(viewModel.zone.state == .armed ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)

                Text(viewModel.statusText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(viewModel.zone.state == .armed ? .green : .secondary)

                Text(viewModel.zone.state == .armed ? "Zone actively armed & monitored" : "Zone disarmed • System safe")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 6)

            // Arm / Disarm Action Button
            AppButton(
                viewModel.zone.state == .armed ? "Disarm Zone" : "Arm Zone",
                iconName: viewModel.zone.state == .armed ? "shield.slash.fill" : "lock.shield.fill",
                variant: viewModel.zone.state == .armed ? .destructive : .primary,
                isLoading: viewModel.isLoading,
                isEnabled: !viewModel.isLoading
            ) {
                if viewModel.zone.state == .armed && preferences.requireDisarmConfirmation {
                    showingDisarmConfirmation = true
                } else {
                    Task {
                        await viewModel.toggleSecurity()
                    }
                }
            }
            .appConfirmationDialog(
                title: "Disarm Zone",
                message: "Are you sure you want to disarm \(viewModel.zone.name)?",
                confirmTitle: "Disarm Zone",
                confirmRole: .destructive,
                isPresented: $showingDisarmConfirmation
            ) {
                Task {
                    await viewModel.toggleSecurity()
                }
            }

            // Inline Loading Message
            if viewModel.isLoading {
                ProgressView("Updating zone state...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Error Message Banner
            if case .error(let message) = viewModel.operationState {
                AppBanner(
                    message: message,
                    style: .error,
                    iconName: "exclamationmark.triangle.fill"
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - Sensor Overview Section

    private var sensorOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SENSOR HEALTH OVERVIEW")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            // Metric Counters Grid
            HStack(spacing: 10) {
                sensorMetricTile(
                    title: "Total",
                    count: "\(viewModel.totalSensorsCount)",
                    color: .primary,
                    icon: "square.grid.2x2"
                )

                sensorMetricTile(
                    title: "Online",
                    count: "\(viewModel.onlineSensorsCount)",
                    color: .green,
                    icon: "antenna.radiowaves.left.and.right"
                )

                sensorMetricTile(
                    title: "Offline",
                    count: "\(viewModel.offlineSensorsCount)",
                    color: viewModel.offlineSensorsCount > 0 ? .red : .secondary,
                    icon: "wifi.slash"
                )

                sensorMetricTile(
                    title: "Attention",
                    count: "\(viewModel.attentionSensorsCount)",
                    color: viewModel.hasAttentionSensors ? .orange : .secondary,
                    icon: "exclamationmark.circle"
                )
            }
        }
    }

    private func sensorMetricTile(title: String, count: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)

            Text(count)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - Sensor List Section

    private var sensorListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MONITORED SENSORS (\(viewModel.totalSensorsCount))")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            if viewModel.sensors.isEmpty {
                emptySensorsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.sensors) { sensor in
                        SensorCardView(
                            sensor: sensor,
                            showWarnings: preferences.showSensorWarnings
                        )
                    }
                }
            }
        }
    }

    private var emptySensorsView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "sensor.tag.radiowaves.forward")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("No Sensors Connected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

#Preview("Living Room (Disarmed with Warning & Offline)") {
    let container = AppContainer()
    let zone = AppContainer.sampleZones[1] // Living Room
    let viewModel = container.makeZoneDetailViewModel(zone: zone)
    return NavigationStack {
        ZoneDetailView(viewModel: viewModel)
    }
}

#Preview("Front Entry (Armed with Low Battery)") {
    let container = AppContainer()
    let zone = AppContainer.sampleZones[0] // Front Entry
    let viewModel = container.makeZoneDetailViewModel(zone: zone)
    return NavigationStack {
        ZoneDetailView(viewModel: viewModel)
    }
}
