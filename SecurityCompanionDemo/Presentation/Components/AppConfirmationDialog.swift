//
//  AppConfirmationDialog.swift
//  SecurityCompanionDemo
//
//  Created for Mini-Project Component Library.
//

import SwiftUI

/// View modifier standardizing modal confirmation dialogs for safety-critical and destructive actions.
struct AppConfirmationDialogModifier: ViewModifier {

    let title: String
    let message: String
    let confirmTitle: String
    let confirmRole: ButtonRole?
    let cancelTitle: String
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                title,
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button(confirmTitle, role: confirmRole) {
                    onConfirm()
                }
                Button(cancelTitle, role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

extension View {
    /// Attaches a standardized, prop-driven confirmation dialog for critical operations.
    /// - Parameters:
    ///   - title: Dialog title.
    ///   - message: Detailed descriptive message explaining the consequence of the action.
    ///   - confirmTitle: Action button label (e.g. "Disarm Zone", "Sign Out").
    ///   - confirmRole: Button role (defaults to .destructive).
    ///   - cancelTitle: Cancel button label (defaults to "Cancel").
    ///   - isPresented: Binding controlling dialog visibility.
    ///   - onConfirm: Callback invoked when the user confirms the action.
    func appConfirmationDialog(
        title: String,
        message: String,
        confirmTitle: String,
        confirmRole: ButtonRole? = .destructive,
        cancelTitle: String = "Cancel",
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(
            AppConfirmationDialogModifier(
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                confirmRole: confirmRole,
                cancelTitle: cancelTitle,
                isPresented: isPresented,
                onConfirm: onConfirm
            )
        )
    }
}

// MARK: - Previews

private struct ConfirmationDialogDemoView: View {
    @State private var showingDisarm = false
    @State private var showingSignOut = false
    @State private var status = "Armed"

    var body: some View {
        VStack(spacing: 16) {
            Text("Current State: \(status)")
                .font(.headline)

            AppButton("Disarm Living Room", variant: .destructive) {
                showingDisarm = true
            }
            .appConfirmationDialog(
                title: "Confirm Disarm",
                message: "Are you sure you want to disarm Living Room? Perimeter sensors will stop triggering active alarms.",
                confirmTitle: "Disarm Zone",
                confirmRole: .destructive,
                isPresented: $showingDisarm
            ) {
                status = "Disarmed"
            }

            AppButton("Sign Out", variant: .secondary) {
                showingSignOut = true
            }
            .appConfirmationDialog(
                title: "Sign Out",
                message: "Are you sure you want to sign out? Your stored security data will remain intact.",
                confirmTitle: "Sign Out",
                confirmRole: .destructive,
                isPresented: $showingSignOut
            ) {
                status = "Signed Out"
            }
        }
        .padding()
        .background(AppTheme.Colors.screenBackground)
    }
}

#Preview("Confirmation Dialog Demo") {
    ConfirmationDialogDemoView()
}
