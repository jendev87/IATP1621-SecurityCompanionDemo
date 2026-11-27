//
//  ZoneListView.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 18/11/26.
//

import SwiftUI

struct ZoneListView: View {

    @Bindable var viewModel: ZoneListViewModel
    let container: AppContainer

    @State private var selectedZone: Zone?
    @State private var isNavigatingToDetail: Bool = false
    @State private var zoneToDisarm: Zone?
    @State private var showingDisarmConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let errorMessage = viewModel.operationErrorMessage {
                        AppBanner(
                            message: errorMessage,
                            style: .error,
                            onDismiss: {
                                viewModel.operationErrorMessage = nil
                            }
                        )
                    }

                    switch viewModel.uiState {
                    case .idle, .loading:
                        loadingView
                    case .empty:
                        emptyView
                    case .error(let message):
                        errorView(message: message)
                    case .loaded:
                        securityOverviewSection
                        activityFeedLinkSection
                        settingsLinkSection
                        zoneListSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Security Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $isNavigatingToDetail) {
                if let zone = selectedZone {
                    ZoneDetailView(
                        viewModel: container.makeZoneDetailViewModel(zone: zone)
                    )
                }
            }
            .appConfirmationDialog(
                title: "Disarm Zone",
                message: "Are you sure you want to disarm \(zoneToDisarm?.name ?? "this zone")?",
                confirmTitle: "Disarm Zone",
                confirmRole: .destructive,
                isPresented: $showingDisarmConfirmation
            ) {
                if let zone = zoneToDisarm {
                    Task {
                        await viewModel.toggleSecurity(for: zone)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink {
                            EventListView(viewModel: container.makeEventListViewModel())
                        } label: {
                            Image(systemName: "bell.badge")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .accessibilityLabel("Activity Feed")

                        NavigationLink {
                            SettingsView(viewModel: container.makeSettingsViewModel())
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .accessibilityLabel("Settings")
                    }
                }
            }
            .refreshable {
                await viewModel.loadZones()
            }
            .task {
                await container.ensureDataSeeded()
                await viewModel.loadZones()
            }
        }
    }

    // MARK: - Security Overview Section

    private var securityOverviewSection: some View {
        VStack(spacing: 16) {
            // Main Status Banner
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: viewModel.overallStatus.iconName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(statusColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.overallStatus.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("\(viewModel.armedCount) of \(viewModel.totalCount) zones actively monitored")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            // Metric Counters
            HStack(spacing: 12) {
                metricCard(
                    title: "Total",
                    value: "\(viewModel.totalCount)",
                    systemImage: "square.grid.2x2",
                    color: .primary
                )

                metricCard(
                    title: "Armed",
                    value: "\(viewModel.armedCount)",
                    systemImage: "shield.fill",
                    color: .green
                )

                metricCard(
                    title: "Disarmed",
                    value: "\(viewModel.disarmedCount)",
                    systemImage: "shield.slash",
                    color: .secondary
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Activity Feed Quick Access Link

    private var activityFeedLinkSection: some View {
        NavigationLink {
            EventListView(viewModel: container.makeEventListViewModel())
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 42, height: 42)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Security Activity Feed")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("View live timeline & security alerts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings Quick Access Link

    private var settingsLinkSection: some View {
        NavigationLink {
            SettingsView(viewModel: container.makeSettingsViewModel())
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("System Settings")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("Preferences, account & security rules")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private func metricCard(title: String, value: String, systemImage: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        )
    }

    private var statusColor: Color {
        switch viewModel.overallStatus {
        case .allArmed:
            return .green
        case .partiallyArmed:
            return .orange
        case .allDisarmed:
            return .secondary
        case .noZones:
            return .gray
        }
    }

    // MARK: - Zones List Section

    private var zoneListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MONITORED ZONES (\(viewModel.totalCount))")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
                .padding(.top, 8)

            LazyVStack(spacing: 12) {
                ForEach(viewModel.zones) { zone in
                    ZoneCardView(
                        zone: zone,
                        isLoading: viewModel.isZoneLoading(zone.id),
                        onToggle: {
                            handleToggle(for: zone)
                        },
                        onSelect: {
                            selectedZone = zone
                            isNavigatingToDetail = true
                        }
                    )
                }
            }
        }
    }

    private func handleToggle(for zone: Zone) {
        if zone.state == .armed && container.preferences.requireDisarmConfirmation {
            zoneToDisarm = zone
            showingDisarmConfirmation = true
        } else {
            Task {
                await viewModel.toggleSecurity(for: zone)
            }
        }
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading security status...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No Zones Configured")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("There are currently no security zones configured for this system.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Unable to Load Zones")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            AppButton(
                "Try Again",
                iconName: "arrow.clockwise",
                variant: .primary,
                isFullWidth: false
            ) {
                Task {
                    await viewModel.loadZones()
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

#Preview {
    let container = AppContainer()
    let viewModel = container.makeZoneListViewModel()
    return ZoneListView(viewModel: viewModel, container: container)
}
