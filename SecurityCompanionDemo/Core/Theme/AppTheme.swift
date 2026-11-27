//
//  AppTheme.swift
//  SecurityCompanionDemo
//
//  Created for Mini-Project Component Library.
//

import SwiftUI

/// Central design tokens and styling constants for the application.
enum AppTheme {

    // MARK: - Corner Radii

    enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let card: CGFloat = 14
        public static let large: CGFloat = 16
    }

    // MARK: - Spacing & Padding

    enum Spacing {
        public static let extraSmall: CGFloat = 4
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let cardPadding: CGFloat = 16
        public static let section: CGFloat = 20
    }

    // MARK: - Semantic Colors

    enum Colors {
        public static let success = Color.green
        public static let warning = Color.orange
        public static let critical = Color.red
        public static let info = Color.blue
        public static let neutral = Color.secondary

        public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
        public static let screenBackground = Color(uiColor: .systemGroupedBackground)
    }

    // MARK: - Opacities

    enum Opacity {
        public static let subtleBackground: Double = 0.12
        public static let mediumBackground: Double = 0.15
        public static let borderStroke: Double = 0.25
    }
}
