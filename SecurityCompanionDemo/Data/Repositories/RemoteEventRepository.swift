//
//  RemoteEventRepository.swift
//  SecurityCompanionDemo
//

import Foundation

final class RemoteEventRepository: EventRepository, Sendable {

    private let session: URLSession
    private let endpoint: URL
    private let mapper: SecurityEventMapper

    init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://jsonplaceholder.typicode.com/posts?_limit=15")!,
        mapper: SecurityEventMapper = SecurityEventMapper()
    ) {
        self.session = session
        self.endpoint = endpoint
        self.mapper = mapper
    }

    func fetchEvents() async throws -> [SecurityEvent] {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: endpoint)
        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet ||
                urlError.code == .networkConnectionLost ||
                urlError.code == .cannotConnectToHost ||
                urlError.code == .timedOut {
                throw DataError.networkUnavailable
            } else {
                throw DataError.networkUnavailable
            }
        } catch {
            throw DataError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw DataError.httpError(statusCode: httpResponse.statusCode)
        }

        let posts: [PostDTO]
        do {
            let decoder = JSONDecoder()
            posts = try decoder.decode([PostDTO].self, from: data)
        } catch {
            throw DataError.decodingFailed
        }

        guard !posts.isEmpty else {
            throw DataError.emptyResponse
        }

        let events = posts.map { mapper.map(dto: $0) }
        return events.sorted { $0.timestamp > $1.timestamp }
    }
}
