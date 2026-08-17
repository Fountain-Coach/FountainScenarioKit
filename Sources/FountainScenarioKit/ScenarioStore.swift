import Foundation

/// A host Store adapter boundary. The kit owns lifecycle semantics; the integration owns its native Store client,
/// document identities, and `changes()` subscription. No HTTP or Store implementation is allowed to leak into this
/// generic seam.
public protocol FountainScenarioLifecycleStore: Sendable {
    func append(_ event: FountainScenarioLifecycleEvent, idempotencyKey: String) async throws
    func terminal(forIdempotencyKey key: String) async -> FountainScenarioLifecycleEvent?
}
