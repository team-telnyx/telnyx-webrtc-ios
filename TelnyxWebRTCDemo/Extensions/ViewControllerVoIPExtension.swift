//
//  ViewControllerVoIPExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 25/08/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.

import Foundation
import UIKit
import AVFoundation
import CallKit
import PushKit
import TelnyxRTC

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
        DispatchQueue.main.async {
            self.removeLoadingView()
            self.resetCallStates()
            self.socketStateLabel.text = "Disconnected"
            self.connectButton.setTitle("Connect", for: .normal)
            self.sessionIdLabel.text = "-"
            self.settingsView.isHidden = false
            self.callView.isHidden = true
            self.incomingCallView.isHidden = true
        }
    }
    
    func onClientError(error: Error) {
        print("ViewController:: TxClientDelegate onClientError() error: \(error)")
        DispatchQueue.main.async {
            self.removeLoadingView()
            self.incomingCallView.isHidden = true
            self.telnyxClient?.disconnect()
            
            let alert = UIAlertController(title: "WebRTC error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
        }
    }
    
    func onClientReady() {
        print("ViewController:: TxClientDelegate onClientReady()")
        DispatchQueue.main.async {
            self.removeLoadingView()
            self.socketStateLabel.text = "Client ready"
            self.settingsView.isHidden = true
            self.callView.isHidden = false
            self.incomingCallView.isHidden = true
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
    
    func onRemoteCallEnded(callId: UUID) {
        print("ViewController:: TxClientDelegate onRemoteCallEnded() callId: \(callId)")
        let reason = CXCallEndedReason.remoteEnded
        if let provider = appDelegate.callKitProvider {
            provider.reportCall(with: callId, endedAt: Date(), reason: reason)
        }
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
                    break
                case .DONE:
                    self.resetCallStates()
                    break
                case .HELD:
                    break
            }
            self.updateButtonsState()
        }
    }
    
    func executeCall(action: CXStartCallAction, completionHandler: @escaping (Call?) -> Void) {
        do {
            guard let callerName = self.settingsView.callerIdNameLabel.text,
                  let callerNumber = self.settingsView.callerIdNumberLabel.text,
                  let destinationNumber = self.callView.destinationNumberOrSip.text else {
                print("ERROR: executeCall can't be performed. Check callerName - callerNumber and destinationNumber")
                return
            }
            
            let call = try telnyxClient?.newCall(callerName: callerName,
                                                         callerNumber: callerNumber,
                                                         destinationNumber: destinationNumber,
                                                         callId: action.callUUID)
            completionHandler(call)
        } catch let error {
            print("ViewController:: executeCall Error \(error)")
            completionHandler(nil)
        }
    }

    func executeAnswerCall(uuid: UUID, completionHandler: @escaping (_ success: Bool) -> Void) {
        // TODO: Update ui
    }
    
    func executeEndCall(uuid: UUID, completionHandler: @escaping (Bool) -> Void) {
		// TODO: update UI
    }
    
    func onPushNotificationReceived(payload: PKPushPayload) {
        // no-op for now
    }
}
