import Foundation
import FountainScenarioKit

public actor InMemoryScenarioStore: FountainScenarioLifecycleStore {
    public enum StoreError: Error {
        case rejected
    }

    private let rejectWrites: Bool
    private var events: [FountainScenarioLifecycleEvent] = []
    private var terminalByKey: [String: FountainScenarioLifecycleEvent] = [:]

    public init(rejectWrites: Bool = false) {
        self.rejectWrites = rejectWrites
    }

    public func append(_ event: FountainScenarioLifecycleEvent, idempotencyKey: String) async throws {
        if rejectWrites { throw StoreError.rejected }
        events.append(event)
        if [.succeeded, .failed, .canceled].contains(event.phase) {
            terminalByKey[idempotencyKey] = event
        }
    }

    public func terminal(forIdempotencyKey key: String) async -> FountainScenarioLifecycleEvent? {
        terminalByKey[key]
    }

    public func allEvents() -> [FountainScenarioLifecycleEvent] { events }
}
