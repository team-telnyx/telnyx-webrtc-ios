import SwiftUI
import TelnyxRTC

class CallViewModel: ObservableObject {
    @Published var sipAddress: String = ""
    @Published var isMuted: Bool = false
    @Published var isSpeakerOn: Bool = false
    @Published var callState: CallState = .DONE(reason: nil)
    @Published var isOnHold: Bool = false
    @Published var showDTMFKeyboard: Bool = false
    @Published var showCallMetricsPopup = false
    @Published var callQualityMetrics: CallQualityMetrics? = nil
    @Published var showErrorPopup = false
    @Published var errorMessage: String = ""
    
    /// Formats the termination reason into a user-friendly message
    func formatTerminationReason(reason: CallTerminationReason?) -> String {
        guard let reason = reason else {
            return "Call ended"
        }
        
        // If we have a SIP code and reason, use that
        if let sipCode = reason.sipCode, let sipReason = reason.sipReason {
            return "Call ended: \(sipReason) (SIP \(sipCode))"
        }
        
        // If we have just a SIP code
        if let sipCode = reason.sipCode {
            return "Call ended with SIP code: \(sipCode)"
        }
        
        // If we have a cause
        if let cause = reason.cause {
            switch cause {
            case "USER_BUSY":
                return "Call ended: User busy"
            case "CALL_REJECTED":
                return "Call ended: Call rejected"
            case "UNALLOCATED_NUMBER":
                return "Call ended: Invalid number"
            case "NORMAL_CLEARING":
                return "Call ended normally"
            default:
                return "Call ended: \(cause)"
            }
        }
        
        return "Call ended"
    }
}
