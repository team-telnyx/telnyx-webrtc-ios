import Foundation

/// Quality rating for a WebRTC call based on MOS score
public enum CallQuality: String {
    /// MOS > 4.2
    case excellent
    
    /// 4.1 <= MOS <= 4.2
    case good
    
    /// 3.7 <= MOS <= 4.0
    case fair
    
    /// 3.1 <= MOS <= 3.6
    case poor
    
    /// MOS <= 3.0
    case bad
    
    /// Unable to calculate quality
    case unknown
}

/// Utility class for calculating Mean Opinion Score (MOS) and call quality metrics
public class MOSCalculator {
    
    /// Calculates the Mean Opinion Score (MOS) based on WebRTC statistics
    /// - Parameters:
    ///   - jitter: Jitter in milliseconds
    ///   - rtt: Round-trip time in milliseconds
    ///   - packetsReceived: Number of packets received
    ///   - packetsLost: Number of packets lost
    /// - Returns: MOS score between 1.0 and 5.0
    public static func calculateMOS(jitter: Double, rtt: Double, packetsReceived: Int, packetsLost: Int) -> Double {
        
        Logger.log.i(message: "MOSCalculator:: Input - Jitter: \(jitter)ms, RTT: \(rtt)ms, PacketsReceived: \(packetsReceived), PacketsLost: \(packetsLost)") 
        
        // Handle edge cases
        if jitter.isNaN || rtt.isNaN || jitter.isInfinite || rtt.isInfinite {
            Logger.log.w(message: "MOSCalculator:: Invalid input values detected, returning poor quality")
            return 2.0 // Return poor quality for invalid inputs
        }
        
        // Simplified R-factor calculation
        let R0: Double = 93.2 // Base value for G.711 codec
        let Is: Double = 0 // Assume no simultaneous transmission impairment
        let Id = calculateDelayImpairment(jitter: jitter, rtt: rtt) // Delay impairment
        let Ie = calculateEquipmentImpairment(packetsLost: packetsLost, packetsReceived: packetsReceived) // Equipment impairment
        let A: Double = 0 // Advantage factor (0 for WebRTC)
        
        let R = R0 - Is - Id - Ie + A
        
        Logger.log.i(message: "MOSCalculator:: R-factor components - R0: \(R0), Id: \(Id), Ie: \(Ie), R: \(R)")
        
        // Convert R-factor to MOS using the standard E-model formula
        let MOS: Double
        if R < 0 {
            MOS = 1.0
        } else if R > 100 {
            MOS = 4.5
        } else {
            // Standard E-model conversion formula
            MOS = 1 + 0.035 * R + 0.000007 * R * (R - 60) * (100 - R)
        }
        
        let clampedMOS = min(max(MOS, 1), 5) // Clamp MOS between 1 and 5
        
        Logger.log.i(message: "MOSCalculator:: Calculated MOS: \(clampedMOS)")
        
        return clampedMOS
    }
    
    /// Determines call quality based on MOS score
    /// - Parameter mos: Mean Opinion Score
    /// - Returns: Call quality rating
    public static func getQuality(mos: Double) -> CallQuality {
        if mos.isNaN {
            return .unknown
        }
        
        if mos > 4.2 {
            return .excellent
        } else if mos >= 4.1 && mos <= 4.2 {
            return .good
        } else if mos >= 3.7 && mos <= 4.0 {
            return .fair
        } else if mos >= 3.1 && mos <= 3.6 {
            return .poor
        } else {
            return .bad
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Calculates delay impairment (Id) using RTT and jitter
    /// - Parameters:
    ///   - jitter: Jitter in milliseconds
    ///   - rtt: Round-trip time in milliseconds
    /// - Returns: Delay impairment value
    private static func calculateDelayImpairment(jitter: Double, rtt: Double) -> Double {
        // Approximate one-way latency as RTT / 2
        let latency = jitter + rtt / 2
        
        Logger.log.i(message: "MOSCalculator:: Delay calculation - Jitter: \(jitter)ms, RTT: \(rtt)ms, Latency: \(latency)ms")
        
        // Enhanced formula for delay impairment that better handles high latency
        var impairment = 0.024 * latency
        
        // Additional penalty for high latency (more aggressive than original)
        if latency > 177.3 {
            impairment += 0.11 * (latency - 177.3)
        }
        
        // Additional penalty for very high latency (> 500ms)
        if latency > 500 {
            impairment += 0.2 * (latency - 500)
        }
        
        // Additional penalty for very high latency (> 1000ms)
        if latency > 1000 {
            impairment += 0.3 * (latency - 1000)
        }
        
        Logger.log.i(message: "MOSCalculator:: Delay impairment: \(impairment)")
        
        return impairment
    }
    
    /// Calculates equipment impairment (Ie) based on packet loss
    /// - Parameters:
    ///   - packetsLost: Number of packets lost
    ///   - packetsReceived: Number of packets received
    /// - Returns: Equipment impairment value
    private static func calculateEquipmentImpairment(packetsLost: Int, packetsReceived: Int) -> Double {
        // Avoid division by zero
        if packetsReceived + packetsLost == 0 {
            Logger.log.i(message: "MOSCalculator:: No packets to calculate loss percentage")
            return 0
        }
        
        // Calculate packet loss percentage
        let packetLossPercentage = Double(packetsLost) / Double(packetsReceived + packetsLost) * 100
        
        Logger.log.i(message: "MOSCalculator:: Packet loss - Lost: \(packetsLost), Received: \(packetsReceived), Percentage: \(packetLossPercentage)%")
        
        // Enhanced formula for equipment impairment that better handles high packet loss
        var impairment: Double
        
        if packetLossPercentage == 0 {
            impairment = 0
        } else if packetLossPercentage < 1 {
            // Low packet loss - use standard formula
            impairment = 20 * log(1 + packetLossPercentage)
        } else if packetLossPercentage < 5 {
            // Medium packet loss - more aggressive penalty
            impairment = 25 * log(1 + packetLossPercentage)
        } else {
            // High packet loss - very aggressive penalty
            impairment = 30 * log(1 + packetLossPercentage) + 10 * (packetLossPercentage - 5)
        }
        
        Logger.log.i(message: "MOSCalculator:: Equipment impairment: \(impairment)")
        
        return impairment
    }
}
