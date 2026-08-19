import XCTest
@testable import FountainScenarioKit

final class SemanticPipelineContractTests: XCTestCase {
    private func source() throws -> FountainSemanticSourceReference {
        try FountainSemanticSourceReference(documentID: "doc:85", contentDigest: "sha256:abc", startLine: 1, endLine: 20)
    }

    func testOrderedPipelineRequiresOneSource() throws {
        let source = try source()
        let measure = try FountainSemanticPipelineOperation(
            operation: .measure, source: source, frameworkRevision: "NaturalLanguage", idempotencyKey: "m")
        let interpret = try FountainSemanticPipelineOperation(
            operation: .interpret, source: source, inputReceiptIDs: ["measure-1"],
            laneDecisionID: "lane-1", modelRevision: "paid-model-1", idempotencyKey: "i")
        let contract = try FountainSemanticPipelineContract(
            pipelineID: "pipeline-86", source: source, operations: [measure, interpret])
        XCTAssertEqual(contract.terminalOperation, .interpret)
    }

    func testPaidOperationRequiresLaneDecision() throws {
        let source = try source()
        XCTAssertThrowsError(try FountainSemanticPipelineOperation(
            operation: .interpret, source: source, inputReceiptIDs: ["measure-1"], idempotencyKey: "i")) { error in
            XCTAssertEqual(error as? FountainSemanticPipelineError, .missing("laneDecisionID"))
        }
    }

    func testMixedSourcesAndOutOfOrderOperationsAreRejected() throws {
        let source = try source()
        let other = try FountainSemanticSourceReference(documentID: "doc:other", contentDigest: "sha256:def", startLine: 1, endLine: 2)
        let measure = try FountainSemanticPipelineOperation(operation: .measure, source: source, idempotencyKey: "m")
        let embed = try FountainSemanticPipelineOperation(operation: .embed, source: other, idempotencyKey: "e")
        XCTAssertThrowsError(try FountainSemanticPipelineContract(pipelineID: "bad-source", source: source, operations: [measure, embed]))

        let interpret = try FountainSemanticPipelineOperation(
            operation: .interpret, source: source, inputReceiptIDs: ["embed-1"],
            laneDecisionID: "lane-1", modelRevision: "model-1", idempotencyKey: "i")
        XCTAssertThrowsError(try FountainSemanticPipelineContract(
            pipelineID: "bad-order", source: source, operations: [interpret, measure]))
    }
}
