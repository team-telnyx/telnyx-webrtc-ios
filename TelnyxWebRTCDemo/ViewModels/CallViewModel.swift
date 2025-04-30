import SwiftUI
import TelnyxRTC

class CallViewModel: ObservableObject {
    @Published var sipAddress: String = ""
    @Published var isMuted: Bool = false
    @Published var isSpeakerOn: Bool = false
    @Published var callState: CallState = .DONE
    @Published var isOnHold: Bool = false
    @Published var showDTMFKeyboard: Bool = false
    @Published var showCallMetricsPopup = false
    @Published var callQualityMetrics: CallQualityMetrics? = nil
}
