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
            
            
            if(error.self is NWError){
                print("ERROR: socket connectiontion error \(error)")
            } else {
                print("ERROR: client error \(error)")
               
            }
           
        }
    }
    
    func onClientReady() {
        print("ViewController:: TxClientDelegate onClientReady()")
        DispatchQueue.main.async {
            self.removeLoadingView()
            self.socketStateLabel.text = "Client ready"
            self.settingsView.isHidden = true
            self.callView.isHidden = false
            if(!self.incomingCall){
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
    
    func onRemoteCallEnded(callId: UUID) {
        print("ViewController:: TxClientDelegate onRemoteCallEnded() callId: \(callId)")
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        DispatchQueue.main.async {
            switch (callState) {
                case .CONNECTING:
                    break
                case .RINGING:
                    self.setCurrentAudioOutput()
                    break
                case .NEW:
                    break
                case .ACTIVE:
                    self.incomingCallView.isHidden = true
                    self.callView.isHidden = false
                    if(self.isCallOutGoing()){
                        self.appDelegate.executeOutGoingCall()
                    }
                    self.setCurrentAudioOutput()
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
            
            let call = try telnyxClient?.newCall(callerName: callerName,
                                                 callerNumber: callerNumber,
                                                 destinationNumber: destinationNumber,
                                                 callId: callUUID,customHeaders: ["X-test1":"ios-test1",
                                                                                  "X-test2":"ios-test2"])
            completionHandler(call)
        } catch let error {
            print("ViewController:: executeCall Error \(error)")
            completionHandler(nil)
        }
    }
}
