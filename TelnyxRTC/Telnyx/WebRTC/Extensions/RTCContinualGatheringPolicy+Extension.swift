import WebRTC
import Foundation

extension RTCContinualGatheringPolicy {
    func telnyx_to_string() -> String {
        switch self {
            case .gatherContinually: return "gatherContinually"
            case .gatherOnce: return "gatherOnce"
            @unknown default: return "unknown"
        }
    }
}
