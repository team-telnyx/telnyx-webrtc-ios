import WebRTC
import Foundation

extension RTCRtcpMuxPolicy {
    func telnyx_to_string() -> String {
        switch self {
            case .negotiate: return "negotiate"
            case .require: return "require"
            @unknown default: return "unknown"
        }
    }
}
