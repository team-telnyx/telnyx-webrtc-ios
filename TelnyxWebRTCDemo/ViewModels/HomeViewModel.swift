import SwiftUI
import TelnyxRTC
import Combine


class HomeViewModel: ObservableObject {
    @Published var socketState: SocketState = .disconnected
    @Published var sessionId: String = "-"
    @Published var environment: String = "-"
    @Published var isLoading: Bool = false
    @Published var callState: CallState = .DONE(reason: nil)
    @Published var preCallDiagnosisState: PreCallDiagnosisState?
    
    // Connection timeout in seconds
    let connectionTimeout: TimeInterval = 30.0
    
    // PreCall Diagnostic Manager
    @Published var preCallDiagnosticManager = PreCallDiagnosticManager()
    
    // Publisher for PreCall Diagnosis state updates
    var preCallDiagnosisStatePublisher: AnyPublisher<PreCallDiagnosisState?, Never> {
        $preCallDiagnosisState.eraseToAnyPublisher()
    }
    
    // Reference to TxClient for PreCall Diagnosis
    private var txClient: TxClient?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupPreCallDiagnosticManager()
    }
    
    func setTxClient(_ client: TxClient) {
        self.txClient = client
        preCallDiagnosticManager.setTelnyxClient(client)
    }
    
    func startPreCallDiagnosis(destinationNumber: String, duration: TimeInterval = 10.0) {
        preCallDiagnosticManager.startPreCallDiagnosis(
            destinationNumber: destinationNumber,
            duration: duration
        )
    }
    
    func updatePreCallDiagnosisState(_ state: PreCallDiagnosisState) {
        DispatchQueue.main.async {
            self.preCallDiagnosisState = state
            self.preCallDiagnosticManager.updateState(state)
        }
    }
    
    /// Handles call state changes and forwards them to PreCallDiagnosticManager
    /// - Parameters:
    ///   - callId: The call ID
    ///   - callState: The new call state
    func handleCallStateChange(callId: UUID, callState: CallState) {
        preCallDiagnosticManager.handleCallStateChange(callId: callId, callState: callState)
    }
    
    /// Handles call quality metrics and forwards them to PreCallDiagnosticManager
    /// - Parameter metrics: The call quality metrics
    func handleCallQualityMetrics(_ metrics: CallQualityMetrics) {
        preCallDiagnosticManager.collectMetrics(metrics)
    }
    
    // MARK: - Private Methods
    
    private func setupPreCallDiagnosticManager() {
        preCallDiagnosticManager.delegate = self
        
        // Observe state changes from the manager
        preCallDiagnosticManager.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.preCallDiagnosisState = state
            }
            .store(in: &cancellables)
    }
}

// MARK: - PreCallDiagnosticManagerDelegate

extension HomeViewModel: PreCallDiagnosticManagerDelegate {
    func preCallDiagnosticManager(_ manager: PreCallDiagnosticManager, didUpdateState state: PreCallDiagnosisState?) {
        DispatchQueue.main.async {
            self.preCallDiagnosisState = state
        }
    }
}
