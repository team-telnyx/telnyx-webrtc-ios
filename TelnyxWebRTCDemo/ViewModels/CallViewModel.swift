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
    @Published var errorMessage: String = ""
    
    /// The current active call object, used for accessing media streams
    @Published var currentCall: Call? = nil
}
