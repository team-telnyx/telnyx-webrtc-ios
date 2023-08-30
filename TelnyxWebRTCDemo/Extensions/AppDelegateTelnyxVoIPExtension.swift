//
//  AppDelegateTelnyxVoIPExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 07/09/2021.
//

import Foundation
import TelnyxRTC
import CallKit

extension AppDelegate: TxClientDelegate {
    
    
    func onPushDisabled(success: Bool, message: String) {
        print("AppDelegate:: TxClientDelegate onPushDisabled()")
    }
    
    
    
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
        guard let callId = call.callInfo?.callId else {
            print("AppDelegate:: TxClientDelegate onIncomingCall() Error unknown call UUID")
            return
        }
        print("AppDelegate:: TxClientDelegate onIncomingCall() callKitUUID [\(String(describing: self.callKitUUID))] callId [\(callId)]")

        if let currentCallUUID = self.currentCall?.callInfo?.callId {
            print("AppDelegate:: TxClientDelegate onIncomingCall() end previous call [\(currentCallUUID)]")
            executeEndCallAction(uuid: currentCallUUID) //Hangup the previous call if there's one active
        }
        self.callKitUUID = call.callInfo?.callId
        self.currentCall = call //Update the current call with the incoming call
        self.newIncomingCall(from: call.callInfo?.callerName ?? "Unknown", uuid: callId)
        self.voipDelegate?.onIncomingCall(call: call)
    }
    
    func onPushCall(call: Call) {
        print("AppDelegate:: TxClientDelegate onPushCall() \(call)")
        self.currentCall = call //Update the current call with the incoming call
    }
    
    func onRemoteCallEnded(callId: UUID) {
        print("AppDelegate:: TxClientDelegate onRemoteCallEnded() callKitUUID [\(String(describing: self.callKitUUID))] callId [\(callId)]")
        self.voipDelegate?.onRemoteCallEnded(callId: callId)
        let reason = CXCallEndedReason.remoteEnded
        if let provider = self.callKitProvider,
           let callKitUUID = self.callKitUUID {
            provider.reportCall(with: callKitUUID, endedAt: Date(), reason: reason)
        }
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        print("AppDelegate:: TxClientDelegate onCallStateUpdated() callKitUUID [\(String(describing: self.callKitUUID))] callId [\(callId)]")
        self.voipDelegate?.onCallStateUpdated(callState: callState, callId: callId)
        
        if callState == .DONE {
            if let currentCallId = self.currentCall?.callInfo?.callId,
               currentCallId == callId {
                self.currentCall = nil // clear current call
            }
        }
    }
}
