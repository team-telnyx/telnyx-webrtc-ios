import WebRTC
import Foundation

extension RTCTlsCertPolicy {
    func telnyx_to_string() -> String {
        switch self {
            case .secure: return "secure"
            case .insecureNoCheck: return "insecureNoCheck"
            @unknown default: return "unknown"
        }
    }
}
