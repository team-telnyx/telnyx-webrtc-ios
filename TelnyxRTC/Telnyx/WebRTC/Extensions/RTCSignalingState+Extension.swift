import WebRTC

extension RTCSignalingState {
    func telnyx_to_string() -> String {
        switch self {
            case .stable: return "stable"
            case .haveLocalOffer: return "have-local-offer"
            case .haveLocalPrAnswer: return "have-local-pr-answer"
            case .haveRemoteOffer: return "have-remote-offer"
            case .haveRemotePrAnswer: return "have-remote-pr-answer"
            case .closed: return "closed"
            @unknown default: return "unknown"
        }
    }
}
