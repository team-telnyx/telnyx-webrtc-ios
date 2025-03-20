import SwiftUI
import TelnyxRTC

class HomeViewModel: ObservableObject {
    @Published var socketState: SocketState = .disconnected
    @Published var sessionId: String = "-"
    @Published var environment: String = "-"
    @Published var isLoading: Bool = false
    @Published var callState: CallState = .DONE
    
    // Connection timeout in seconds
    let connectionTimeout: TimeInterval = 30.0
}
