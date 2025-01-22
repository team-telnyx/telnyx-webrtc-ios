import WebRTC
import Foundation

extension RTCIceCandidate {

    func telnyx_stats_extractUfrag() -> String? {
        let pattern = "ufrag\\s+(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: sdp, range: NSRange(sdp.startIndex..., in: sdp)),
              let range = Range(match.range(at: 1), in: sdp) else {
            return nil
        }
        return String(sdp[range])
    }
}
