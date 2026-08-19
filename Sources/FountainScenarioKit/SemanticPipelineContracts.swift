import Foundation

/// Product-neutral identities for a composed semantic pipeline.
/// The kit owns handoff shape and ordering; consumers own Store, UI, providers, and acceptance.
public enum FountainSemanticPipelineStage: String, Codable, CaseIterable, Sendable {
    case measure = "semantic.measure"
    case embed = "semantic.embed"
    case interpret = "semantic.interpret"
    case enrich = "semantic.enrich"
    case reconcile = "semantic.reconcile"
    case synthesize = "semantic.synthesize"
    case illustrationPrompt = "illustration.prompt"

    public var ordinal: Int { Self.allCases.firstIndex(of: self)! }
    public var requiresLaneDecision: Bool {
        switch self {
        case .measure, .embed: false
        case .interpret, .enrich, .reconcile, .synthesize, .illustrationPrompt: true
        }
    }
}

public struct FountainSemanticSourceReference: Codable, Equatable, Hashable, Sendable {
    public let documentID: String
    public let contentDigest: String
    public let startLine: UInt32
    public let endLine: UInt32

    public init(documentID: String, contentDigest: String, startLine: UInt32, endLine: UInt32) throws {
        guard !documentID.isEmpty else { throw FountainSemanticPipelineError.empty("documentID") }
        guard !contentDigest.isEmpty else { throw FountainSemanticPipelineError.empty("contentDigest") }
        guard startLine > 0, endLine >= startLine else { throw FountainSemanticPipelineError.invalidRange }
        self.documentID = documentID
        self.contentDigest = contentDigest
        self.startLine = startLine
        self.endLine = endLine
    }
}

public struct FountainSemanticPipelineOperation: Codable, Equatable, Sendable {
    public let operation: FountainSemanticPipelineStage
    public let operationVersion: String
    public let source: FountainSemanticSourceReference
    public let inputReceiptIDs: [String]
    public let laneDecisionID: String?
    public let frameworkRevision: String?
    public let modelRevision: String?
    public let idempotencyKey: String

    public init(
        operation: FountainSemanticPipelineStage,
        operationVersion: String = "1.0.0",
        source: FountainSemanticSourceReference,
        inputReceiptIDs: [String] = [],
        laneDecisionID: String? = nil,
        frameworkRevision: String? = nil,
        modelRevision: String? = nil,
        idempotencyKey: String
    ) throws {
        guard !operationVersion.isEmpty else { throw FountainSemanticPipelineError.empty("operationVersion") }
        guard !idempotencyKey.isEmpty else { throw FountainSemanticPipelineError.empty("idempotencyKey") }
        guard inputReceiptIDs.allSatisfy({ !$0.isEmpty }) else {
            throw FountainSemanticPipelineError.empty("inputReceiptIDs")
        }
        if operation.requiresLaneDecision && (laneDecisionID?.isEmpty != false) {
            throw FountainSemanticPipelineError.missing("laneDecisionID")
        }
        self.operation = operation
        self.operationVersion = operationVersion
        self.source = source
        self.inputReceiptIDs = inputReceiptIDs
        self.laneDecisionID = laneDecisionID
        self.frameworkRevision = frameworkRevision
        self.modelRevision = modelRevision
        self.idempotencyKey = idempotencyKey
    }
}

public struct FountainSemanticPipelineContract: Codable, Equatable, Sendable {
    public let pipelineID: String
    public let source: FountainSemanticSourceReference
    public let operations: [FountainSemanticPipelineOperation]

    public init(pipelineID: String, source: FountainSemanticSourceReference,
                operations: [FountainSemanticPipelineOperation]) throws {
        guard !pipelineID.isEmpty else { throw FountainSemanticPipelineError.empty("pipelineID") }
        guard !operations.isEmpty else { throw FountainSemanticPipelineError.empty("operations") }
        guard operations.allSatisfy({ $0.source == source }) else { throw FountainSemanticPipelineError.mixedSources }
        let ordinals = operations.map { $0.operation.ordinal }
        guard ordinals == ordinals.sorted() else { throw FountainSemanticPipelineError.invalidOrder }
        guard Set(operations.map { $0.operation }).count == operations.count else {
            throw FountainSemanticPipelineError.duplicateOperation
        }
        self.pipelineID = pipelineID
        self.source = source
        self.operations = operations
    }

    public var terminalOperation: FountainSemanticPipelineStage { operations.last!.operation }
}

public enum FountainSemanticPipelineError: Error, Equatable, LocalizedError, Sendable {
    case empty(String)
    case invalidRange
    case missing(String)
    case mixedSources
    case invalidOrder
    case duplicateOperation

    public var errorDescription: String? {
        switch self {
        case .empty(let field): "semantic pipeline requires a non-empty \(field)"
        case .invalidRange: "semantic pipeline source range is invalid"
        case .missing(let field): "semantic pipeline requires \(field) for this operation"
        case .mixedSources: "semantic pipeline operations must reference one immutable source"
        case .invalidOrder: "semantic pipeline operations are out of declared order"
        case .duplicateOperation: "semantic pipeline contains a duplicate operation"
        }
    }
}
