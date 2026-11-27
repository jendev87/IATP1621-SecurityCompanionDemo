//
//  AppBadge.swift
//  SecurityCompanionDemo
//
//  Created for Mini-Project Component Library.
//

import SwiftUI

/// Semantic styles supported by AppBadge.
enum AppBadgeStyle: Sendable {
    case success     // Green (e.g. Armed, Online)
    case warning     // Orange (e.g. Low Battery, Sensor Warning)
    case critical    // Red (e.g. Disarmed alert, Sensor Offline)
    case neutral     // Secondary (e.g. Disarmed neutral, Bypassed)
    case info        // Blue (e.g. Info event, System status)

    var color: Color {
        switch self {
        case .success: return AppTheme.Colors.success
        case .warning: return AppTheme.Colors.warning
        case .critical: return AppTheme.Colors.critical
        case .neutral: return AppTheme.Colors.neutral
        case .info: return AppTheme.Colors.info
        }
    }

    var defaultIcon: String? {
        switch self {
        case .success: return "shield.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        case .neutral: return "shield.slash"
        case .info: return "info.circle.fill"
        }
    }
}

/// A standardized, prop-driven semantic badge component for displaying security states and event severities.
struct AppBadge: View {

    private let text: String
    private let iconName: String?
    private let style: AppBadgeStyle
    private let isSmall: Bool
    private let showDot: Bool

    /// Initializes a semantic AppBadge.
    /// - Parameters:
    ///   - text: Label text to display.
    ///   - iconName: Optional SF Symbol icon name.
    ///   - style: Semantic visual style (defaults to neutral).
    ///   - isSmall: Whether to render in compact size (defaults to false).
    ///   - showDot: Whether to show a colored leading dot indicator (defaults to false if an icon is supplied).
    init(
        _ text: String,
        iconName: String? = nil,
        style: AppBadgeStyle = .neutral,
        isSmall: Bool = false,
        showDot: Bool = false
    ) {
        self.text = text
        self.iconName = iconName
        self.style = style
        self.isSmall = isSmall
        self.showDot = showDot && iconName == nil
    }

    var body: some View {
        HStack(spacing: isSmall ? 3 : 5) {
            if let iconName {
                Image(systemName: iconName)
                    .font(isSmall ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                    .foregroundStyle(style.color)
            } else if showDot {
                Circle()
                    .fill(style.color)
                    .frame(width: isSmall ? 4 : 6, height: isSmall ? 4 : 6)
            }

            Text(text)
                .font(isSmall ? .caption2.weight(.bold) : .caption.weight(.semibold))
                .foregroundStyle(style.color)
                .lineLimit(1)
        }
        .padding(.horizontal, isSmall ? 6 : 9)
        .padding(.vertical, isSmall ? 2 : 4)
        .background(
            Capsule()
                .fill(style.color.opacity(AppTheme.Opacity.subtleBackground))
        )
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(text) status")
    }
}

// MARK: - Previews

#Preview("Badge Styles (Light Mode)") {
    VStack(spacing: 16) {
        HStack(spacing: 10) {
            AppBadge("ARMED", iconName: "shield.fill", style: .success)
            AppBadge("DISARMED", iconName: "shield.slash", style: .neutral)
            AppBadge("WARNING", iconName: "exclamationmark.triangle.fill", style: .warning)
        }

        HStack(spacing: 10) {
            AppBadge("CRITICAL", iconName: "exclamationmark.octagon.fill", style: .critical)
            AppBadge("ONLINE", style: .success, showDot: true)
            AppBadge("OFFLINE", style: .critical, showDot: true)
        }

        HStack(spacing: 10) {
            AppBadge("INFO", style: .info, isSmall: true, showDot: true)
            AppBadge("LOW BATT", iconName: "battery.25", style: .warning, isSmall: true)
            AppBadge("SYSTEM", iconName: "gearshape", style: .info, isSmall: true)
        }
    }
    .padding()
    .background(AppTheme.Colors.screenBackground)
}

#Preview("Badge Styles (Dark Mode)") {
    HStack(spacing: 10) {
        AppBadge("Armed", iconName: "shield.fill", style: .success)
        AppBadge("Warning", iconName: "exclamationmark.triangle.fill", style: .warning)
        AppBadge("Critical", iconName: "exclamationmark.octagon.fill", style: .critical)
    }
    .padding()
    .background(AppTheme.Colors.screenBackground)
    .preferredColorScheme(.dark)
}
