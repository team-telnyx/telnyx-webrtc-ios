import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var socketState: SocketState = .disconnected
    @Published var selectedProfile: SipCredential? = nil
    @Published var sessionId: String = "-"
    @Published var environment: String = "-"
}
