import WebRTC
import Foundation

extension RTCBundlePolicy {
    func telnyx_to_string() -> String {
        switch self {
            case .balanced: return "balanced"
            case .maxBundle: return "maxBundle"
            case .maxCompat: return "maxCompat"
            @unknown default: return "unknown"
        }
    }
}
