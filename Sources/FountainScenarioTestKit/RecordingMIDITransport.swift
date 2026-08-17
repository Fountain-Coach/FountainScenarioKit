import Foundation
import FountainScenarioKit

public final class RecordingMIDITransport: FountainScenarioMIDI2Transport, @unchecked Sendable {
    public var onReceiveUMP: (([UInt32]) -> Void)?
    public private(set) var sentPackets: [[UInt32]] = []
    public private(set) var isOpen = false

    public init() {}
    public func open() throws { isOpen = true }
    public func close() throws { isOpen = false }
    public func send(umpWords: [UInt32]) throws { sentPackets.append(umpWords) }

    public func deliver(_ words: [UInt32]) {
        onReceiveUMP?(words)
    }
}
