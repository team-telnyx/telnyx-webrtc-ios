import WebRTC
import Foundation

// MARK: - RTCIceServer Extension
extension RTCIceServer {
    func telnyx_to_stats_dictionary() -> [String: Any] {
        return [
            "urlStrings": self.urlStrings,
            "username": self.username ?? NSNull(),
            "credential": self.credential ?? NSNull(),
            "tlsCertPolicy": self.tlsCertPolicy.telnyx_to_string(),
            "hostname": self.hostname ?? NSNull(),
            "tlsAlpnProtocols": self.tlsAlpnProtocols.isEmpty ? NSNull() : self.tlsAlpnProtocols,
            "tlsEllipticCurves": self.tlsEllipticCurves.isEmpty ? NSNull() : self.tlsEllipticCurves
        ]
    }
}
