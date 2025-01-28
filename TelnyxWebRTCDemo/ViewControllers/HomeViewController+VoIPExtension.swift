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
    }
    
    func onSocketDisconnected() {
        print("ViewController:: TxClientDelegate onSocketDisconnected()")
        let noActiveCalls = self.telnyxClient?.calls.filter { $0.value.callState == .ACTIVE || $0.value.callState == .HELD }.isEmpty
        
        // Re-connection logic
        if noActiveCalls != true {
            self.reachability.whenReachable = { reachability in
                if reachability.connection == .wifi {
                    print("Reachable via WiFi")
                    self.handleConnect()
                } else {
                    print("Reachable via Cellular")
                    self.handleConnect()
                }
            }
            return
        }
        
        DispatchQueue.main.async {
            self.viewModel.isLoading = false
            self.viewModel.socketState = .disconnected
        }
    }
    
    func onClientError(error: Error) {
        print("ViewController:: TxClientDelegate onClientError() error: \(error)")
        let noActiveCalls = self.telnyxClient?.calls.filter { $0.value.callState == .ACTIVE || $0.value.callState == .HELD }.isEmpty
        
        if noActiveCalls != true {
            return
        }
        
        DispatchQueue.main.async {
            self.viewModel.isLoading = false
            self.viewModel.socketState = .disconnected
            self.appDelegate.executeEndCallAction(uuid: UUID());
            
            if error.self is NWError {
                print("ERROR: socket connectiontion error \(error)")
            } else {
                print("ERROR: client error \(error)")
            }
        }
        
        self.telnyxClient?.disconnect()
    }
    
    func onClientReady() {
        print("ViewController:: TxClientDelegate onClientReady()")
        DispatchQueue.main.async {
            self.viewModel.isLoading = false
            self.viewModel.socketState = .connected
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
//            self.updateButtonsState()
//            self.incomingCallView.isHidden = false
//            self.callView.isHidden = true
//            //Hide the keyboard
//            self.view.endEditing(true)
        }
    }
    
    func onRemoteCallEnded(callId: UUID) {
        print("ViewController:: TxClientDelegate onRemoteCallEnded() callId: \(callId)")
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        DispatchQueue.main.async {
            switch (callState) {
                case .CONNECTING:
                    break
                case .RINGING:
                    break
                case .NEW:
                    break
                case .ACTIVE:
//                    self.incomingCallView.isHidden = true
//                    self.callView.isHidden = false
                    if self.appDelegate.isCallOutGoing {
                        self.appDelegate.executeOutGoingCall()
                    }
                    break
                case .DONE:
                    // self.resetCallStates()
                    break
                case .HELD:
                    break
            }
//            self.updateButtonsState()
        }
    }
    
    func executeCall(callUUID: UUID, completionHandler: @escaping (Call?) -> Void) {
//        do {
//            guard let callerName = self.settingsView.callerIdNameLabel.text,
//                  let callerNumber = self.settingsView.callerIdNumberLabel.text,
//                  let destinationNumber = self.callView.destinationNumberOrSip.text else {
//                print("ERROR: executeCall can't be performed. Check callerName - callerNumber and destinationNumber")
//                return
//            }
//            let headers =  [
//                "X-test1":"ios-test1",
//                "X-test2":"ios-test2"
//            ]
//            
//            let call = try telnyxClient?.newCall(callerName: callerName,
//                                                 callerNumber: callerNumber,
//                                                 destinationNumber: destinationNumber,
//                                                 callId: callUUID,customHeaders: headers)
//            completionHandler(call)
//        } catch let error {
//            print("ViewController:: executeCall Error \(error)")
//            completionHandler(nil)
//        }
    }
}
