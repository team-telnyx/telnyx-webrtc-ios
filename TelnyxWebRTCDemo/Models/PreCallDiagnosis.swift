//
//  PreCallDiagnosis.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 12/06/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation
import TelnyxRTC

/// Data structure representing a metric summary with min, max, and average values
public struct MetricSummary {
    /// Minimum value recorded
    public let min: Double
    
    /// Maximum value recorded
    public let max: Double
    
    /// Average value calculated
    public let avg: Double
    
    public init(min: Double, max: Double, avg: Double) {
        self.min = min
        self.max = max
        self.avg = avg
    }
    
    /// Creates a dictionary representation of the metric summary
    /// - Returns: Dictionary containing min, max, and avg values
    public func toDictionary() -> [String: Any] {
        return [
            "min": min,
            "max": max,
            "avg": avg
        ]
    }
}

/// Data structure representing ICE candidate information
public struct ICECandidate {
    /// Unique identifier for the ICE candidate
    public let id: String
    
    /// Type of the ICE candidate (host, srflx, relay, etc.)
    public let type: String
    
    /// Protocol used (UDP, TCP)
    public let candidateProtocol: String
    
    /// IP address of the candidate
    public let address: String
    
    /// Port number of the candidate
    public let port: Int
    
    /// Priority of the candidate
    public let priority: Int
    
    public init(id: String, type: String, candidateProtocol: String, address: String, port: Int, priority: Int) {
        self.id = id
        self.type = type
        self.candidateProtocol = candidateProtocol
        self.address = address
        self.port = port
        self.priority = priority
    }
    
    /// Creates a dictionary representation of the ICE candidate
    /// - Returns: Dictionary containing candidate information
    public func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "type": type,
            "protocol": candidateProtocol,
            "address": address,
            "port": port,
            "priority": priority
        ]
    }
}

/// Data structure representing a pre-call diagnosis result
/// This provides comprehensive information about call quality metrics
/// collected during a test call to help diagnose potential issues
public struct PreCallDiagnosis {
    /// Mean Opinion Score (1.0-5.0) representing overall call quality
    public let mos: Double
    
    /// Call quality rating based on MOS score
    public let quality: CallQuality
    
    /// Jitter metrics summary (in seconds)
    public let jitter: MetricSummary
    
    /// Round-trip time metrics summary (in seconds)
    public let rtt: MetricSummary
    
    /// Total number of bytes sent during the test call
    public let bytesSent: Int64
    
    /// Total number of bytes received during the test call
    public let bytesReceived: Int64
    
    /// Total number of packets sent during the test call
    public let packetsSent: Int64
    
    /// Total number of packets received during the test call
    public let packetsReceived: Int64
    
    /// List of ICE candidates discovered during the test call
    public let iceCandidates: [ICECandidate]
    
    public init(
        mos: Double,
        quality: CallQuality,
        jitter: MetricSummary,
        rtt: MetricSummary,
        bytesSent: Int64,
        bytesReceived: Int64,
        packetsSent: Int64,
        packetsReceived: Int64,
        iceCandidates: [ICECandidate]
    ) {
        self.mos = mos
        self.quality = quality
        self.jitter = jitter
        self.rtt = rtt
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
        self.packetsSent = packetsSent
        self.packetsReceived = packetsReceived
        self.iceCandidates = iceCandidates
    }
    
    /// Creates a dictionary representation of the pre-call diagnosis
    /// - Returns: Dictionary containing all diagnosis metrics
    public func toDictionary() -> [String: Any] {
        return [
            "mos": mos,
            "quality": quality.rawValue,
            "jitter": jitter.toDictionary(),
            "rtt": rtt.toDictionary(),
            "bytesSent": bytesSent,
            "bytesReceived": bytesReceived,
            "packetsSent": packetsSent,
            "packetsReceived": packetsReceived,
            "iceCandidates": iceCandidates.map { $0.toDictionary() }
        ]
    }
}

/// Enumeration representing the state of a pre-call diagnosis operation
public enum PreCallDiagnosisState: Equatable {
    case started
    case completed(PreCallDiagnosis)
    case failed(String?)

    public static func == (lhs: PreCallDiagnosisState, rhs: PreCallDiagnosisState) -> Bool {
        switch (lhs, rhs) {
        case (.started, .started):
            return true
        case (.completed, .completed):
            return true // Ignore actual diagnosis values
        case (.failed, .failed):
            return true // Optionally compare error content
        default:
            return false
        }
    }
}
