//
//  DomainError.swift
//  SecurityCompanionDemo
//
import Foundation

enum DomainError: LocalizedError, Sendable, Equatable {
    case notFound
    case alreadyArmed
    case alreadyDisarmed
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested zone could not be found."
        case .alreadyArmed:
            return "This zone is already armed."
        case .alreadyDisarmed:
            return "This zone is already disarmed."
        }
    }
}
