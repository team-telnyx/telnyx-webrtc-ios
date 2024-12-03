import WebRTC

extension RTCIceGatheringState {
    func telnyx_to_string() -> String {
        switch self {
            case .new: return "new"
            case .gathering: return "gathering"
            case .complete: return "complete"
            @unknown default: return "unknown"
        }
    }
}
