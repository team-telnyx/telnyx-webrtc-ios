import WebRTC
import Foundation

extension RTCPeerConnectionState {
    func telnyx_to_string() -> String {
        switch self {
            case .new: return "new"
            case .connecting: return "connecting"
            case .connected: return "connected"
            case .disconnected: return "disconnected"
            case .failed: return "failed"
            case .closed: return "closed"
            @unknown default: return "unknown"
        }
    }
}