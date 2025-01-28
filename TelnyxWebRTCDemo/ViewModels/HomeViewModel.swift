import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var socketState: SocketState = .disconnected
    @Published var sessionId: String = "-"
    @Published var environment: String = "-"
    @Published var isLoading: Bool = false
}
