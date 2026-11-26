//
//  EventListView.swift
//  SecurityCompanionDemo
//

import SwiftUI

struct EventListView: View {

    @Bindable var viewModel: EventListViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Optional pull-to-refresh transient error notification banner
                if let refreshError = viewModel.refreshErrorMessage {
                    refreshErrorBanner(message: refreshError)
                }

                switch viewModel.uiState {
                case .idle, .loading:
                    loadingView
                case .empty:
                    emptyView
                case .error(let message):
                    errorView(message: message)
                case .loaded:
                    feedOverviewSection
                    simulationNoticeBanner
                    eventsTimelineSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Activity Feed")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.loadEvents(isPullToRefresh: true)
        }
        .task {
            await viewModel.loadEvents()
        }
    }

    // MARK: - Overview Summary

    private var simulationNoticeBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.blue)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text("Simulated Activity Feed")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("Demonstration events generated from mock JSONPlaceholder REST data. This feed does not reflect live physical telemetry.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
        )
    }

    private var feedOverviewSection: some View {
        HStack(spacing: 10) {
            metricTile(
                title: "Total",
                count: "\(viewModel.totalCount)",
                icon: "clock.arrow.circlepath",
                color: .primary
            )
            metricTile(
                title: "Critical",
                count: "\(viewModel.criticalCount)",
                icon: "exclamationmark.octagon.fill",
                color: viewModel.criticalCount > 0 ? .red : .secondary
            )
            metricTile(
                title: "Warnings",
                count: "\(viewModel.warningCount)",
                icon: "exclamationmark.triangle.fill",
                color: viewModel.warningCount > 0 ? .orange : .secondary
            )
            metricTile(
                title: "Info",
                count: "\(viewModel.infoCount)",
                icon: "info.circle.fill",
                color: .blue
            )
        }
    }

    private func metricTile(title: String, count: String, icon: String, color: Color) -> some View {
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

    // MARK: - Events Timeline

    private var eventsTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT EVENTS (\(viewModel.totalCount))")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            LazyVStack(spacing: 12) {
                ForEach(viewModel.events) { event in
                    EventRowView(event: event)
                }
            }
        }
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading security activity...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No Security Events")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("There are no recent security alerts or activity recorded for this system.")
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

            Text("Unable to Load Activity Feed")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    await viewModel.loadEvents()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func refreshErrorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                viewModel.dismissRefreshError()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
    }
}

#Preview {
    let repo = RemoteEventRepository()
    let useCase = GetEventsUseCase(eventRepository: repo)
    let vm = EventListViewModel(getEventsUseCase: useCase)
    return NavigationStack {
        EventListView(viewModel: vm)
    }
}
