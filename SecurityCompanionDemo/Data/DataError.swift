//
//  DataError.swift
//  SecurityCompanionDemo
//

import Foundation

enum DataError: LocalizedError, Sendable, Equatable {
    case zoneNotFound
    case networkUnavailable
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingFailed
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .zoneNotFound:
            return "The zone could not be found."
        case .networkUnavailable:
            return "Network connection unavailable. Please check your internet connection."
        case .invalidResponse:
            return "Invalid server response. Please try again later."
        case .httpError(let statusCode):
            return "Server returned an error (status \(statusCode)). Please try again later."
        case .decodingFailed:
            return "Unable to process the received security event data."
        case .emptyResponse:
            return "No security events were returned by the service."
        }
    }
}
