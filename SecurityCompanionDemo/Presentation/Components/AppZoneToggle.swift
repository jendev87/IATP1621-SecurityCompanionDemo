//
//  AppZoneToggle.swift
//  SecurityCompanionDemo
//
//  Created for Mini-Project Component Library.
//

import SwiftUI

/// A dedicated, prop-driven toggle control for arming and disarming security zones.
///
/// - Important: `AppZoneToggle` does not directly mutate Zone entities or repository state.
///   State ownership resides with the parent ViewModel, which enforces business rules and
///   disarm confirmation dialogs.
struct AppZoneToggle: View {

    private let isArmed: Bool
    private let isLoading: Bool
    private let isEnabled: Bool
    private let onToggle: () -> Void

    /// Initializes an AppZoneToggle control.
    /// - Parameters:
    ///   - isArmed: Current armed security state (read-only prop).
    ///   - isLoading: Whether an asynchronous arm/disarm use case is executing.
    ///   - isEnabled: Whether interaction is allowed (defaults to true).
    ///   - onToggle: Action callback invoked when the user requests a state change.
    init(
        isArmed: Bool,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        onToggle: @escaping () -> Void
    ) {
        self.isArmed = isArmed
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.onToggle = onToggle
    }

    var body: some View {
        Button(action: {
            guard isEnabled && !isLoading else { return }
            onToggle()
        }) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .font(.caption2)
                        .tint(isArmed ? AppTheme.Colors.success : AppTheme.Colors.neutral)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: isArmed ? "shield.fill" : "shield.slash")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isArmed ? AppTheme.Colors.success : AppTheme.Colors.neutral)
                }

                Text(isArmed ? "ARMED" : "DISARMED")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isArmed ? AppTheme.Colors.success : AppTheme.Colors.neutral)
                    .lineLimit(1)

                // Miniature toggle thumb indicator
                Circle()
                    .fill(isArmed ? AppTheme.Colors.success : AppTheme.Colors.neutral.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .padding(.leading, 2)
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        isArmed ?
                            AppTheme.Colors.success.opacity(AppTheme.Opacity.subtleBackground) :
                            Color(uiColor: .tertiarySystemGroupedBackground)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isArmed ?
                            AppTheme.Colors.success.opacity(AppTheme.Opacity.borderStroke) :
                            Color.secondary.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44) // Meets Apple Human Interface Guidelines minimum touch target
        .contentShape(Rectangle())
        .disabled(!isEnabled || isLoading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isArmed ? "Disarm zone" : "Arm zone")
        .accessibilityValue(isArmed ? "Armed" : "Disarmed")
        .accessibilityHint("Double tap to toggle security state")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

private struct ZoneToggleInteractiveDemo: View {
    @State private var isArmed = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Interactive Zone Toggle Demo")
                .font(.headline)

            HStack {
                Text("Living Room")
                    .font(.subheadline)
                Spacer()
                AppZoneToggle(isArmed: isArmed, isLoading: isLoading) {
                    isLoading = true
                    Task {
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        isArmed.toggle()
                        isLoading = false
                    }
                }
            }
            .padding()
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Static Variants")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Armed State:")
                    Spacer()
                    AppZoneToggle(isArmed: true) {}
                }

                HStack {
                    Text("Disarmed State:")
                    Spacer()
                    AppZoneToggle(isArmed: false) {}
                }

                HStack {
                    Text("Loading State:")
                    Spacer()
                    AppZoneToggle(isArmed: true, isLoading: true) {}
                }

                HStack {
                    Text("Disabled State:")
                    Spacer()
                    AppZoneToggle(isArmed: false, isEnabled: false) {}
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.screenBackground)
    }
}

#Preview("Zone Toggle (Light Mode)") {
    ZoneToggleInteractiveDemo()
}

#Preview("Zone Toggle (Dark Mode)") {
    ZoneToggleInteractiveDemo()
        .preferredColorScheme(.dark)
}
