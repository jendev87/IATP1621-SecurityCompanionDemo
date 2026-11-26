//
//  MockAccount.swift
//  SecurityCompanionDemo
//

import Foundation

nonisolated struct MockAccount: Sendable, Equatable {
    let name: String
    let email: String
    let role: String
    let propertyName: String

    static let demo = MockAccount(
        name: "Alex Morgan",
        email: "alex.morgan@example.com",
        role: "Primary Administrator",
        propertyName: "Oakwood Family Residence"
    )
}
