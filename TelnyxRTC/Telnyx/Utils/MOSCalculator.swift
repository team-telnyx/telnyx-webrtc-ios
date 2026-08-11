import Foundation

/// Quality rating for a WebRTC call based on MOS score
public enum CallQuality: String {
    /// `MOS > 4.2`
    case excellent

    /// `4.1 <= MOS <= 4.2`
    case good

    /// `3.7 <= MOS <= 4.0`
    case fair

    /// `3.1 <= MOS <= 3.6`
    case poor

    /// `MOS <= 3.0`
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
    /// - Returns: MOS score in the inclusive range `1.0...5.0`, or `NaN` when the
    ///   inputs are non-finite or the computation overflows. Callers should pair
    ///   the result with `getQuality(mos:)`, which maps `NaN` to `.unknown`.
    public static func calculateMOS(jitter: Double, rtt: Double, packetsReceived: Int, packetsLost: Int) -> Double {


        Logger.log.i(message: "Calculating_MOS... \(jitter), \(rtt), \(packetsReceived), \(packetsLost)")

        // Reject non-finite inputs early so we never surface a misleading
        // clamped score (e.g. jitter / RTT reported as `.infinity` would
        // otherwise clamp to 5.0 → `.excellent`). Returning NaN lets
        // `getQuality(mos:)` report `.unknown` instead.
        guard jitter.isFinite, rtt.isFinite else {
            return Double.nan
        }

        // Simplified R-factor calculation
        let R0: Double = 93.2 // Base value for G.711 codec
        let Is: Double = 0 // Assume no simultaneous transmission impairment
        let Id = calculateDelayImpairment(jitter: jitter, rtt: rtt) // Delay impairment
        let Ie = calculateEquipmentImpairment(packetsLost: packetsLost, packetsReceived: packetsReceived) // Equipment impairment
        let A: Double = 0 // Advantage factor (0 for WebRTC)

        let R = R0 - Is - Id - Ie + A

        // Convert R-factor to MOS
        let MOS = 1 + 0.035 * R + 0.000007 * R * (R - 60) * (100 - R)

        // If the computation produced a non-finite value we cannot safely
        // clamp it. Propagate NaN so the caller can mark quality as unknown
        // instead of reporting an arbitrary in-range score.
        guard MOS.isFinite else {
            return Double.nan
        }
        return min(max(MOS, 1), 5) // Clamp MOS between 1 and 5
    }

    /// Determines call quality based on MOS score.
    ///
    /// Non-finite inputs (`NaN`, `±infinity`) are reported as `.unknown`. For
    /// finite values the bands are continuous — every non-negative MOS value
    /// maps to exactly one rating, with no gaps between bands.
    /// - Parameter mos: Mean Opinion Score
    /// - Returns: Call quality rating
    public static func getQuality(mos: Double) -> CallQuality {
        if mos.isNaN || mos.isInfinite {
            return .unknown
        }

        if mos > 4.2 {
            return .excellent
        } else if mos >= 4.1 {
            return .good
        } else if mos >= 3.7 {
            return .fair
        } else if mos >= 3.1 {
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
        
        // Simplified formula for delay impairment
        return 0.024 * latency + 0.11 * (latency - 177.3) * (latency > 177.3 ? 1 : 0)
    }
    
    /// Calculates equipment impairment (Ie) based on packet loss
    /// - Parameters:
    ///   - packetsLost: Number of packets lost
    ///   - packetsReceived: Number of packets received
    /// - Returns: Equipment impairment value
    private static func calculateEquipmentImpairment(packetsLost: Int, packetsReceived: Int) -> Double {
        // Avoid division by zero
        if packetsReceived + packetsLost == 0 {
            return 0
        }
        
        // Calculate packet loss percentage
        let packetLossPercentage = Double(packetsLost) / Double(packetsReceived + packetsLost) * 100
        
        // Simplified formula for equipment impairment
        return 20 * log(1 + packetLossPercentage)
    }
}
