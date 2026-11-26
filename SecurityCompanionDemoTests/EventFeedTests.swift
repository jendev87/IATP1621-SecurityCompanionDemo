//
//  EventFeedTests.swift
//  SecurityCompanionDemoTests
//

import XCTest
@testable import SecurityCompanionDemo

// MARK: - Mock Event Repository for Testing

actor MockEventRepository: EventRepository {
    private var events: [SecurityEvent]
    var shouldThrow: Bool = false
    var errorToThrow: Error = DataError.networkUnavailable

    init(events: [SecurityEvent] = []) {
        self.events = events
    }

    func setShouldThrow(_ value: Bool, error: Error = DataError.networkUnavailable) {
        self.shouldThrow = value
        self.errorToThrow = error
    }

    func setEvents(_ newEvents: [SecurityEvent]) {
        self.events = newEvents
    }

    func fetchEvents() throws -> [SecurityEvent] {
        if shouldThrow {
            throw errorToThrow
        }
        return events
    }
}

// MARK: - URLProtocol Mock for Offline URLSession Testing

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Unit Tests

final class EventFeedTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // Helper to create an isolated mock URLSession
    private func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    // MARK: - 1. GetEventsUseCase Tests

    func testGetEventsUseCase_returnsEventsFromRepository() async throws {
        let sampleEvents = [
            SecurityEvent(
                id: "1",
                title: "Door Opened",
                description: "Entry Door Opened",
                timestamp: Date(),
                severity: .info,
                type: .doorOpened,
                zoneName: "Front Entry"
            ),
            SecurityEvent(
                id: "2",
                title: "Motion Detected",
                description: "Motion detector triggered",
                timestamp: Date().addingTimeInterval(-900),
                severity: .warning,
                type: .motionDetected,
                zoneName: "Living Room"
            )
        ]

        let mockRepo = MockEventRepository(events: sampleEvents)
        let useCase = GetEventsUseCase(eventRepository: mockRepo)

        let result = try await useCase.execute()

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result, sampleEvents)
    }

    func testGetEventsUseCase_propagatesErrorWhenRepositoryFails() async {
        let mockRepo = MockEventRepository()
        await mockRepo.setShouldThrow(true, error: DataError.networkUnavailable)
        let useCase = GetEventsUseCase(eventRepository: mockRepo)

        do {
            _ = try await useCase.execute()
            XCTFail("Expected error to be propagated, but call succeeded")
        } catch let error as DataError {
            XCTAssertEqual(error, DataError.networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGetEventsUseCase_returnsEmptyArrayWhenNoEventsExist() async throws {
        let mockRepo = MockEventRepository(events: [])
        let useCase = GetEventsUseCase(eventRepository: mockRepo)

        let result = try await useCase.execute()

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - 2. RemoteEventRepository & URLProtocol Network Error Handling Tests

    func testRemoteEventRepository_successfulFetchAndMapping() async throws {
        let jsonString = """
        [
            {"userId": 1, "id": 1, "title": "post 1", "body": "body 1"},
            {"userId": 1, "id": 2, "title": "post 2", "body": "body 2"}
        ]
        """
        let data = jsonString.data(using: .utf8)!
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts?_limit=15")!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }

        let session = makeMockSession()
        let repo = RemoteEventRepository(session: session, endpoint: url)

        let events = try await repo.fetchEvents()

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.id, "1")
        XCTAssertEqual(events.last?.id, "2")
        // Verify newest first
        XCTAssertTrue(events[0].timestamp > events[1].timestamp)
    }

    func testRemoteEventRepository_networkUnavailableError() async {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts?_limit=15")!
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let session = makeMockSession()
        let repo = RemoteEventRepository(session: session, endpoint: url)

        do {
            _ = try await repo.fetchEvents()
            XCTFail("Expected DataError.networkUnavailable, but call succeeded")
        } catch let error as DataError {
            XCTAssertEqual(error, DataError.networkUnavailable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRemoteEventRepository_httpErrorStatus() async {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts?_limit=15")!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let session = makeMockSession()
        let repo = RemoteEventRepository(session: session, endpoint: url)

        do {
            _ = try await repo.fetchEvents()
            XCTFail("Expected DataError.httpError(500), but call succeeded")
        } catch let error as DataError {
            XCTAssertEqual(error, DataError.httpError(statusCode: 500))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRemoteEventRepository_decodingFailedError() async {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts?_limit=15")!
        let corruptData = "Not Valid JSON".data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, corruptData)
        }

        let session = makeMockSession()
        let repo = RemoteEventRepository(session: session, endpoint: url)

        do {
            _ = try await repo.fetchEvents()
            XCTFail("Expected DataError.decodingFailed, but call succeeded")
        } catch let error as DataError {
            XCTAssertEqual(error, DataError.decodingFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRemoteEventRepository_emptyResponseError() async {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts?_limit=15")!
        let emptyArrayData = "[]".data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, emptyArrayData)
        }

        let session = makeMockSession()
        let repo = RemoteEventRepository(session: session, endpoint: url)

        do {
            _ = try await repo.fetchEvents()
            XCTFail("Expected DataError.emptyResponse, but call succeeded")
        } catch let error as DataError {
            XCTAssertEqual(error, DataError.emptyResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - 3. DTO Decoding & SecurityEventMapper Determinism Tests

    func testPostDTO_decodingFromJSON() throws {
        let json = """
        {
            "userId": 1,
            "id": 42,
            "title": "sample title",
            "body": "sample body"
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(PostDTO.self, from: json)
        XCTAssertEqual(dto.id, 42)
        XCTAssertEqual(dto.userId, 1)
        XCTAssertEqual(dto.title, "sample title")
        XCTAssertEqual(dto.body, "sample body")
    }

    func testEventMapper_deterministicMapping_sameIDProducesIdenticalEvent() {
        let mapper = SecurityEventMapper()
        let dtoA = PostDTO(userId: 1, id: 10, title: "Title A", body: "Body A")
        let dtoB = PostDTO(userId: 99, id: 10, title: "Completely Different Title", body: "Body B")

        let eventA = mapper.map(dto: dtoA)
        let eventB = mapper.map(dto: dtoB)

        // Same ID must produce the exact same simulated security event
        XCTAssertEqual(eventA.id, eventB.id)
        XCTAssertEqual(eventA.type, eventB.type)
        XCTAssertEqual(eventA.severity, eventB.severity)
        XCTAssertEqual(eventA.zoneName, eventB.zoneName)
        XCTAssertEqual(eventA.title, eventB.title)
        XCTAssertEqual(eventA.description, eventB.description)
        XCTAssertEqual(eventA.timestamp, eventB.timestamp)
    }

    func testEventMapper_generatesAllRequiredEventTypes() {
        let mapper = SecurityEventMapper()

        // Test multiple IDs across the modulo cycle to confirm every EventType is covered
        var mappedTypes = Set<EventType>()
        for id in 0...11 {
            let dto = PostDTO(userId: 1, id: id, title: "T", body: "B")
            mappedTypes.insert(mapper.map(dto: dto).type)
        }

        XCTAssertTrue(mappedTypes.contains(.motionDetected))
        XCTAssertTrue(mappedTypes.contains(.doorOpened))
        XCTAssertTrue(mappedTypes.contains(.systemArmed))
        XCTAssertTrue(mappedTypes.contains(.systemDisarmed))
        XCTAssertTrue(mappedTypes.contains(.sensorOffline))
        XCTAssertTrue(mappedTypes.contains(.lowBattery))
    }

    func testEventMapper_severityAssignmentRules() {
        let mapper = SecurityEventMapper()

        // Verify sensorOffline is critical
        let offlineDTO = PostDTO(userId: 1, id: 4, title: "T", body: "B") // 4 % 6 = 4 -> sensorOffline
        let offlineEvent = mapper.map(dto: offlineDTO)
        XCTAssertEqual(offlineEvent.type, .sensorOffline)
        XCTAssertEqual(offlineEvent.severity, .critical)

        // Verify lowBattery is warning
        let lowBatteryDTO = PostDTO(userId: 1, id: 5, title: "T", body: "B") // 5 % 6 = 5 -> lowBattery
        let lowBatteryEvent = mapper.map(dto: lowBatteryDTO)
        XCTAssertEqual(lowBatteryEvent.type, .lowBattery)
        XCTAssertEqual(lowBatteryEvent.severity, .warning)

        // Verify system armed / disarmed are info
        let armedDTO = PostDTO(userId: 1, id: 2, title: "T", body: "B") // 2 % 6 = 2 -> systemArmed
        let armedEvent = mapper.map(dto: armedDTO)
        XCTAssertEqual(armedEvent.type, .systemArmed)
        XCTAssertEqual(armedEvent.severity, .info)
        XCTAssertNil(armedEvent.zoneName, "System-wide events should not be tied to a single zone")

        let disarmedDTO = PostDTO(userId: 1, id: 3, title: "T", body: "B") // 3 % 6 = 3 -> systemDisarmed
        let disarmedEvent = mapper.map(dto: disarmedDTO)
        XCTAssertEqual(disarmedEvent.type, .systemDisarmed)
        XCTAssertEqual(disarmedEvent.severity, .info)
        XCTAssertNil(disarmedEvent.zoneName, "System-wide events should not be tied to a single zone")
    }

    func testEventMapper_sortingChronologicalNewestFirst() {
        let baseDate = Date(timeIntervalSince1970: 1795521600) // Nov 24, 2026 12:00:00 UTC
        let mapper = SecurityEventMapper(referenceDate: baseDate)

        let dtos = (1...5).map { PostDTO(userId: 1, id: $0, title: "T\($0)", body: "B\($0)") }
        let events = dtos.map { mapper.map(dto: $0) }
        let sorted = events.sorted { $0.timestamp > $1.timestamp }

        // id 1 is -900s, id 2 is -1800s, so id 1 > id 2 > ... > id 5
        XCTAssertEqual(sorted.map { $0.id }, ["1", "2", "3", "4", "5"])
        for i in 0..<(sorted.count - 1) {
            XCTAssertTrue(sorted[i].timestamp > sorted[i + 1].timestamp)
        }
    }

    func testSecurityEventMapper_defaultReferenceDateIsNovember2026() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour],
            from: SecurityEventMapper.defaultReferenceDate
        )

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 11)
        XCTAssertEqual(components.day, 24)
        XCTAssertEqual(components.hour, 12)
    }

    // MARK: - 4. EventListViewModel State & Flow Tests

    @MainActor
    func testEventListViewModel_initialStateIsIdle() {
        let mockRepo = MockEventRepository()
        let useCase = GetEventsUseCase(eventRepository: mockRepo)
        let viewModel = EventListViewModel(getEventsUseCase: useCase)

        XCTAssertEqual(viewModel.uiState, .idle)
        XCTAssertTrue(viewModel.events.isEmpty)
        XCTAssertFalse(viewModel.isFetching)
    }

    @MainActor
    func testEventListViewModel_successfulLoad_transitionsToLoaded() async {
        let sampleEvents = [
            SecurityEvent(
                id: "1",
                title: "Door Opened",
                description: "Entry Door Opened",
                timestamp: Date(),
                severity: .info,
                type: .doorOpened,
                zoneName: "Front Entry"
            )
        ]
        let mockRepo = MockEventRepository(events: sampleEvents)
        let useCase = GetEventsUseCase(eventRepository: mockRepo)
        let viewModel = EventListViewModel(getEventsUseCase: useCase)

        await viewModel.loadEvents()

        XCTAssertEqual(viewModel.uiState, .loaded(sampleEvents))
        XCTAssertEqual(viewModel.events.count, 1)
        XCTAssertEqual(viewModel.totalCount, 1)
        XCTAssertFalse(viewModel.isFetching)
    }

    @MainActor
    func testEventListViewModel_emptyLoad_transitionsToEmpty() async {
        let mockRepo = MockEventRepository(events: [])
        let useCase = GetEventsUseCase(eventRepository: mockRepo)
        let viewModel = EventListViewModel(getEventsUseCase: useCase)

        await viewModel.loadEvents()

        XCTAssertEqual(viewModel.uiState, .empty)
        XCTAssertTrue(viewModel.events.isEmpty)
        XCTAssertEqual(viewModel.totalCount, 0)
    }

    @MainActor
    func testEventListViewModel_failureLoad_transitionsToError() async {
        let mockRepo = MockEventRepository()
        await mockRepo.setShouldThrow(true, error: DataError.networkUnavailable)
        let useCase = GetEventsUseCase(eventRepository: mockRepo)
        let viewModel = EventListViewModel(getEventsUseCase: useCase)

        await viewModel.loadEvents()

        if case .error(let message) = viewModel.uiState {
            XCTAssertEqual(message, DataError.networkUnavailable.localizedDescription)
        } else {
            XCTFail("Expected .error state, but got \(viewModel.uiState)")
        }
    }

    @MainActor
    func testEventListViewModel_retryAfterFailure_recoversToLoaded() async {
        let sampleEvents = [
            SecurityEvent(
                id: "10",
                title: "Motion",
                description: "Motion detected",
                timestamp: Date(),
                severity: .warning,
                type: .motionDetected
            )
        ]
        let mockRepo = MockEventRepository(events: sampleEvents)
        await mockRepo.setShouldThrow(true, error: DataError.networkUnavailable)
        let useCase = GetEventsUseCase(eventRepository: mockRepo)
        let viewModel = EventListViewModel(getEventsUseCase: useCase)

        // 1. Initial attempt fails
        await viewModel.loadEvents()
        XCTAssertEqual(viewModel.uiState, .error(DataError.networkUnavailable.localizedDescription))

        // 2. Retry succeeds
        await mockRepo.setShouldThrow(false)
        await viewModel.loadEvents()

        XCTAssertEqual(viewModel.uiState, .loaded(sampleEvents))
        XCTAssertEqual(viewModel.events.count, 1)
    }

    @MainActor
    func testEventListViewModel_pullToRefresh_maintainsExistingDataOnFailure() async {
        let initialEvents = [
            SecurityEvent(
                id: "1",
                title: "Door Opened",
                description: "Entry Door Opened",
                timestamp: Date(),
                severity: .info,
                type: .doorOpened
            )
        ]
        let mockRepo = MockEventRepository(events: initialEvents)
        let useCase = GetEventsUseCase(eventRepository: mockRepo)
        let viewModel = EventListViewModel(getEventsUseCase: useCase)

        // Initial load succeeds
        await viewModel.loadEvents()
        XCTAssertEqual(viewModel.events.count, 1)

        // Pull to refresh fails: existing events must stay visible
        await mockRepo.setShouldThrow(true, error: DataError.networkUnavailable)
        await viewModel.loadEvents(isPullToRefresh: true)

        XCTAssertEqual(viewModel.uiState, .loaded(initialEvents), "Events must remain visible during pull-to-refresh failure")
        XCTAssertEqual(viewModel.events.count, 1)
        XCTAssertNotNil(viewModel.refreshErrorMessage)
    }

    @MainActor
    func testEventListViewModel_dismissRefreshError_clearsMessageWithoutMutatingEvents() async {
        let initialEvents = [
            SecurityEvent(
                id: "1",
                title: "Door Opened",
                description: "Entry Door Opened",
                timestamp: Date(),
                severity: .info,
                type: .doorOpened
            )
        ]
        let mockRepo = MockEventRepository(events: initialEvents)
        let useCase = GetEventsUseCase(eventRepository: mockRepo)
        let viewModel = EventListViewModel(getEventsUseCase: useCase)

        await viewModel.loadEvents()
        XCTAssertEqual(viewModel.events.count, 1)

        // Trigger refresh failure
        await mockRepo.setShouldThrow(true, error: DataError.networkUnavailable)
        await viewModel.loadEvents(isPullToRefresh: true)
        XCTAssertNotNil(viewModel.refreshErrorMessage)

        // Dismiss error
        viewModel.dismissRefreshError()
        XCTAssertNil(viewModel.refreshErrorMessage, "Dismissing error must clear refreshErrorMessage")
        XCTAssertEqual(viewModel.uiState, .loaded(initialEvents), "Dismissing error must not mutate cached uiState")
        XCTAssertEqual(viewModel.events.count, 1, "Cached events must remain intact")

        // Subsequent refresh failure displays error again
        await viewModel.loadEvents(isPullToRefresh: true)
        XCTAssertNotNil(viewModel.refreshErrorMessage, "Subsequent refresh failure must redisplay error message")
        XCTAssertEqual(viewModel.events.count, 1)

        // Subsequent successful refresh clears error message
        await mockRepo.setShouldThrow(false)
        await viewModel.loadEvents(isPullToRefresh: true)
        XCTAssertNil(viewModel.refreshErrorMessage, "Successful refresh must clear refreshErrorMessage")
        XCTAssertEqual(viewModel.events.count, 1)
    }

    @MainActor
    func testEventListViewModel_metricCounters() async {
        let events = [
            SecurityEvent(id: "1", title: "A", description: "A", timestamp: Date(), severity: .critical, type: .sensorOffline),
            SecurityEvent(id: "2", title: "B", description: "B", timestamp: Date(), severity: .warning, type: .lowBattery),
            SecurityEvent(id: "3", title: "C", description: "C", timestamp: Date(), severity: .warning, type: .motionDetected),
            SecurityEvent(id: "4", title: "D", description: "D", timestamp: Date(), severity: .info, type: .systemArmed)
        ]
        let mockRepo = MockEventRepository(events: events)
        let useCase = GetEventsUseCase(eventRepository: mockRepo)
        let viewModel = EventListViewModel(getEventsUseCase: useCase)

        await viewModel.loadEvents()

        XCTAssertEqual(viewModel.totalCount, 4)
        XCTAssertEqual(viewModel.criticalCount, 1)
        XCTAssertEqual(viewModel.warningCount, 2)
        XCTAssertEqual(viewModel.infoCount, 1)
    }
}
