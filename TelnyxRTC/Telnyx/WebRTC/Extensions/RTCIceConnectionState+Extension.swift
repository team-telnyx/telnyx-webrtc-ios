import WebRTC

extension RTCIceConnectionState {
    func telnyx_to_string() -> String {
        switch self {
            case .new: return "new"
            case .checking: return "checking"
            case .connected: return "connected"
            case .completed: return "completed"
            case .failed: return "failed"
            case .disconnected: return "disconnected"
            case .closed: return "closed"
            case .count: return "count"
            @unknown default: return "unknown"
        }
    }
}
