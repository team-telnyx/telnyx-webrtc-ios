import SwiftUI
import TelnyxRTC
import Combine


class HomeViewModel: ObservableObject {
    @Published var socketState: SocketState = .disconnected
    @Published var sessionId: String = "-"
    @Published var environment: String = "-"
    @Published var isLoading: Bool = false
    @Published var seletedRegion: Region = Region.auto
    @Published var callState: CallState = .DONE(reason: nil)
    @Published var preCallDiagnosisState: PreCallDiagnosisState?
    
    // Connection timeout in seconds
    let connectionTimeout: TimeInterval = 30.0
    
    // PreCall Diagnostic Manager
    @Published var preCallDiagnosticManager = PreCallDiagnosticManager.shared
    
    // Publisher for PreCall Diagnosis state updates
    var preCallDiagnosisStatePublisher: AnyPublisher<PreCallDiagnosisState?, Never> {
        $preCallDiagnosisState.eraseToAnyPublisher()
    }
    
    // Reference to TxClient for PreCall Diagnosis
    private var txClient: TxClient?
    private var cancellables = Set<AnyCancellable>()
    
    /// Computed property to determine if calls are active
    /// When calls are active, region selection and pre-call diagnosis should be disabled
    var isCallsActive: Bool {
        guard let client = txClient else { return false }
        
        // Check if any call is in an active state (not NEW or DONE)
        return !client.calls.filter { 
            switch $0.value.callState {
            case .DONE, .NEW:
                return false
            default:
                return true
            }
        }.isEmpty
    }
    
    /// Computed property to determine if region selection should be disabled
    /// Region selection is disabled when:
    /// 1. There are active calls
    /// 2. The client is connected (to prevent connection disruption)
    var isRegionSelectionDisabled: Bool {
        return isCallsActive || socketState == .connected || socketState == .clientReady
    }
    
    /// Computed property to determine if pre-call diagnosis should be disabled
    var isPreCallDiagnosisDisabled: Bool {
        return isCallsActive
    }
    
    init() {
        setupPreCallDiagnosticManager()
    }
    
    func setTxClient(_ client: TxClient) {
        self.txClient = client
        preCallDiagnosticManager.setTelnyxClient(client)
    }
    
    func startPreCallDiagnosis(destinationNumber: String, duration: TimeInterval = 40.0) {
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
