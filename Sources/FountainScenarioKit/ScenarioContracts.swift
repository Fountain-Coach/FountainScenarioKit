import Foundation
import MIDI2

/// The small, machine-readable projection consumed by the Swift scenario runner.
/// The YAML remains the authoring contract; this loader consumes its tracked JSON projection so acceptance does not
/// depend on Python or a second parser.
public struct FountainScenarioContract: Sendable, Equatable {
    public let scenarioVersion: Int
    public let id: String
    public let command: String
    public let status: String
    public let storeIntent: String
    public let corpusID: String
    public let sceneID: String
    public let stepIDs: [String]

    public init(jsonData: Data, expectedOperationIdentity: String = FountainScenarioMIDI2Contract.generic.operationIdentity) throws {
        guard let root = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let scenarioVersion = root["scenarioVersion"] as? Int,
              let id = root["id"] as? String,
              let command = root["command"] as? String,
              let status = root["status"] as? String,
              let store = root["store"] as? [String: Any],
              let storeIntent = store["intent"] as? String,
              let corpusID = store["corpus"] as? String,
              let launch = root["launch"] as? [String: Any],
              let sceneID = launch["scene"] as? String,
              let steps = root["steps"] as? [[String: Any]] else {
            throw ContractError.invalidShape
        }
        guard scenarioVersion >= 2, !id.isEmpty, command == expectedOperationIdentity,
              !storeIntent.isEmpty, !corpusID.isEmpty, !sceneID.isEmpty,
              !steps.isEmpty, steps.allSatisfy({ ($0["id"] as? String)?.isEmpty == false }) else {
            throw ContractError.invalidValues
        }
        self.scenarioVersion = scenarioVersion
        self.id = id
        self.command = command
        self.status = status
        self.storeIntent = storeIntent
        self.corpusID = corpusID
        self.sceneID = sceneID
        self.stepIDs = steps.compactMap { $0["id"] as? String }
    }

    public enum ContractError: Error, LocalizedError, Equatable, Sendable {
        case unreadableFile(String)
        case invalidShape
        case invalidValues

        public var errorDescription: String? {
            switch self {
            case .unreadableFile(let path): return "scenario contract is unreadable: \(path)"
            case .invalidShape: return "scenario contract JSON does not match the governed shape"
            case .invalidValues: return "scenario contract contains invalid or non-MIDI2 operation values"
            }
        }
    }

    public static func load(
        from url: URL,
        expectedOperationIdentity: String = FountainScenarioMIDI2Contract.generic.operationIdentity
    ) throws -> FountainScenarioContract {
        do { return try FountainScenarioContract(jsonData: Data(contentsOf: url), expectedOperationIdentity: expectedOperationIdentity) }
        catch let error as ContractError { throw error }
        catch { throw ContractError.unreadableFile(url.path) }
    }
}

/// The one typed operation boundary used by the Swift scenario actor and by external MIDI2 peers.
public struct FountainScenarioMIDI2Contract: Sendable, Equatable {
    public let schemaVersion: String
    public let operationIdentity: String
    public let discoveryTopic: String
    public let invokeTopic: String
    public let eventTopic: String

    public init(
        schemaVersion: String,
        operationIdentity: String,
        discoveryTopic: String,
        invokeTopic: String,
        eventTopic: String
    ) {
        self.schemaVersion = schemaVersion
        self.operationIdentity = operationIdentity
        self.discoveryTopic = discoveryTopic
        self.invokeTopic = invokeTopic
        self.eventTopic = eventTopic
    }

    /// A host-neutral contract for package consumers that do not need a product namespace.
    public static let generic = FountainScenarioMIDI2Contract(
        schemaVersion: "fountain-scenario-midi2/1",
        operationIdentity: "fountain.scenario.run",
        discoveryTopic: "fountain/scenario.discovery",
        invokeTopic: "fountain/scenario.run",
        eventTopic: "fountain/scenario.event")
}

public enum FountainScenarioLifecyclePhase: String, Codable, Equatable, Sendable {
    case admitted
    case running
    case succeeded
    case failed
    case canceled
}

public struct FountainScenarioRunRequest: Codable, Equatable, Sendable {
    public let scenarioID: String
    public let correlationID: String
    public let idempotencyKey: String
    public let sourceCommit: String
    public let storePath: String

    public init(
        scenarioID: String,
        correlationID: String,
        idempotencyKey: String,
        sourceCommit: String,
        storePath: String
    ) {
        self.scenarioID = scenarioID
        self.correlationID = correlationID
        self.idempotencyKey = idempotencyKey
        self.sourceCommit = sourceCommit
        self.storePath = storePath
    }
}

public struct FountainScenarioLifecycleEvent: Codable, Equatable, Sendable {
    public let operation: String
    public let scenarioID: String
    public let correlationID: String
    public let executionID: String
    public let phase: FountainScenarioLifecyclePhase
    public let summary: String
    public let sourceCommit: String

    public init(
        operation: String = FountainScenarioMIDI2Contract.generic.operationIdentity,
        scenarioID: String,
        correlationID: String,
        executionID: String,
        phase: FountainScenarioLifecyclePhase,
        summary: String,
        sourceCommit: String
    ) {
        self.operation = operation
        self.scenarioID = scenarioID
        self.correlationID = correlationID
        self.executionID = executionID
        self.phase = phase
        self.summary = summary
        self.sourceCommit = sourceCommit
    }
}

public struct FountainScenarioMIDI2Envelope: Codable, Equatable, Sendable {
    public let topic: String
    public let schemaVersion: String
    public let correlationId: String
    public let timestamp: UInt64
    public let qos: String
    public let sessionId: String
    public let capabilityMask: UInt64
    public let resumeToken: String?
    public let ttlMs: UInt32?
    public let payload: [String: String]

    public init(
        topic: String,
        correlationId: String,
        sessionId: String,
        payload: [String: String],
        // MIDI2Core's JSONValue transport represents numbers exactly only within the JSON integer range. The IDL
        // timestamp is session-relative, so use monotonic process uptime rather than an epoch nanosecond value.
        timestamp: UInt64 = DispatchTime.now().uptimeNanoseconds,
        qos: String = "at-least-once",
        capabilityMask: UInt64 = 1 << 11,
        resumeToken: String? = nil,
        ttlMs: UInt32? = nil,
        contract: FountainScenarioMIDI2Contract = .generic
    ) {
        self.topic = topic
        self.schemaVersion = contract.schemaVersion
        self.correlationId = correlationId
        self.timestamp = timestamp
        self.qos = qos
        self.sessionId = sessionId
        self.capabilityMask = capabilityMask
        self.resumeToken = resumeToken
        self.ttlMs = ttlMs
        self.payload = payload
    }
}

public enum FountainScenarioMIDI2Codec {
    public enum CodecError: Error, Equatable {
        case invalidEnvelope
    }

    public static func encode(_ envelope: FountainScenarioMIDI2Envelope) throws -> [UInt32] {
        let data = try JSONEncoder().encode(envelope)
        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        return try MIDI2Core.encodeWords(FlexEnvelope(
            v: 1,
            ts: envelope.timestamp / 1_000_000,
            corr: envelope.correlationId,
            intent: envelope.topic,
            body: value))
    }

    public static func decode(_ words: [UInt32]) throws -> FountainScenarioMIDI2Envelope {
        let flex = try MIDI2Core.decode(words: words)
        let data = try JSONEncoder().encode(flex.body)
        return try JSONDecoder().decode(FountainScenarioMIDI2Envelope.self, from: data)
    }
}
