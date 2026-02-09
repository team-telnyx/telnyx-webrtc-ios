//
//  CallReportModels.swift
//  TelnyxRTC
//
//  Created by OpenClaw on 2026-02-09.
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import Foundation

// MARK: - Call Report Data Models

/// Log entry for debug information captured during a call
public struct LogEntry: Codable {
    public let timestamp: String
    public let level: String // "debug", "info", "warn", "error"
    public let message: String
    public let context: [String: AnyCodable]?
    
    public init(timestamp: String, level: String, message: String, context: [String: AnyCodable]? = nil) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.context = context
    }
}

/// Statistics for outbound audio stream
public struct OutboundAudioStats: Codable {
    public let packetsSent: Int?
    public let bytesSent: Int?
    public let audioLevelAvg: Double?
    public let bitrateAvg: Double?
    
    public init(packetsSent: Int? = nil, bytesSent: Int? = nil, audioLevelAvg: Double? = nil, bitrateAvg: Double? = nil) {
        self.packetsSent = packetsSent
        self.bytesSent = bytesSent
        self.audioLevelAvg = audioLevelAvg
        self.bitrateAvg = bitrateAvg
    }
}

/// Statistics for inbound audio stream
public struct InboundAudioStats: Codable {
    public let packetsReceived: Int?
    public let bytesReceived: Int?
    public let packetsLost: Int?
    public let packetsDiscarded: Int?
    public let jitterBufferDelay: Double?
    public let jitterBufferEmittedCount: Int?
    public let totalSamplesReceived: Int?
    public let concealedSamples: Int?
    public let concealmentEvents: Int?
    public let audioLevelAvg: Double?
    public let jitterAvg: Double?
    public let bitrateAvg: Double?
    
    public init(
        packetsReceived: Int? = nil,
        bytesReceived: Int? = nil,
        packetsLost: Int? = nil,
        packetsDiscarded: Int? = nil,
        jitterBufferDelay: Double? = nil,
        jitterBufferEmittedCount: Int? = nil,
        totalSamplesReceived: Int? = nil,
        concealedSamples: Int? = nil,
        concealmentEvents: Int? = nil,
        audioLevelAvg: Double? = nil,
        jitterAvg: Double? = nil,
        bitrateAvg: Double? = nil
    ) {
        self.packetsReceived = packetsReceived
        self.bytesReceived = bytesReceived
        self.packetsLost = packetsLost
        self.packetsDiscarded = packetsDiscarded
        self.jitterBufferDelay = jitterBufferDelay
        self.jitterBufferEmittedCount = jitterBufferEmittedCount
        self.totalSamplesReceived = totalSamplesReceived
        self.concealedSamples = concealedSamples
        self.concealmentEvents = concealmentEvents
        self.audioLevelAvg = audioLevelAvg
        self.jitterAvg = jitterAvg
        self.bitrateAvg = bitrateAvg
    }
}

/// Combined audio statistics for a reporting interval
public struct AudioStats: Codable {
    public let outbound: OutboundAudioStats?
    public let inbound: InboundAudioStats?
    
    public init(outbound: OutboundAudioStats? = nil, inbound: InboundAudioStats? = nil) {
        self.outbound = outbound
        self.inbound = inbound
    }
}

/// Connection statistics for a reporting interval
public struct ConnectionStats: Codable {
    public let roundTripTimeAvg: Double?
    public let packetsSent: Int?
    public let packetsReceived: Int?
    public let bytesSent: Int?
    public let bytesReceived: Int?
    
    public init(
        roundTripTimeAvg: Double? = nil,
        packetsSent: Int? = nil,
        packetsReceived: Int? = nil,
        bytesSent: Int? = nil,
        bytesReceived: Int? = nil
    ) {
        self.roundTripTimeAvg = roundTripTimeAvg
        self.packetsSent = packetsSent
        self.packetsReceived = packetsReceived
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
    }
}

/// Statistics collected during a single reporting interval
public struct CallReportInterval: Codable {
    public let intervalStartUtc: String
    public let intervalEndUtc: String
    public let audio: AudioStats?
    public let connection: ConnectionStats?
    
    public init(intervalStartUtc: String, intervalEndUtc: String, audio: AudioStats? = nil, connection: ConnectionStats? = nil) {
        self.intervalStartUtc = intervalStartUtc
        self.intervalEndUtc = intervalEndUtc
        self.audio = audio
        self.connection = connection
    }
}

/// Summary information about the call
public struct CallReportSummary: Codable {
    public let callId: String
    public let destinationNumber: String?
    public let callerNumber: String?
    public let direction: String?
    public let state: String?
    public let durationSeconds: Double?
    public let telnyxSessionId: String?
    public let telnyxLegId: String?
    public let voiceSdkSessionId: String?
    public let sdkVersion: String?
    public let startTimestamp: String?
    public let endTimestamp: String?
    
    public init(
        callId: String,
        destinationNumber: String? = nil,
        callerNumber: String? = nil,
        direction: String? = nil,
        state: String? = nil,
        durationSeconds: Double? = nil,
        telnyxSessionId: String? = nil,
        telnyxLegId: String? = nil,
        voiceSdkSessionId: String? = nil,
        sdkVersion: String? = nil,
        startTimestamp: String? = nil,
        endTimestamp: String? = nil
    ) {
        self.callId = callId
        self.destinationNumber = destinationNumber
        self.callerNumber = callerNumber
        self.direction = direction
        self.state = state
        self.durationSeconds = durationSeconds
        self.telnyxSessionId = telnyxSessionId
        self.telnyxLegId = telnyxLegId
        self.voiceSdkSessionId = voiceSdkSessionId
        self.sdkVersion = sdkVersion
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
    }
}

/// Complete call report payload sent to voice-sdk-proxy
public struct CallReportPayload: Codable {
    public let summary: CallReportSummary
    public let stats: [CallReportInterval]
    public let logs: [LogEntry]?
    
    public init(summary: CallReportSummary, stats: [CallReportInterval], logs: [LogEntry]? = nil) {
        self.summary = summary
        self.stats = stats
        self.logs = logs
    }
}

// MARK: - AnyCodable Helper

/// Helper type for encoding/decoding arbitrary JSON values
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
