//
//  TxCodecCapability.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 08/10/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation
import WebRTC

/// Represents an audio codec capability that can be used for preferred codec selection
/// This mirrors the RTCRtpCodecCapability structure from WebRTC
public struct TxCodecCapability: Codable, Equatable, Identifiable {
    /// Unique identifier for the codec combining mimeType, clockRate, and channels
    public var id: String {
        if let channels = channels {
            return "\(mimeType)_\(clockRate)_\(channels)"
        }
        return "\(mimeType)_\(clockRate)"
    }
    /// The MIME type of the codec (e.g., "audio/opus", "audio/PCMA")
    public let mimeType: String
    
    /// The clock rate of the codec in Hz
    public let clockRate: Int
    
    /// The number of audio channels (typically 1 or 2)
    public let channels: Int?
    
    /// The SDP format-specific parameters line
    public let sdpFmtpLine: String?
    
    public init(mimeType: String, clockRate: Int, channels: Int? = nil, sdpFmtpLine: String? = nil) {
        self.mimeType = mimeType
        self.clockRate = clockRate
        self.channels = channels
        self.sdpFmtpLine = sdpFmtpLine
    }
    
    /// Creates a TxCodecCapability from an RTCRtpCodecCapability
    internal init(from rtcCodec: RTCRtpCodecCapability) {
        self.mimeType = rtcCodec.mimeType
        self.clockRate = rtcCodec.clockRate?.intValue ?? 0
        if let numChannels = rtcCodec.numChannels?.intValue, numChannels > 0 {
            self.channels = numChannels
        } else {
            self.channels = nil
        }
        self.sdpFmtpLine = rtcCodec.parameters.isEmpty ? nil : rtcCodec.parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ";")
    }
    
    /// Converts this TxCodecCapability to a dictionary for JSON serialization
    internal func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "mimeType": mimeType,
            "clockRate": clockRate
        ]

        if let channels = channels {
            dict["channels"] = channels
        }

        if let sdpFmtpLine = sdpFmtpLine {
            dict["sdpFmtpLine"] = sdpFmtpLine
        }

        return dict
    }

    /// Checks if this TxCodecCapability matches an RTCRtpCodecCapability
    /// - Parameter rtcCodec: The RTCRtpCodecCapability to compare against
    /// - Returns: true if the codecs match, false otherwise
    internal func matches(_ rtcCodec: RTCRtpCodecCapability) -> Bool {
        // Compare mimeType (case-insensitive)
        guard rtcCodec.mimeType.lowercased() == self.mimeType.lowercased() else {
            return false
        }

        // Compare clockRate
        guard let rtcClockRate = rtcCodec.clockRate?.intValue,
              rtcClockRate == self.clockRate else {
            return false
        }

        // Compare channels if specified
        if let expectedChannels = self.channels {
            let rtcChannels = rtcCodec.numChannels?.intValue ?? 0
            guard rtcChannels == expectedChannels else {
                return false
            }
        }

        return true
    }
}