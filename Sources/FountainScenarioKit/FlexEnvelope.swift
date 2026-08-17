import Foundation
import MIDI2

public struct FlexEnvelope: Codable, Equatable, Sendable {
    public let v: Int
    public let ts: UInt64
    public let corr: String
    public let intent: String
    public let body: JSONValue

    public init(v: Int, ts: UInt64, corr: String, intent: String, body: JSONValue) {
        self.v = v
        self.ts = ts
        self.corr = corr
        self.intent = intent
        self.body = body
    }
}

public enum MIDI2Core {
    enum CoreError: Error { case encodingFailed, decodingFailed }
    private static let sysexManufacturerId: [UInt8] = [0x7D]

    public static func encode(_ env: FlexEnvelope) throws -> Ump128 {
        let data = try JSONEncoder().encode(env)
        guard let text = String(data: data, encoding: .utf8) else { throw CoreError.encodingFailed }
        let msg = try FlexText(address: .group(Uint4(0)!), text: text)
        return msg.encode()
    }

    public static func encodeWords(_ env: FlexEnvelope) throws -> [UInt32] {
        let data = try JSONEncoder().encode(env)
        let body = DataMessageBody.sysex8(
            manufacturerID: sysexManufacturerId,
            data: Array(data)
        )
        let packets = try body.umpPackets(group: Uint4(0)!)
        return packets.flatMap { $0.words }
    }

    public static func decode(_ packet: Ump128) throws -> FlexEnvelope {
        guard let msg = FlexText.decode(packet) else { throw CoreError.decodingFailed }
        let data = Data(msg.text.utf8)
        return try JSONDecoder().decode(FlexEnvelope.self, from: data)
    }

    public static func decode(words: [UInt32]) throws -> FlexEnvelope {
        if words.count == 4 {
            if let header = UmpHeader128(word: words[0]), header.messageType == 0xD,
               let packet = Ump128(words: words) {
                return try decode(packet)
            }
        }
        guard words.count % UmpPacket128.wordCount == 0 else { throw CoreError.decodingFailed }
        var packets: [UmpPacket128] = []
        packets.reserveCapacity(words.count / UmpPacket128.wordCount)
        var index = 0
        while index < words.count {
            let slice = Array(words[index..<(index + UmpPacket128.wordCount)])
            guard let packet = UmpPacket128(words: slice) else { throw CoreError.decodingFailed }
            packets.append(packet)
            index += UmpPacket128.wordCount
        }
        guard let body = DataMessageBody(sysex8Packets: packets) else { throw CoreError.decodingFailed }
        guard case let .sysex8(mfr, payload) = body,
              mfr == sysexManufacturerId else { throw CoreError.decodingFailed }
        return try JSONDecoder().decode(FlexEnvelope.self, from: Data(payload))
    }
}
