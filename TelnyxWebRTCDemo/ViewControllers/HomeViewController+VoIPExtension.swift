import Foundation
import UIKit
import AVFoundation
import PushKit
import TelnyxRTC
import Network

// MARK: - VoIPDelegate
extension HomeViewController : VoIPDelegate {
    
    func onSocketConnected() {
        print("ViewController:: TxClientDelegate onSocketConnected()")
        DispatchQueue.main.async {
            self.viewModel.socketState = .connected
            self.sipCredentialsVC.dismiss(animated: false)
        }
        // Don't stop the timer here, wait for onClientReady
    }
    
    func onSocketDisconnected() {
        print("ViewController:: TxClientDelegate onSocketDisconnected()")
        
        // Stop the connection timer if it's running
        stopConnectionTimer()
        
        DispatchQueue.main.async {
            self.viewModel.isLoading = false
            self.viewModel.socketState = .disconnected
        }
    }
    
    func onClientError(error: Error) {
        print("ViewController:: TxClientDelegate onClientError() error: \(error)")
        let noActiveCalls = self.telnyxClient?.calls.filter { $0.value.callState.isConsideredActive }.isEmpty
        
        // Stop the connection timer if it's running
        stopConnectionTimer()
        
        if noActiveCalls != true {
            return
        }
        
        DispatchQueue.main.async {
            self.appDelegate.executeEndCallAction(uuid: UUID());
            
            if error.self is NWError {
                print("ERROR: socket connectiontion error \(error)")
                self.showAlert(message: "\(error)")
            } else if(error is TxError) {
                let txError = error as! TxError
                switch txError {
                    case .socketConnectionFailed(let reason):
                        print("Socket Connection Error: \(reason.localizedDescription ?? "Unknown reason")")
                        
                    case .clientConfigurationFailed(let reason):
                        print("Client Configuration Error: \(reason.localizedDescription ?? "Unknown reason")")
                        
                    case .callFailed(let reason):
                        print("Call Failure: \(reason.localizedDescription ?? "Unknown reason")")
                        self.showAlert(message: reason.localizedDescription ?? "")

                    case .serverError(let reason):
                        self.telnyxClient?.disconnect()
                        self.viewModel.isLoading = false
                        self.viewModel.socketState = .disconnected
                        
                        // Check if it's a signaling server error
                        if case .signalingServerError(let message, let code) = reason {
                            print("Signaling Server Error: \(message) (Code: \(code))")
                            // Display a popup with the error message
                            let codeInt = Int(code) ?? 0
                            self.showErrorPopup(title: "Signaling Server Error", message: self.formatSignalingErrorMessage(causeCode: codeInt, message: message))
                        } else {
                            print("Server Error: \(reason.localizedDescription)")
                        }
                    }
                print("ERROR: client error \(error)")
            }
        }
    }
    
    func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            self.present(alert, animated: true)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                alert.dismiss(animated: true)
            }
        }
    }
    
    func showErrorPopup(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    /// Formats a signaling server error message based on the cause code
    /// - Parameters:
    ///   - causeCode: The error code from the signaling server
    ///   - message: The error message from the signaling server
    /// - Returns: A user-friendly error message
    func formatSignalingErrorMessage(causeCode: Int, message: String) -> String {
        // Map error codes to user-friendly messages
        switch causeCode {
        case -32000:
            return "Token registration error: \(message)"
        case -32001:
            return "Credential registration error: \(message)"
        case -32002:
            return "Codec error: \(message)"
        case -32003:
            return "Gateway registration timeout: \(message)"
        case -32004:
            return "Gateway registration failed: \(message)"
        default:
            if message.contains("Call not found") {
                return "Call not found: The specified call cannot be found"
            }
            return message
        }
    }
    
    func onClientReady() {
        print("ViewController:: TxClientDelegate onClientReady()")
        
        // Stop the connection timer as the connection is now established
        stopConnectionTimer()
        
        DispatchQueue.main.async {
            self.viewModel.isLoading = false
            self.viewModel.socketState = .clientReady
        }
    }
    
    func onSessionUpdated(sessionId: String) {
        print("ViewController:: TxClientDelegate onSessionUpdated() sessionId: \(sessionId)")
        DispatchQueue.main.async {
            self.viewModel.sessionId = sessionId
        }
    }
    
    func onIncomingCall(call: Call) {
        self.incomingCall = true
        DispatchQueue.main.async {
            self.callViewModel.callState = call.callState
            self.viewModel.callState = call.callState
            //Hide the keyboard
            self.view.endEditing(true)
        }
    }
    
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason? = nil) {
        print("ViewController:: TxClientDelegate onRemoteCallEnded() callId: \(callId), reason: \(reason?.cause ?? "None")")
        
        // We no longer show a popup here as the termination reason is displayed inline in the UI
        // The call state will be updated through onCallStateUpdated with the termination reason
    }
    
    private func formatTerminationReason(reason: CallTerminationReason) -> String {
        // If we have a SIP code and reason, use that
        if let sipCode = reason.sipCode, let sipReason = reason.sipReason {
            return "\(sipReason) (SIP \(sipCode))"
        }
        
        // If we have just a SIP code
        if let sipCode = reason.sipCode {
            return "Call ended with SIP code: \(sipCode)"
        }
        
        // If we have a cause
        if let cause = reason.cause {
            switch cause {
            case "USER_BUSY":
                return "Call ended: User busy"
            case "CALL_REJECTED":
                return "Call ended: Call rejected"
            case "UNALLOCATED_NUMBER":
                return "Call ended: Invalid number"
            case "NORMAL_CLEARING":
                return "Call ended normally"
            default:
                return "Call ended: \(cause)"
            }
        }
        
        return "Call ended"
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        DispatchQueue.main.async {
            self.callViewModel.callState = callState
            self.viewModel.callState = callState
            
            // Forward call state changes to HomeViewModel for PreCall Diagnosis
            self.viewModel.handleCallStateChange(callId: callId, callState: callState)

            print("CallState : \(callState)")
            switch (callState) {
                case .CONNECTING:
                    break
                case .RINGING:
                    break
                case .NEW:
                    break
                case .ACTIVE:
                    if let call = self.appDelegate.currentCall {
                        call.onCallQualityChange = { qualityMetric in
                            print("metric_values: \(qualityMetric)")
                            DispatchQueue.main.async {
                                self.callViewModel.callQualityMetrics = qualityMetric
                                // Forward metrics to HomeViewModel for PreCall Diagnosis
                                self.viewModel.handleCallQualityMetrics(qualityMetric)
                            }
                        }
                    }
                    if self.appDelegate.isCallOutGoing {
                        print("Outgoing_reported")
                        self.appDelegate.executeOutGoingCall()
                    }
                    break
                case .DONE(let reason):
                    // Handle call termination reason if needed
                    if let reason = reason {
                        print("Call ended with reason: \(reason.cause ?? "Unknown"), SIP code: \(reason.sipCode ?? 0)")
                    }
                    // self.resetCallStates()
                    break
                case .HELD:
                    break
                case .RECONNECTING(reason: _):
                    break
                case .DROPPED(reason: _):
                    break
            }
//            self.updateButtonsState()
        }
    }
    
    func executeCall(callUUID: UUID, completionHandler: @escaping (Call?) -> Void) {
        do {
            guard let sipCred = SipCredentialsManager.shared.getSelectedCredential() else {
                print("ERROR: executeCall can't be performed. Check callerName - callerNumber and destinationNumber")
                return
            }
            let headers =  [
                "X-test1":"ios-test1",
                "X-test2":"ios-test2"
            ]
            
            let destinationNumber = self.callViewModel.sipAddress
            
            let call = try telnyxClient?.newCall(callerName: sipCred.callerName ?? "",
                                                 callerNumber: sipCred.callerNumber ?? "",
                                                 destinationNumber: destinationNumber,
                                                 callId: callUUID,customHeaders: headers,debug: true)
            completionHandler(call)
        } catch let error {
            print("HomeViewController:: executeCall Error \(error)")
            completionHandler(nil)
        }
    }
    

    
    func onPushDisabled(success: Bool, message: String) {
        print("HomeViewController:: onPushDisabled() success: \(success), message: \(message)")
        DispatchQueue.main.async {
            // Handle push notification disable result if needed
            // Could show an alert or update UI state
        }
    }
    
    func onPushCall(call: Call) {
        print("HomeViewController:: onPushCall() callId: \(call.callInfo?.callId ?? UUID())")
        DispatchQueue.main.async {
            self.callViewModel.callState = call.callState
            self.viewModel.callState = call.callState
            // Hide the keyboard
            self.view.endEditing(true)
        }
    }
}
