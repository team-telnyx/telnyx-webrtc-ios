import Foundation

/// Represents real-time call quality metrics derived from WebRTC statistics
public struct CallQualityMetrics {
    /// Jitter in seconds
    public let jitter: Double
    
    /// Round-trip time in seconds
    public let rtt: Double
    
    /// Mean Opinion Score (1.0-5.0)
    public let mos: Double
    
    /// Call quality rating based on MOS
    public let quality: CallQuality
    
    /// Instantaneous inbound audio level (typically 0.0 to 1.0)
    public let inboundAudioLevel: Float
    
    /// Instantaneous outbound (local) audio level (typically 0.0 to 1.0)
    public let outboundAudioLevel: Float
    
    /// Remote inbound audio statistics
    public let inboundAudio: [String: Any]?
    
    /// Remote outbound audio statistics
    public let outboundAudio: [String: Any]?
    
    /// Remote inbound audio statistics
    public let remoteInboundAudio: [String: Any]?
    
    /// Remote outbound audio statistics
    public let remoteOutboundAudio: [String: Any]?
    
    /// Creates a dictionary representation of the metrics
    /// - Returns: Dictionary containing the metrics
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "jitter": jitter,
            "rtt": rtt,
            "mos": mos,
            "quality": quality.rawValue
        ]
        
        if let remoteInboundAudio = remoteInboundAudio {
            dict["remoteInboundAudio"] = remoteInboundAudio
        }
        
        if let remoteOutboundAudio = remoteOutboundAudio {
            dict["remoteOutboundAudio"] = remoteOutboundAudio
        }
        
        dict["inboundAudioLevel"] = inboundAudioLevel
        dict["outboundAudioLevel"] = outboundAudioLevel
        
        return dict
    }

    // Public initializer
    public init(
        jitter: Double,
        rtt: Double,
        mos: Double,
        quality: CallQuality,
        inboundAudioLevel: Float,
        outboundAudioLevel: Float,
        inboundAudio: [String: Any]?,
        outboundAudio: [String: Any]?,
        remoteInboundAudio: [String: Any]?,
        remoteOutboundAudio: [String: Any]?
    ) {
        self.jitter = jitter
        self.rtt = rtt
        self.mos = mos
        self.quality = quality
        self.inboundAudioLevel = inboundAudioLevel
        self.outboundAudioLevel = outboundAudioLevel
        self.inboundAudio = inboundAudio
        self.outboundAudio = outboundAudio
        self.remoteInboundAudio = remoteInboundAudio
        self.remoteOutboundAudio = remoteOutboundAudio
    }
}


extension CallQualityMetrics {
    /// Returns an empty/default instance of CallQualityMetrics
    public static var empty: CallQualityMetrics {
        return CallQualityMetrics(
            jitter: 0.0,
            rtt: 0.0,
            mos: 1.0, // lowest possible MOS score
            quality: .bad,
            inboundAudioLevel: 0.0,
            outboundAudioLevel: 0.0,
            inboundAudio: nil,
            outboundAudio: nil,
            remoteInboundAudio: nil,
            remoteOutboundAudio: nil
        )
    }
}

