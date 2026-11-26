//
//  SettingsViewModel.swift
//  SecurityCompanionDemo
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {

    var session: AuthSessionManager
    var preferences: UserPreferences
    var showingSignOutConfirmation: Bool = false

    init(
        session: AuthSessionManager,
        preferences: UserPreferences
    ) {
        self.session = session
        self.preferences = preferences
    }

    convenience init() {
        self.init(
            session: AuthSessionManager.shared,
            preferences: UserPreferences.shared
        )
    }

    var account: MockAccount {
        session.currentUser
    }

    var appName: String {
        "Security Monitoring Companion"
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var platformInfo: String {
        "iOS 17.0+ • Apple Platform"
    }

    var appDescription: String {
        "A reliable companion for real-time security zone control, sensor telemetry monitoring, and automated activity event logging."
    }

    func signOut() {
        session.signOut()
    }
}
