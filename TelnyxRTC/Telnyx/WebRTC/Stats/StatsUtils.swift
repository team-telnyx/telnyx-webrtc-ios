import WebRTC

class StatsUtils {
    
    static func extractUfrag(from input: String) -> String? {
        // Expresión regular para capturar el valor de ufrag
        let pattern = "ufrag\\s+(\\w+)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: input.utf16.count)
            
            // Buscar el patrón en el string
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                // Obtener el valor del ufrag que está en el primer grupo de captura (el valor después de "ufrag")
                if let ufragRange = Range(match.range(at: 1), in: input) {
                    return String(input[ufragRange])
                }
            }
        } catch {
            print("Error al crear la expresión regular: \(error)")
        }
        
        return nil
    }
    
    static func mapIceServers(_ iceServers: [RTCIceServer]) -> [[String: Any]] {
        return iceServers.map { mapIceServer($0) }
    }

    static func mapIceServer(_ iceServer: RTCIceServer) -> [String: Any] {
        return [
            "urlStrings": iceServer.urlStrings,
            "username": iceServer.username ?? NSNull(),
            "credential": iceServer.credential ?? NSNull(),
            "tlsCertPolicy": mapTlsCertPolicy(iceServer.tlsCertPolicy),
            "hostname": iceServer.hostname ?? NSNull(),
            "tlsAlpnProtocols": iceServer.tlsAlpnProtocols.isEmpty ? NSNull() : iceServer.tlsAlpnProtocols,
            "tlsEllipticCurves": iceServer.tlsEllipticCurves.isEmpty ? NSNull() : iceServer.tlsEllipticCurves
        ]
    }
    
    static func mapTlsCertPolicy(_ policy: RTCTlsCertPolicy) -> String {
        switch policy {
            case .secure: return "secure"
            case .insecureNoCheck: return "insecureNoCheck"
            @unknown default: return "unknown"
        }
    }
    
    static func mapBundlePolicy(_ semantics: RTCBundlePolicy) -> String {
        switch semantics {
            case .balanced: return "balanced"
            case .maxBundle: return "maxBundle"
            case .maxCompat: return "maxCompat"
            @unknown default: return "unknown"
        }
    }

    static func mapSdpSemantics(_ semantics: RTCSdpSemantics) -> String {
        switch semantics {
            case .planB: return "planB"
            case .unifiedPlan: return "unifiedPlan"
            @unknown default: return "unknown"
        }
    }
    
    static func mapContinualGatheringPolicy(_ policy: RTCContinualGatheringPolicy) -> String {
        switch policy {
            case .gatherContinually: return "gatherContinually"
            case .gatherOnce: return "gatherOnce"
            @unknown default: return "unknown"
        }
    }
    
    static func mapRtcpMuxPolicy(_ policy: RTCRtcpMuxPolicy) -> String {
        switch policy {
            case .negotiate: return "negotiate"
            case .require: return "require"
            @unknown default: return "unknown"
        }
    }
    
    static func mapTransportPolicy(_ policy: RTCIceTransportPolicy) -> String {
        switch policy {
            case .all: return "all"
            case .noHost: return "noHost"
            case .none: return "none"
            case .relay: return "relay"
            @unknown default: return "unknown"
        }
    }
    
    static func mapSignalingState(_ state: RTCSignalingState) -> String {
        switch state {
            case .stable: return "stable"
            case .haveLocalOffer: return "have-local-offer"
            case .haveLocalPrAnswer: return "have-local-pr-answer"
            case .haveRemoteOffer: return "have-remote-offer"
            case .haveRemotePrAnswer: return "have-remote-pr-answer"
            case .closed: return "closed"
            @unknown default: return "unknown"
        }
    }
    
    static func mapIceConnectionState(_ state: RTCIceConnectionState) -> String {
        switch state {
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
    
    static func mapIceGatheringState(_ state: RTCIceGatheringState) -> String {
        switch state {
            case .new: return "new"
            case .gathering: return "gathering"
            case .complete: return "complete"
            @unknown default: return "unknown"
        }
    }
    
    static func getStreamDetails(stream: RTCMediaStream) -> [String: Any] {
        var data = [String : Any]()
        data["id"] = stream.streamId
        return data
    }
    
    static func getAudioTrackDetails(track: RTCMediaStreamTrack) -> [String: Any] {
        var data = [String : Any]()
        data["enabled"] = track.isEnabled
        data["id"] = track.trackId
        data["kind"] = track.kind
        data["readyState"] = track.readyState.rawValue
        return data
    }
    
}
