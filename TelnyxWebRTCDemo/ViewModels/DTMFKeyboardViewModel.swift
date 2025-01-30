import SwiftUI
import TelnyxRTC

class DTMFKeyboardViewModel: ObservableObject {
    @Published var displayText: String = ""
    let currentCall: Call?
    
    init(currentCall: Call? = nil) {
        self.currentCall = currentCall
    }
    
    func sendDTMF(_ value: String) {
        currentCall?.dtmf(value)
        displayText += value
    }
    
    func clearDisplay() {
        displayText = ""
    }
}