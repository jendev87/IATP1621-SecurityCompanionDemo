//
//  AuthSessionManager.swift
//  SecurityCompanionDemo
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthSessionManager {

    static let shared = AuthSessionManager()

    private let defaults: UserDefaults
    private let storageKey: String

    var isAuthenticated: Bool {
        didSet {
            defaults.set(isAuthenticated, forKey: storageKey)
        }
    }

    var currentUser: MockAccount

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "is_authenticated_session",
        initialUser: MockAccount = .demo
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.currentUser = initialUser

        // Register default session state: active on initial launch
        defaults.register(defaults: [storageKey: true])
        self.isAuthenticated = defaults.bool(forKey: storageKey)
    }

    func signIn(user: MockAccount = .demo) {
        self.currentUser = user
        self.isAuthenticated = true
    }

    func signOut() {
        self.isAuthenticated = false
    }
}
