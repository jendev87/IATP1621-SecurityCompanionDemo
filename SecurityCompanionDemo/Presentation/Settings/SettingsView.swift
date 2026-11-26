//
//  SettingsView.swift
//  SecurityCompanionDemo
//

import SwiftUI

struct SettingsView: View {

    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            // MARK: - Account Section
            accountSection

            // MARK: - Notification Preferences
            notificationSection

            // MARK: - Security Preferences
            securitySection

            // MARK: - About Section
            aboutSection

            // MARK: - Sign Out Section
            signOutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Sign Out",
            isPresented: $viewModel.showingSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? Your stored security data and preferences will remain intact.")
        }
    }

    // MARK: - Subsections

    private var accountSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.account.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(viewModel.account.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            LabeledContent("Account Role", value: viewModel.account.role)
            LabeledContent("Monitored Property", value: viewModel.account.propertyName)
        } header: {
            Text("Account")
        } footer: {
            Text("Logged in using simulated credential session.")
        }
    }

    private var notificationSection: some View {
        Section {
            Toggle(
                "Security Event Alerts",
                isOn: $viewModel.preferences.securityEventAlerts
            )

            Toggle(
                "Sensor Health Alerts",
                isOn: $viewModel.preferences.sensorHealthAlerts
            )
        } header: {
            Text("Notification Preferences")
        } footer: {
            Text("Preferences are stored locally on this device.")
        }
    }

    private var securitySection: some View {
        Section {
            Toggle(
                "Require Confirmation to Disarm",
                isOn: $viewModel.preferences.requireDisarmConfirmation
            )

            Toggle(
                "Show Sensor Health Warnings",
                isOn: $viewModel.preferences.showSensorWarnings
            )
        } header: {
            Text("Security Preferences")
        } footer: {
            Text("Confirmation prevents accidental disarming. Sensor warnings highlight low battery and offline devices.")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Application", value: viewModel.appName)
            LabeledContent("Version", value: "\(viewModel.appVersion) (\(viewModel.buildNumber))")
            LabeledContent("Platform", value: viewModel.platformInfo)

            VStack(alignment: .leading, spacing: 6) {
                Text("About")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(viewModel.appDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("About")
        }
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.showingSignOutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Sign Out")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel())
    }
}
