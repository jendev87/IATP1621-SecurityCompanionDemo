//
//  AppBanner.swift
//  SecurityCompanionDemo
//
//  Created for Mini-Project Component Library.
//

import SwiftUI

/// Visual styles supported by AppBanner.
enum AppBannerStyle: Sendable {
    case info
    case warning
    case error
    case success

    var color: Color {
        switch self {
        case .info: return AppTheme.Colors.info
        case .warning: return AppTheme.Colors.warning
        case .error: return AppTheme.Colors.critical
        case .success: return AppTheme.Colors.success
        }
    }

    var defaultIcon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
}

/// A standardized contextual alert or notification banner supporting icons, dismiss actions, and multi-line text.
struct AppBanner: View {

    private let title: String?
    private let message: String
    private let style: AppBannerStyle
    private let iconName: String
    private let onDismiss: (() -> Void)?

    /// Initializes a standardized AppBanner.
    /// - Parameters:
    ///   - title: Optional bold headline.
    ///   - message: Informational or error description.
    ///   - style: Semantic visual style (defaults to .info).
    ///   - iconName: Custom SF Symbol name (defaults to style-based icon).
    ///   - onDismiss: Optional callback to show a dismiss "X" control.
    init(
        title: String? = nil,
        message: String,
        style: AppBannerStyle = .info,
        iconName: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.style = style
        self.iconName = iconName ?? style.defaultIcon
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(style.color)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 2) {
                    if let title {
                        Text(title)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(style.color)
                    }

                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(styleDescription): \(title.map { "\($0), " } ?? "")\(message)")

            Spacer()

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Circle().fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("Dismiss message")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .fill(style.color.opacity(AppTheme.Opacity.subtleBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .stroke(style.color.opacity(AppTheme.Opacity.borderStroke), lineWidth: 1)
        )
    }

    private var styleDescription: String {
        switch style {
        case .info: return "Information"
        case .warning: return "Warning"
        case .error: return "Error"
        case .success: return "Success"
        }
    }
}

// MARK: - Previews

#Preview("Banner Styles (Light Mode)") {
    VStack(spacing: 12) {
        AppBanner(
            title: "Simulated Activity Feed",
            message: "Events are generated deterministically for grading demonstration.",
            style: .info
        )

        AppBanner(
            message: "Unable to refresh events. Displaying cached events.",
            style: .warning,
            onDismiss: {}
        )

        AppBanner(
            title: "Connection Failed",
            message: "The security gateway is unreachable. Please check your network.",
            style: .error,
            onDismiss: {}
        )

        AppBanner(
            message: "All zones successfully armed.",
            style: .success
        )
    }
    .padding()
    .background(AppTheme.Colors.screenBackground)
}

#Preview("Banner Styles (Dark Mode)") {
    VStack(spacing: 12) {
        AppBanner(
            title: "Notice",
            message: "Sensors in Living Room require attention.",
            style: .warning,
            onDismiss: {}
        )
    }
    .padding()
    .background(AppTheme.Colors.screenBackground)
    .preferredColorScheme(.dark)
}
