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

/// Codec metadata linked from an RTP statistics record.
public struct AudioCodecStats: Codable {
    public let codecId: String?
    public let mimeType: String?
    public let payloadType: Int?
    public let clockRate: Int?
    public let channels: Int?
    public let sdpFmtpLine: String?

    public init(codecId: String? = nil, mimeType: String? = nil, payloadType: Int? = nil, clockRate: Int? = nil, channels: Int? = nil, sdpFmtpLine: String? = nil) {
        self.codecId = codecId
        self.mimeType = mimeType
        self.payloadType = payloadType
        self.clockRate = clockRate
        self.channels = channels
        self.sdpFmtpLine = sdpFmtpLine
    }
}

/// Local audio-source telemetry linked from outbound RTP statistics.
public struct AudioMediaSourceStats: Codable {
    public let id: String?
    public let audioLevel: Double?
    public let totalAudioEnergy: Double?
    public let totalSamplesDuration: Double?
    public let echoReturnLoss: Double?
    public let echoReturnLossEnhancement: Double?
    public let trackIdentifier: String?

    public init(id: String? = nil, audioLevel: Double? = nil, totalAudioEnergy: Double? = nil, totalSamplesDuration: Double? = nil, echoReturnLoss: Double? = nil, echoReturnLossEnhancement: Double? = nil, trackIdentifier: String? = nil) {
        self.id = id
        self.audioLevel = audioLevel
        self.totalAudioEnergy = totalAudioEnergy
        self.totalSamplesDuration = totalSamplesDuration
        self.echoReturnLoss = echoReturnLoss
        self.echoReturnLossEnhancement = echoReturnLossEnhancement
        self.trackIdentifier = trackIdentifier
    }
}

/// Statistics for outbound audio stream
public struct OutboundAudioStats: Codable {
    public let packetsSent: Int?
    public let bytesSent: Int?
    public let audioLevelAvg: Double?
    public let bitrateAvg: Double?
    public let retransmittedPacketsSent: Int?
    public let retransmittedBytesSent: Int?
    public let headerBytesSent: Int?
    public let nackCount: Int?
    public let targetBitrate: Double?
    public let totalPacketSendDelay: Double?
    public let active: Bool?
    public let codec: AudioCodecStats?
    public let mediaSource: AudioMediaSourceStats?
    
    public init(packetsSent: Int? = nil, bytesSent: Int? = nil, audioLevelAvg: Double? = nil, bitrateAvg: Double? = nil, retransmittedPacketsSent: Int? = nil, retransmittedBytesSent: Int? = nil, headerBytesSent: Int? = nil, nackCount: Int? = nil, targetBitrate: Double? = nil, totalPacketSendDelay: Double? = nil, active: Bool? = nil, codec: AudioCodecStats? = nil, mediaSource: AudioMediaSourceStats? = nil) {
        self.packetsSent = packetsSent
        self.bytesSent = bytesSent
        self.audioLevelAvg = audioLevelAvg
        self.bitrateAvg = bitrateAvg
        self.retransmittedPacketsSent = retransmittedPacketsSent
        self.retransmittedBytesSent = retransmittedBytesSent
        self.headerBytesSent = headerBytesSent
        self.nackCount = nackCount
        self.targetBitrate = targetBitrate
        self.totalPacketSendDelay = totalPacketSendDelay
        self.active = active
        self.codec = codec
        self.mediaSource = mediaSource
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
    public let nackCount: Int?
    public let headerBytesReceived: Int?
    public let fecPacketsReceived: Int?
    public let fecPacketsDiscarded: Int?
    public let jitterBufferTargetDelay: Double?
    public let jitterBufferMinimumDelay: Double?
    public let totalSamplesDecoded: Int?
    public let samplesDecodedWithSilence: Int?
    public let samplesDecodedWithConcealment: Int?
    public let totalAudioEnergy: Double?
    public let totalSamplesDuration: Double?
    public let codec: AudioCodecStats?
    
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
        bitrateAvg: Double? = nil,
        nackCount: Int? = nil,
        headerBytesReceived: Int? = nil,
        fecPacketsReceived: Int? = nil,
        fecPacketsDiscarded: Int? = nil,
        jitterBufferTargetDelay: Double? = nil,
        jitterBufferMinimumDelay: Double? = nil,
        totalSamplesDecoded: Int? = nil,
        samplesDecodedWithSilence: Int? = nil,
        samplesDecodedWithConcealment: Int? = nil,
        totalAudioEnergy: Double? = nil,
        totalSamplesDuration: Double? = nil,
        codec: AudioCodecStats? = nil
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
        self.nackCount = nackCount
        self.headerBytesReceived = headerBytesReceived
        self.fecPacketsReceived = fecPacketsReceived
        self.fecPacketsDiscarded = fecPacketsDiscarded
        self.jitterBufferTargetDelay = jitterBufferTargetDelay
        self.jitterBufferMinimumDelay = jitterBufferMinimumDelay
        self.totalSamplesDecoded = totalSamplesDecoded
        self.samplesDecodedWithSilence = samplesDecodedWithSilence
        self.samplesDecodedWithConcealment = samplesDecodedWithConcealment
        self.totalAudioEnergy = totalAudioEnergy
        self.totalSamplesDuration = totalSamplesDuration
        self.codec = codec
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
    public let currentRoundTripTime: Double?
    public let roundTripTimeSource: String?
    
    public init(
        roundTripTimeAvg: Double? = nil,
        packetsSent: Int? = nil,
        packetsReceived: Int? = nil,
        bytesSent: Int? = nil,
        bytesReceived: Int? = nil,
        currentRoundTripTime: Double? = nil,
        roundTripTimeSource: String? = nil
    ) {
        self.roundTripTimeAvg = roundTripTimeAvg
        self.packetsSent = packetsSent
        self.packetsReceived = packetsReceived
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
        self.currentRoundTripTime = currentRoundTripTime
        self.roundTripTimeSource = roundTripTimeSource
    }
}

/// A local or remote ICE candidate resolved from the selected candidate pair.
public struct ICECandidateStats: Codable {
    public let id: String?
    public let address: String?
    public let port: Int?
    public let candidateType: String?
    public let protocolType: String?
    public let networkType: String?
    public let url: String?
    public let relayProtocol: String?

    enum CodingKeys: String, CodingKey {
        case id, address, port, candidateType, networkType, url, relayProtocol
        case protocolType = "protocol"
    }

    public init(id: String? = nil, address: String? = nil, port: Int? = nil, candidateType: String? = nil, protocolType: String? = nil, networkType: String? = nil, url: String? = nil, relayProtocol: String? = nil) {
        self.id = id
        self.address = address
        self.port = port
        self.candidateType = candidateType
        self.protocolType = protocolType
        self.networkType = networkType
        self.url = url
        self.relayProtocol = relayProtocol
    }
}

/// Selected ICE candidate-pair details. Field names mirror the JS SDK report.
public struct ICECandidatePairStats: Codable {
    public let id: String?
    public let localCandidateId: String?
    public let remoteCandidateId: String?
    public let state: String?
    public let nominated: Bool?
    public let writable: Bool?
    public let currentRoundTripTime: Double?
    public let requestsSent: Int?
    public let responsesReceived: Int?
    public let local: ICECandidateStats?
    public let remote: ICECandidateStats?

    public init(id: String? = nil, localCandidateId: String? = nil, remoteCandidateId: String? = nil, state: String? = nil, nominated: Bool? = nil, writable: Bool? = nil, currentRoundTripTime: Double? = nil, requestsSent: Int? = nil, responsesReceived: Int? = nil, local: ICECandidateStats? = nil, remote: ICECandidateStats? = nil) {
        self.id = id
        self.localCandidateId = localCandidateId
        self.remoteCandidateId = remoteCandidateId
        self.state = state
        self.nominated = nominated
        self.writable = writable
        self.currentRoundTripTime = currentRoundTripTime
        self.requestsSent = requestsSent
        self.responsesReceived = responsesReceived
        self.local = local
        self.remote = remote
    }
}

/// DTLS/ICE transport snapshot for a reporting interval.
public struct TransportStats: Codable {
    public let iceState: String?
    public let dtlsState: String?
    public let srtpCipher: String?
    public let tlsVersion: String?
    public let selectedCandidatePairChanges: Int?
    public let selectedCandidatePairId: String?

    public init(iceState: String? = nil, dtlsState: String? = nil, srtpCipher: String? = nil, tlsVersion: String? = nil, selectedCandidatePairChanges: Int? = nil, selectedCandidatePairId: String? = nil) {
        self.iceState = iceState
        self.dtlsState = dtlsState
        self.srtpCipher = srtpCipher
        self.tlsVersion = tlsVersion
        self.selectedCandidatePairChanges = selectedCandidatePairChanges
        self.selectedCandidatePairId = selectedCandidatePairId
    }
}

public struct MediaPlayoutStats: Codable {
    public let synthesizedSamplesEvents: Int?
    public let synthesizedSamplesDuration: Double?
    public let totalPlayoutDelay: Double?
    public let totalSamplesCount: Int?
    public let totalSamplesDuration: Double?
}

public struct RemoteInboundRTCPStats: Codable {
    public let packetsReceived: Int?
    public let packetsLost: Int?
    public let fractionLost: Double?
    public let jitter: Double?
    public let roundTripTime: Double?
    public let totalRoundTripTime: Double?
    public let roundTripTimeMeasurements: Int?
    public let roundTripTimeAvg: Double?
    public let nackCount: Int?
    public let reportsReceived: Int?
    public let packetsDiscarded: Int?
}

public struct RemoteOutboundRTCPStats: Codable {
    public let packetsSent: Int?
    public let bytesSent: Int?
    public let reportsCount: Int?
    public let roundTripTime: Double?
    public let totalPacketSendDelay: Double?
}

public struct RemoteRTCPStats: Codable {
    public let inbound: RemoteInboundRTCPStats?
    public let outbound: RemoteOutboundRTCPStats?
}

/// Statistics collected during a single reporting interval
public struct CallReportInterval: Codable {
    public let intervalStartUtc: String
    public let intervalEndUtc: String
    public let audio: AudioStats?
    public let connection: ConnectionStats?
    public let ice: ICECandidatePairStats?
    public let transport: TransportStats?
    public let mediaPlayout: MediaPlayoutStats?
    public let remoteRtcp: RemoteRTCPStats?
    
    public init(intervalStartUtc: String, intervalEndUtc: String, audio: AudioStats? = nil, connection: ConnectionStats? = nil, ice: ICECandidatePairStats? = nil, transport: TransportStats? = nil, mediaPlayout: MediaPlayoutStats? = nil, remoteRtcp: RemoteRTCPStats? = nil) {
        self.intervalStartUtc = intervalStartUtc
        self.intervalEndUtc = intervalEndUtc
        self.audio = audio
        self.connection = connection
        self.ice = ice
        self.transport = transport
        self.mediaPlayout = mediaPlayout
        self.remoteRtcp = remoteRtcp
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
    /// Sanitized client and call options that were in effect for this call.
    /// Credentials and ICE usernames are represented only as presence flags.
    public let clientSummary: CallReportClientSummary?
    
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
        endTimestamp: String? = nil,
        clientSummary: CallReportClientSummary? = nil
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
        self.clientSummary = clientSummary
    }
}

/// JS-compatible, sanitized runtime configuration included with a call report.
/// Keep this intentionally narrow: a call report must never contain ICE server
/// credentials, authentication secrets, or user-provided sensitive values.
public struct CallReportClientSummary: Codable {
    public let connection: CallReportConnectionSummary?
    public let media: CallReportMediaSummary?
    public let callReports: CallReportSettingsSummary?

    public init(
        connection: CallReportConnectionSummary? = nil,
        media: CallReportMediaSummary? = nil,
        callReports: CallReportSettingsSummary? = nil
    ) {
        self.connection = connection
        self.media = media
        self.callReports = callReports
    }
}

public struct CallReportConnectionSummary: Codable {
    public let host: String?

    public init(host: String? = nil) {
        self.host = host
    }
}

public struct CallReportMediaSummary: Codable {
    public let audio: Bool?
    public let video: Bool?
    public let mutedMicOnStart: Bool?
    public let prefetchIceCandidates: Bool?
    public let forceRelayCandidate: Bool?
    public let trickleIce: Bool?
    public let iceServers: [CallReportIceServerSummary]?

    public init(
        audio: Bool? = nil,
        video: Bool? = nil,
        mutedMicOnStart: Bool? = nil,
        prefetchIceCandidates: Bool? = nil,
        forceRelayCandidate: Bool? = nil,
        trickleIce: Bool? = nil,
        iceServers: [CallReportIceServerSummary]? = nil
    ) {
        self.audio = audio
        self.video = video
        self.mutedMicOnStart = mutedMicOnStart
        self.prefetchIceCandidates = prefetchIceCandidates
        self.forceRelayCandidate = forceRelayCandidate
        self.trickleIce = trickleIce
        self.iceServers = iceServers
    }
}

public struct CallReportIceServerSummary: Codable {
    public let urls: [String]
    public let hasUsername: Bool
    public let hasCredential: Bool

    public init(urls: [String], hasUsername: Bool, hasCredential: Bool) {
        self.urls = urls
        self.hasUsername = hasUsername
        self.hasCredential = hasCredential
    }
}

public struct CallReportSettingsSummary: Codable {
    public let enabled: Bool
    public let intervalMs: Int
    public let debugLogLevel: String
    public let debugLogMaxEntries: Int

    public init(enabled: Bool, intervalMs: Int, debugLogLevel: String, debugLogMaxEntries: Int) {
        self.enabled = enabled
        self.intervalMs = intervalMs
        self.debugLogLevel = debugLogLevel
        self.debugLogMaxEntries = debugLogMaxEntries
    }
}

/// Complete call report payload sent to voice-sdk-proxy
public struct CallReportPayload: Codable {
    public let summary: CallReportSummary
    public let stats: [CallReportInterval]
    public let logs: [LogEntry]?
    public let segment: Int?

    public init(summary: CallReportSummary, stats: [CallReportInterval], logs: [LogEntry]? = nil, segment: Int? = nil) {
        self.summary = summary
        self.stats = stats
        self.logs = logs
        self.segment = segment
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
        
        // Check Bool before Int - Bool can decode from 1/0, so Int would greedily match first
        if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
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
