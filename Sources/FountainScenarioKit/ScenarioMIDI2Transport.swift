import Foundation

/// The smallest transport boundary needed by the scenario protocol. A concrete host may bind this to RTP-MIDI,
/// hardware, a software peer, or a deterministic loopback without importing a host transport implementation.
public protocol FountainScenarioMIDI2Transport: AnyObject, Sendable {
    var onReceiveUMP: (([UInt32]) -> Void)? { get set }
    func open() throws
    func close() throws
    func send(umpWords: [UInt32]) throws
}

/// The production transport seam for a scenario actor. The kit owns envelope admission and decoding; the caller owns
/// endpoint choice and must supply an explicitly negotiated transport (RTP, hardware, or another MIDI2 transport).
public final class FountainScenarioMIDI2Adapter: @unchecked Sendable {
    private var transport: any FountainScenarioMIDI2Transport
    private let callbackLock = NSLock()
    private var receiveHandler: ((FountainScenarioMIDI2Envelope) -> Void)?

    public init(transport: any FountainScenarioMIDI2Transport) {
        self.transport = transport
        self.transport.onReceiveUMP = { [weak self] words in
            guard let self,
                  let envelope = try? FountainScenarioMIDI2Codec.decode(words) else { return }
            self.callbackLock.lock()
            let handler = self.receiveHandler
            self.callbackLock.unlock()
            handler?(envelope)
        }
    }

    public func onReceive(_ handler: @escaping (FountainScenarioMIDI2Envelope) -> Void) {
        callbackLock.lock()
        receiveHandler = handler
        callbackLock.unlock()
    }

    public func open() throws { try transport.open() }
    public func close() throws { try transport.close() }
    public func send(_ envelope: FountainScenarioMIDI2Envelope) throws {
        try transport.send(umpWords: FountainScenarioMIDI2Codec.encode(envelope))
    }
}
