//
//  AppCard.swift
//  SecurityCompanionDemo
//
//  Created for Mini-Project Component Library.
//

import SwiftUI

/// A reusable surface container that provides consistent styling, padding, and elevation across the application.
struct AppCard<Content: View>: View {

    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let borderColor: Color?
    private let content: Content

    /// Initializes an AppCard with sensible defaults and ViewBuilder composition.
    /// - Parameters:
    ///   - padding: Inner padding around the content (defaults to standard card padding).
    ///   - cornerRadius: Continuous corner radius (defaults to standard card radius).
    ///   - borderColor: Optional accent border stroke (e.g. For highlighting armed or critical states).
    ///   - content: ViewBuilder closure yielding the card content.
    init(
        padding: CGFloat = AppTheme.Spacing.cardPadding,
        cornerRadius: CGFloat = AppTheme.CornerRadius.card,
        borderColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? 1 : 0)
            )
    }
}

// MARK: - Previews

#Preview("Card Variants (Light Mode)") {
    ScrollView {
        VStack(spacing: 16) {
            AppCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Standard Surface Card")
                            .font(.headline)
                        Text("Sensible default styling with standard background.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            AppCard(borderColor: AppTheme.Colors.success.opacity(AppTheme.Opacity.borderStroke)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Armed Status Border")
                            .font(.headline)
                            .foregroundStyle(AppTheme.Colors.success)
                        Text("Subtle green border indicating an active security state.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "shield.fill")
                        .foregroundStyle(AppTheme.Colors.success)
                }
            }

            AppCard(borderColor: AppTheme.Colors.critical.opacity(AppTheme.Opacity.borderStroke)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Critical Alert Border")
                            .font(.headline)
                            .foregroundStyle(AppTheme.Colors.critical)
                        Text("Subtle red border highlighting a system warning.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppTheme.Colors.critical)
                }
            }
        }
        .padding()
    }
    .background(AppTheme.Colors.screenBackground)
}

#Preview("Card Variants (Dark Mode)") {
    VStack(spacing: 16) {
        AppCard {
            Text("Dark Appearance Card")
                .font(.headline)
        }

        AppCard(borderColor: AppTheme.Colors.info.opacity(0.4)) {
            Text("Dark Appearance with Accent Border")
                .font(.headline)
                .foregroundStyle(AppTheme.Colors.info)
        }
    }
    .padding()
    .background(AppTheme.Colors.screenBackground)
    .preferredColorScheme(.dark)
}
