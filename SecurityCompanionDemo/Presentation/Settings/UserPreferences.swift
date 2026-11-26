//
//  UserPreferences.swift
//  SecurityCompanionDemo
//

import Foundation
import Observation

enum UserPreferenceKeys {
    static let securityEventAlerts = "pref_security_event_alerts"
    static let sensorHealthAlerts = "pref_sensor_health_alerts"
    static let requireDisarmConfirmation = "pref_require_disarm_confirmation"
    static let showSensorWarnings = "pref_show_sensor_warnings"
}

@MainActor
@Observable
final class UserPreferences {

    static let shared = UserPreferences()

    private let defaults: UserDefaults

    var securityEventAlerts: Bool {
        didSet {
            defaults.set(securityEventAlerts, forKey: UserPreferenceKeys.securityEventAlerts)
        }
    }

    var sensorHealthAlerts: Bool {
        didSet {
            defaults.set(sensorHealthAlerts, forKey: UserPreferenceKeys.sensorHealthAlerts)
        }
    }

    var requireDisarmConfirmation: Bool {
        didSet {
            defaults.set(requireDisarmConfirmation, forKey: UserPreferenceKeys.requireDisarmConfirmation)
        }
    }

    var showSensorWarnings: Bool {
        didSet {
            defaults.set(showSensorWarnings, forKey: UserPreferenceKeys.showSensorWarnings)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Sensible default values
        defaults.register(defaults: [
            UserPreferenceKeys.securityEventAlerts: true,
            UserPreferenceKeys.sensorHealthAlerts: true,
            UserPreferenceKeys.requireDisarmConfirmation: true,
            UserPreferenceKeys.showSensorWarnings: true
        ])

        self.securityEventAlerts = defaults.bool(forKey: UserPreferenceKeys.securityEventAlerts)
        self.sensorHealthAlerts = defaults.bool(forKey: UserPreferenceKeys.sensorHealthAlerts)
        self.requireDisarmConfirmation = defaults.bool(forKey: UserPreferenceKeys.requireDisarmConfirmation)
        self.showSensorWarnings = defaults.bool(forKey: UserPreferenceKeys.showSensorWarnings)
    }

    /// Reset preferences to default values (useful for testing)
    func resetToDefaults() {
        securityEventAlerts = true
        sensorHealthAlerts = true
        requireDisarmConfirmation = true
        showSensorWarnings = true
    }
}
