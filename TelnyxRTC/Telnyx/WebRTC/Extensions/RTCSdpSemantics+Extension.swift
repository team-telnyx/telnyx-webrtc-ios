import WebRTC

extension RTCSdpSemantics {
    func telnyx_to_string() -> String {
        switch self {
            case .planB: return "planB"
            case .unifiedPlan: return "unifiedPlan"
            @unknown default: return "unknown"
        }
    }
}

