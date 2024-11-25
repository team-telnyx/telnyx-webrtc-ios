import Foundation

// Represents codec information
struct CodecInfo: Codable {
    let clockRate: Int
    let mimeType: String
    let payloadType: Int
}

// Represents a track report (audio/video) with calculated statistics
struct TrackReport: Codable {
    let id: String
    let timestamp: Double
    var bitrate: Double?        // Bitrate in bps
    var packetRate: Double?     // Packet rate in packets per second
    var bytesReceived: Int64?   // Total bytes received
    var bytesSent: Int64?       // Total bytes sent
    var packetsReceived: Int64? // Total packets received
    var packetsSent: Int64?     // Total packets sent
    var frameWidth: Int?        // Video frame width
    var frameHeight: Int?       // Video frame height
    var framesPerSecond: Double? // Video frames per second
}

// Represents inbound and outbound details for audio/video tracks
struct StatsObjectDetails: Codable {
    var inbound: [TrackReport]
    var outbound: [TrackReport]
}

// Represents remote audio/video statistics
struct RemoteStats: Codable {
    var audio: StatsObjectDetails
    var video: StatsObjectDetails
}

// Represents connection statistics
struct ConnectionStats: Codable {
    var id: String
    var totalRoundTripTime: Double?
    var currentRoundTripTime: Double?
    var availableOutgoingBitrate: Double?
    var availableIncomingBitrate: Double?
}

// Main stats object structure
struct StatsObject: Codable {
    var audio: StatsObjectDetails
    var video: StatsObjectDetails
    var remote: RemoteStats?
    var connection: ConnectionStats
    
    // Method to encode the object to JSON format
    func encodeToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(self)
            return jsonData
        } catch {
            print("Error encoding StatsObject: \(error)")
            return nil
        }
    }
}
