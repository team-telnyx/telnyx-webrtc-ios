import WebRTC
import Foundation

extension RTCIceTransportPolicy {
    func telnyx_to_string() -> String {
        switch self {
            case .all: return "all"
            case .noHost: return "noHost"
            case .none: return "none"
            case .relay: return "relay"
            @unknown default: return "unknown"
        }
    }
}
