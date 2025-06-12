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
    
    // Publisher for PreCall Diagnosis state updates
    var preCallDiagnosisStatePublisher: AnyPublisher<PreCallDiagnosisState?, Never> {
        $preCallDiagnosisState.eraseToAnyPublisher()
    }
    
    // Reference to TxClient for PreCall Diagnosis
    private var txClient: TxClient?
    
    func setTxClient(_ client: TxClient) {
        self.txClient = client
    }
    
    func startPreCallDiagnosis(destinationNumber: String, duration: TimeInterval = 10.0) {
        guard let client = txClient else {
            preCallDiagnosisState = .failed(TxError.clientNotReady)
            return
        }
        
        do {
            try client.startPreCallDiagnosis(
                destinationNumber: destinationNumber,
                duration: duration
            )
        } catch {
            preCallDiagnosisState = .failed(error)
        }
    }
    
    func updatePreCallDiagnosisState(_ state: PreCallDiagnosisState) {
        DispatchQueue.main.async {
            self.preCallDiagnosisState = state
        }
    }
}
