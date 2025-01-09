import WebRTC

extension RTCMediaStream {
    func telnyx_to_stats_dictionary() -> [String: Any] {
        return ["id": self.streamId]
    }
}
