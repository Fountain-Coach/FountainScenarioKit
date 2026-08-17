import XCTest
import FountainScenarioKit
import FountainScenarioTestKit

final class ScenarioRuntimeTests: XCTestCase {
    func testMIDI2CodecRoundTripsTypedScenarioEnvelope() throws {
        let envelope = FountainScenarioMIDI2Envelope(
            topic: FountainScenarioMIDI2Contract.generic.invokeTopic,
            correlationId: "corr-1",
            sessionId: "session-1",
            payload: ["scenario": "scenario-runtime-midi2", "idempotencyKey": "corr-1"],
            timestamp: 1_000,
            capabilityMask: 1 << 11)

        let decoded = try FountainScenarioMIDI2Codec.decode(FountainScenarioMIDI2Codec.encode(envelope))
        XCTAssertEqual(decoded, envelope)
    }

    func testContractLoaderRejectsUnboundOperationAndAcceptsTrackedShape() throws {
        let jsonText = """
        {"scenarioVersion":2,"id":"fixture","command":"fountain.scenario.run","status":"draft",
         "store":{"intent":"fresh","corpus":"fixture-corpus"},
         "launch":{"scene":"fixture-scene"},"steps":[{"id":"admit"}]}
        """
        let contract = try FountainScenarioContract(jsonData: Data(jsonText.utf8))
        XCTAssertEqual(contract.id, "fixture")
        XCTAssertEqual(contract.stepIDs, ["admit"])

        let invalid = jsonText.replacingOccurrences(of: "fountain.scenario.run", with: "unknown.operation")
        XCTAssertThrowsError(try FountainScenarioContract(jsonData: Data(invalid.utf8)))
    }

    func testRuntimeEmitsAdmittedRunningAndTerminalSuccessWithoutTimer() async {
        let runtime = FountainScenarioRuntime(executionIDFactory: { "execution-1" })
        let request = FountainScenarioRunRequest(
            scenarioID: "scenario-runtime-midi2",
            correlationID: "corr-1",
            idempotencyKey: "corr-1",
            sourceCommit: "commit-1",
            storePath: "/tmp/scenario-store")

        let stream = await runtime.execute(request) {}
        var phases: [FountainScenarioLifecyclePhase] = []
        for await event in stream {
            phases.append(event.phase)
        }

        XCTAssertEqual(phases, [.admitted, .running, .succeeded])
        let terminal = await runtime.terminalEvent(forIdempotencyKey: "corr-1")
        XCTAssertEqual(terminal?.executionID, "execution-1")
    }

    func testDuplicateIdempotencyKeyReplaysTerminalWithoutExecutingWorkAgain() async {
        let runtime = FountainScenarioRuntime(executionIDFactory: { "execution-deduplicated" })
        let request = FountainScenarioRunRequest(
            scenarioID: "scenario-runtime-midi2",
            correlationID: "corr-deduplicated",
            idempotencyKey: "same-operation",
            sourceCommit: "commit-1",
            storePath: "/tmp/scenario-store")
        let first = await runtime.execute(request) {}
        for await _ in first {}
        let duplicate = await runtime.execute(request) {
            XCTFail("duplicate operation must not execute work")
        }
        var phases: [FountainScenarioLifecyclePhase] = []
        for await event in duplicate { phases.append(event.phase) }
        XCTAssertEqual(phases, [.succeeded])
    }

    func testLifecyclePersistsBeforeEventsAreYielded() async {
        let store = InMemoryScenarioStore()
        let runtime = FountainScenarioRuntime(executionIDFactory: { "execution-store" }, store: store)
        let request = FountainScenarioRunRequest(
            scenarioID: "scenario-runtime-midi2",
            correlationID: "corr-store",
            idempotencyKey: "corr-store",
            sourceCommit: "commit-1",
            storePath: "/tmp/scenario-store")
        let stream = await runtime.execute(request) {}
        for await _ in stream {}
        let events = await store.allEvents()
        XCTAssertEqual(events.map(\.phase), [.admitted, .running, .succeeded])
    }

    func testTestKitRecordsProductionCodecTraffic() async throws {
        let channel = InMemoryScenarioChannel()
        let envelope = FountainScenarioMIDI2Envelope(
            topic: FountainScenarioMIDI2Contract.generic.eventTopic,
            correlationId: "corr-2",
            sessionId: "session-2",
            payload: ["phase": "succeeded"])
        try await channel.send(envelope)
        let sent = try await channel.sentEnvelopes()
        XCTAssertEqual(sent, [envelope])
    }

    func testEnvelopeUsesTheStableMIDI2Shape() throws {
        let envelope = FountainScenarioMIDI2Envelope(
            topic: FountainScenarioMIDI2Contract.generic.invokeTopic,
            correlationId: "corr-3",
            sessionId: "session-3",
            payload: ["operation": FountainScenarioMIDI2Contract.generic.operationIdentity],
            timestamp: 1_000_000)
        let data = try JSONEncoder().encode(envelope)
        let external = try JSONDecoder().decode(StableMIDI2Envelope.self, from: data)
        XCTAssertEqual(external.topic, envelope.topic)
        XCTAssertEqual(external.schemaVersion, envelope.schemaVersion)
        XCTAssertEqual(external.correlationId, envelope.correlationId)
        XCTAssertEqual(external.sessionId, envelope.sessionId)
        XCTAssertEqual(external.capabilityMask, envelope.capabilityMask)
        XCTAssertEqual(external.payload, envelope.payload)
    }

    func testProductionTransportAdapterUsesTypedEnvelopeAndOwnedTransport() throws {
        let transport = RecordingMIDITransport()
        let adapter = FountainScenarioMIDI2Adapter(transport: transport)
        let envelope = FountainScenarioMIDI2Envelope(
            topic: FountainScenarioMIDI2Contract.generic.invokeTopic,
            correlationId: "corr-4",
            sessionId: "session-4",
            payload: ["operation": FountainScenarioMIDI2Contract.generic.operationIdentity],
            timestamp: 1_000_000)
        var received: FountainScenarioMIDI2Envelope?
        adapter.onReceive { received = $0 }
        try adapter.open()
        try adapter.send(envelope)
        XCTAssertTrue(transport.isOpen)
        XCTAssertEqual(transport.sentPackets.count, 1)
        transport.deliver(transport.sentPackets[0])
        XCTAssertEqual(received, envelope)
    }
}

private struct StableMIDI2Envelope: Codable {
    let topic: String
    let schemaVersion: String
    let correlationId: String
    let timestamp: UInt64
    let qos: String
    let sessionId: String
    let capabilityMask: UInt64
    let resumeToken: String?
    let ttlMs: UInt32?
    let payload: [String: String]
}
