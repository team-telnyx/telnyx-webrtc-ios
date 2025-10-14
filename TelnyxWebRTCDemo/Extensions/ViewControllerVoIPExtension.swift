//
//  ViewControllerVoIPExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 25/08/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.

import Foundation
import UIKit
import AVFoundation
import PushKit
import TelnyxRTC
import Network

// MARK: - VoIPDelegate
extension ViewController : VoIPDelegate {

    func onSocketConnected() {
        print("ViewController:: TxClientDelegate onSocketConnected()")
        DispatchQueue.main.async {
            self.socketStateLabel.text = "Connected"
            self.connectButton.setTitle("Disconnect", for: .normal)
            
        }
        
    }
    
    func onSocketDisconnected() {
        print("ViewController:: TxClientDelegate onSocketDisconnected()")
        let noActiveCalls = self.telnyxClient?.calls.filter { $0.value.callState.isConsideredActive }.isEmpty
        
        if(noActiveCalls != true){
            self.reachability.whenReachable = { reachability in
                 if reachability.connection == .wifi {
                     print("Reachable via WiFi")
                     self.connectButtonTapped("")
                 } else {
                     print("Reachable via Cellular")
                     self.connectButtonTapped("")
                 }
             } 
            return
        }

        DispatchQueue.main.async {
            self.removeLoadingView()
            self.resetCallStates()
            self.socketStateLabel.text = "Disconnected"
            self.connectButton.setTitle("Connect", for: .normal)
            self.sessionIdLabel.text = "-"
            self.settingsView.isHidden = false
            self.callView.isHidden = false
            self.incomingCallView.isHidden = true
        }
        
      
        
    }
    
    func onClientError(error: Error) {
        print("ViewController:: TxClientDelegate onClientError() error: \(error)")
        let noActiveCalls = self.telnyxClient?.calls.filter { $0.value.callState.isConsideredActive }.isEmpty
        
        if noActiveCalls != true {
            return
        }
        
        DispatchQueue.main.async {
            self.removeLoadingView()
            self.incomingCallView.isHidden = true
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
            self.sipCredentialsVC.dismiss(animated: false)
            self.removeLoadingView()
            self.socketStateLabel.text = "Client ready"
            self.settingsView.isHidden = true
            self.callView.isHidden = false
            if !self.incomingCall {
                self.incomingCallView.isHidden = true
            }
        }
    }
    
    func onSessionUpdated(sessionId: String) {
        print("ViewController:: TxClientDelegate onSessionUpdated() sessionId: \(sessionId)")
        DispatchQueue.main.async {
            self.sessionIdLabel.text = sessionId
        }
    }
    
    func onIncomingCall(call: Call) {
        self.incomingCall = true
        DispatchQueue.main.async {
            self.updateButtonsState()
            self.incomingCallView.isHidden = false
            self.callView.isHidden = true
            //Hide the keyboard
            self.view.endEditing(true)
        }
    }
    
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason? = nil) {
        print("ViewController:: TxClientDelegate onRemoteCallEnded() callId: \(callId), reason: \(reason?.cause ?? "None")")
        
        // Display error message if there's a termination reason
        if let reason = reason {
            DispatchQueue.main.async {
                let message = formatTerminationReason(reason: reason)
                self.showAlert(message: message)
            }
        }
    }
    
    private func formatTerminationReason(reason: CallTerminationReason) -> String {
        // If we have a SIP code and reason, use that
        if let sipCode = reason.sipCode, let sipReason = reason.sipReason {
            return "Call ended: \(sipReason) (SIP \(sipCode))"
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
            switch (callState) {
                case .CONNECTING:
                    break
                case .RINGING:
                    break
                case .NEW:
                    break
                case .ACTIVE:
                    self.incomingCallView.isHidden = true
                    self.callView.isHidden = false
                    if(self.isCallOutGoing()){
                        self.appDelegate.executeOutGoingCall()
                    }
                    break
                case .DONE(let reason):
                    // Handle call termination reason if needed
                    if let reason = reason {
                        print("Call ended with reason: \(reason.cause ?? "Unknown"), SIP code: \(reason.sipCode ?? 0)")
                    }
                    self.resetCallStates()
                    break
                case .HELD:
                    break
            }
            self.updateButtonsState()
        }
    }
    
    func setCurrentAudioOutput(){
        if(self.isSpeakerActive){
            self.telnyxClient?.setSpeaker()
        }
    }
    
    
    func executeCall(callUUID: UUID, completionHandler: @escaping (Call?) -> Void) {
        do {
            guard let callerName = self.settingsView.callerIdNameLabel.text,
                  let callerNumber = self.settingsView.callerIdNumberLabel.text,
                  let destinationNumber = self.callView.destinationNumberOrSip.text else {
                print("ERROR: executeCall can't be performed. Check callerName - callerNumber and destinationNumber")
                return
            }
            let headers =  ["X-test1":"ios-test1",
                            "X-test2":"ios-test2"]

            // Get preferred audio codecs from UserDefaults
            let preferredCodecs = UserDefaults.standard.getPreferredAudioCodecs()

            let call = try telnyxClient?.newCall(callerName: callerName,
                                                 callerNumber: callerNumber,
                                                 destinationNumber: destinationNumber,
                                                 callId: callUUID,
                                                 customHeaders: headers,
                                                 preferredCodecs: preferredCodecs.isEmpty ? nil : preferredCodecs)
            completionHandler(call)
        } catch let error {
            print("ViewController:: executeCall Error \(error)")
            completionHandler(nil)
        }
    }
}
