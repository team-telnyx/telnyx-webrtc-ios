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
    
    static func mapSignalingState(_ state: RTCSignalingState) -> String {
        switch state {
            case .stable: return "stable"
            case .haveLocalOffer: return "have-local-offer"
            case .haveLocalPrAnswer: return "have-ocal-pr-answer"
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
    
}
