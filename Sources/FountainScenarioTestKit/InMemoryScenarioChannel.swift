import Foundation
import FountainScenarioKit

/// Test-only MIDI2 envelope channel. It records encoded UMP traffic and decodes it through the production codec.
public actor InMemoryScenarioChannel {
    private var packets: [[UInt32]] = []

    public init() {}

    public func send(_ envelope: FountainScenarioMIDI2Envelope) throws {
        packets.append(try FountainScenarioMIDI2Codec.encode(envelope))
    }

    public func sentEnvelopes() throws -> [FountainScenarioMIDI2Envelope] {
        try packets.map { try FountainScenarioMIDI2Codec.decode($0) }
    }
}
