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
        //self.executeEndCallAction(uuid: self.callKitUUID ?? UUID())
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

        self.callKitUUID = call.callInfo?.callId
        self.previousCall = self.currentCall
        self.currentCall = call //Update the current call with the incoming call
        let headers = call.inviteCustomHeaders
        print("\n Custom Headers onIncomingCall: \(String(describing: headers)) \n")
        self.newIncomingCall(from: call.callInfo?.callerName ?? "Unknown", uuid: callId)
        self.voipDelegate?.onIncomingCall(call: call)
    }
    
    func onPushCall(call: Call) {
        print("AppDelegate:: TxClientDelegate onPushCall() \(call)")
        self.currentCall = call //Update the current call with the incoming call
        let headers = call.inviteCustomHeaders
        print("Custom Headers onPushCall: \(headers as AnyObject)")
    }
    
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason? = nil) {
        print("AppDelegate:: TxClientDelegate onRemoteCallEnded() callKitUUID [\(String(describing: self.callKitUUID))] callId [\(callId)], reason: \(reason?.cause ?? "None")")
        
        // If we have a SIP code, use it for the disconnect cause
        var disconnectCause = CXCallEndedReason.remoteEnded
        if let sipCode = reason?.sipCode {
            if sipCode == 486 || sipCode == 600 {
                disconnectCause = .unanswered
            } else if sipCode == 403 {
                disconnectCause = .failed
            } else if sipCode == 404 {
                disconnectCause = .failed
            }
        }
        
        reportCallEnd(callId: callId, reason: disconnectCause)
        
        if (previousCall?.callInfo?.callId == callId) {
            self.previousCall = nil
        }
        
        if (currentCall?.callInfo?.callId == callId) {
            self.currentCall = nil
        }
        self.voipDelegate?.onRemoteCallEnded(callId: callId, reason: reason)
    }
    
    func reportCallEnd(callId:UUID, reason: CXCallEndedReason = .remoteEnded){
         if let provider = self.callKitProvider {
            provider.reportCall(with: callId, endedAt: Date(), reason: reason)
        }
        
        /*let endCallAction = CXEndCallAction(call: callId)
        let transaction = CXTransaction(action: endCallAction)
        
        callKitCallController.request(transaction) { error in
            if let error = error {
                debugPrint("executeEndCallAction transaction request failed: \(error.localizedDescription)")
                return
            }
        } */
    }
    
    func isCallActive(with uuid: UUID) -> Bool {
        let callController = self.callKitCallController
        let calls = callController.callObserver.calls
        
        // Look for a call with the given UUID
        for call in calls {
            if call.uuid == uuid {
                return call.hasConnected && !call.hasEnded
            }
        }
        
        // If no call with the given UUID is found or it's not active, return false
        return false
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        print("AppDelegate:: TxClientDelegate onCallStateUpdated() callKitUUID [\(String(describing: self.callKitUUID))] callId [\(callId)]")
        self.voipDelegate?.onCallStateUpdated(callState: callState, callId: callId)
        
        if callState.isConsideredActive {
            // check if custom headers was passed for answered message
            let headers = self.currentCall?.answerCustomHeaders
            print("Custom Headers: \(headers as AnyObject)")
        }
        // Track call state changes in call history
        if let call = self.telnyxClient?.calls[callId] {
            CallHistoryManager.shared.handleCallStateChange(call: call, previousState: nil)
        }
        
        if case .DONE = callState {
            if let currentCallId = self.currentCall?.callInfo?.callId,
               currentCallId == callId {
               self.currentCall = nil // clear current call
            }
        }
    }
}
