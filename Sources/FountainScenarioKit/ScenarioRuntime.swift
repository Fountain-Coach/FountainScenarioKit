import Foundation

/// A deterministic, event-driven lifecycle core. Transport, Store, AX, and process admission are adapters owned by
/// the host integration; this target owns neither UI nor persistence and therefore cannot fabricate authority.
public actor FountainScenarioRuntime {
    public typealias ExecutionIDFactory = @Sendable () -> String

    private let executionIDFactory: ExecutionIDFactory
    private let store: (any FountainScenarioLifecycleStore)?
    private var terminalByIdempotency: [String: FountainScenarioLifecycleEvent] = [:]

    public init(
        executionIDFactory: @escaping ExecutionIDFactory = { UUID().uuidString },
        store: (any FountainScenarioLifecycleStore)? = nil
    ) {
        self.executionIDFactory = executionIDFactory
        self.store = store
    }

    public func execute(
        _ request: FountainScenarioRunRequest,
        work: @escaping @Sendable () async throws -> Void
    ) async -> AsyncStream<FountainScenarioLifecycleEvent> {
        if let terminal = terminalByIdempotency[request.idempotencyKey] {
            return AsyncStream { continuation in
                continuation.yield(terminal)
                continuation.finish()
            }
        }
        if let persisted = await store?.terminal(forIdempotencyKey: request.idempotencyKey) {
            terminalByIdempotency[request.idempotencyKey] = persisted
            return AsyncStream { continuation in
                continuation.yield(persisted)
                continuation.finish()
            }
        }
        let executionID = executionIDFactory()
        let admitted = event(request, executionID: executionID, phase: .admitted,
                             summary: "Scenario admitted through the typed MIDI2 operation.")
        let running = event(request, executionID: executionID, phase: .running,
                            summary: "Scenario execution is running.")

        return AsyncStream { continuation in
            Task {
                do {
                    try await self.persist(admitted, idempotencyKey: request.idempotencyKey)
                    continuation.yield(admitted)
                    try await self.persist(running, idempotencyKey: request.idempotencyKey)
                    continuation.yield(running)
                    try await work()
                    let terminal = self.event(request, executionID: executionID, phase: .succeeded,
                                              summary: "Scenario runtime completed.")
                    try await self.persist(terminal, idempotencyKey: request.idempotencyKey)
                    self.remember(terminal, idempotencyKey: request.idempotencyKey)
                    continuation.yield(terminal)
                } catch {
                    let terminal = self.event(request, executionID: executionID, phase: .failed,
                                              summary: "Scenario runtime failed: \(error.localizedDescription)")
                    try? await self.persist(terminal, idempotencyKey: request.idempotencyKey)
                    self.remember(terminal, idempotencyKey: request.idempotencyKey)
                    continuation.yield(terminal)
                }
                continuation.finish()
            }
        }
    }

    public func terminalEvent(forIdempotencyKey key: String) -> FountainScenarioLifecycleEvent? {
        terminalByIdempotency[key]
    }

    private func event(
        _ request: FountainScenarioRunRequest,
        executionID: String,
        phase: FountainScenarioLifecyclePhase,
        summary: String
    ) -> FountainScenarioLifecycleEvent {
        FountainScenarioLifecycleEvent(
            scenarioID: request.scenarioID,
            correlationID: request.correlationID,
            executionID: executionID,
            phase: phase,
            summary: summary,
            sourceCommit: request.sourceCommit)
    }

    private func remember(_ event: FountainScenarioLifecycleEvent, idempotencyKey: String) {
        terminalByIdempotency[idempotencyKey] = event
    }

    private func persist(_ event: FountainScenarioLifecycleEvent, idempotencyKey: String) async throws {
        try await store?.append(event, idempotencyKey: idempotencyKey)
    }
}
