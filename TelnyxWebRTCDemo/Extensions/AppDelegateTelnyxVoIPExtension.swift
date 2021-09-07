//
//  AppDelegateTelnyxVoIPExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 07/09/2021.
//

import Foundation
import TelnyxRTC

extension AppDelegate: TxClientDelegate {
    func onSocketConnected() {
        print("AppDelegate:: TxClientDelegate onSocketConnected()")
        self.voipDelegate?.onSocketConnected()
    }
    
    func onSocketDisconnected() {
        print("AppDelegate:: TxClientDelegate onSocketDisconnected()")
        self.voipDelegate?.onSocketDisconnected()
    }
    
    func onClientError(error: Error) {
        print("AppDelegate:: TxClientDelegate onClientError() error: \(error)")
        self.voipDelegate?.onClientError(error: error)
    }
    
    func onClientReady() {
        print("AppDelegate:: TxClientDelegate onClientReady()")
        self.voipDelegate?.onClientReady()
    }
    
    func onSessionUpdated(sessionId: String) {
        print("AppDelegate:: TxClientDelegate onSessionUpdated() sessionId: \(sessionId)")
        self.voipDelegate?.onSessionUpdated(sessionId: sessionId)
    }
    
    func onIncomingCall(call: Call) {
        self.voipDelegate?.onIncomingCall(call: call)
//        guard let callId = call.callInfo?.callId else {
//            print("ViewController:: TxClientDelegate onIncomingCall() Error unknown call UUID")
//            return
//        }
//        print("ViewController:: TxClientDelegate onIncomingCall() Error unknown call UUID: \(callId)")
//
//        if let currentCallUUID = self.currentCall?.callInfo?.callId {
//            appDelegate.executeEndCallAction(uuid: currentCallUUID) //Hangup the previous call if there's one active
//        }
//        self.currentCall = call //Update the current call with the incoming call
//        self.incomingCall = true
//        DispatchQueue.main.async {
//            self.updateButtonsState()
//            self.incomingCallView.isHidden = false
//            self.callView.isHidden = true
//            //Hide the keyboard
//            self.view.endEditing(true)
//        }
//        appDelegate.newIncomingCall(from: call.callInfo?.callerName ?? "Unknown", uuid: callId)
    }
    
    func onRemoteCallEnded(callId: UUID) {
        self.voipDelegate?.onRemoteCallEnded(callId: callId)
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        self.voipDelegate?.onCallStateUpdated(callState: callState, callId: callId)
    }
}
