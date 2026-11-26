//
//  PostDTO.swift
//  SecurityCompanionDemo
//

import Foundation

nonisolated struct PostDTO: Codable, Sendable, Equatable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
