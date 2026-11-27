//
//  AppButton.swift
//  SecurityCompanionDemo
//
//  Created for Mini-Project Component Library.
//

import SwiftUI

/// Visual variants supported by AppButton.
enum AppButtonVariant: Sendable {
    case primary     // Blue prominent fill
    case secondary   // Tinted subtle fill
    case destructive // Red prominent fill (e.g. Disarm, Sign Out)
    case ghost       // Borderless text button
}

/// A standardized action button component supporting multiple variants, loading states, and full-width sizing.
struct AppButton: View {

    private let title: String
    private let iconName: String?
    private let variant: AppButtonVariant
    private let isLoading: Bool
    private let isEnabled: Bool
    private let isFullWidth: Bool
    private let cornerRadius: CGFloat
    private let action: () -> Void

    /// Initializes a standardized AppButton.
    /// - Parameters:
    ///   - title: Button label text.
    ///   - iconName: Optional leading SF Symbol name.
    ///   - variant: Button visual style (defaults to .primary).
    ///   - isLoading: Whether to show a ProgressView spinner (defaults to false).
    ///   - isEnabled: Whether user interaction is allowed (defaults to true).
    ///   - isFullWidth: Whether the button expands to fill available horizontal width (defaults to true).
    ///   - cornerRadius: Corner radius for the button surface (defaults to AppTheme.CornerRadius.small, 8pt).
    ///   - action: Action callback invoked on tap.
    init(
        _ title: String,
        iconName: String? = nil,
        variant: AppButtonVariant = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        isFullWidth: Bool = true,
        cornerRadius: CGFloat = AppTheme.CornerRadius.small,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.variant = variant
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.isFullWidth = isFullWidth
        self.cornerRadius = cornerRadius
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard isEnabled && !isLoading else { return }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .semibold))
                }

                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(minHeight: 44) // Meets Apple Human Interface Guidelines minimum touch target
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Styling Helpers

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .primary
        case .ghost:
            return AppTheme.Colors.info
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            AppTheme.Colors.info
        case .destructive:
            AppTheme.Colors.critical
        case .secondary:
            Color(uiColor: .tertiarySystemGroupedBackground)
        case .ghost:
            Color.clear
        }
    }
}

// MARK: - Previews

#Preview("Button Variants (Light Mode)") {
    VStack(spacing: 14) {
        AppButton("Primary Button", iconName: "lock.shield.fill", variant: .primary) {}

        AppButton("Destructive Button", iconName: "shield.slash.fill", variant: .destructive) {}

        AppButton("Secondary Action", iconName: "arrow.clockwise", variant: .secondary) {}

        AppButton("Ghost Action", iconName: "chevron.right", variant: .ghost, isFullWidth: false) {}

        AppButton("Loading State", variant: .primary, isLoading: true) {}

        AppButton("Disabled Button", variant: .primary, isEnabled: false) {}
    }
    .padding()
    .background(AppTheme.Colors.screenBackground)
}

#Preview("Button Variants (Dark Mode)") {
    VStack(spacing: 14) {
        AppButton("Arm All Zones", iconName: "shield.fill", variant: .primary) {}
        AppButton("Disarm Zone", iconName: "shield.slash", variant: .destructive) {}
        AppButton("Cancel", variant: .secondary) {}
    }
    .padding()
    .background(AppTheme.Colors.screenBackground)
    .preferredColorScheme(.dark)
}
