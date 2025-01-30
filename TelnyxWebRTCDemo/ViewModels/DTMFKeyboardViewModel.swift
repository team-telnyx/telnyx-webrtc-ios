import SwiftUI
import TelnyxRTC

class DTMFKeyboardViewModel: ObservableObject {
    @Published var displayText: String = ""
    func clearDisplay() {
        displayText = ""
    }
}
