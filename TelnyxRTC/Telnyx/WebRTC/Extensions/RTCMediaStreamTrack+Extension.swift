import WebRTC
import Foundation

extension RTCMediaStreamTrack {
    func telnyx_to_stats_dictionary() -> [String: Any] {
        return [
            "enabled": self.isEnabled,
            "id": self.trackId,
            "kind": self.kind,
            "readyState": self.readyState.rawValue
        ]
    }
}

