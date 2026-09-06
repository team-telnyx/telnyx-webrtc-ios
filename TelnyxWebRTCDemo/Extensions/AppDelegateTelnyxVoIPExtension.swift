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
        print("📞 [ID-MAP] onIncomingCall -> appFacingId: \(callId) | callKitUUID: \(self.callKitUUID?.uuidString ?? "nil") | match: \(callId == self.callKitUUID)")

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
        print("📞 [ID-MAP] onPushCall -> appFacingId: \(call.callInfo?.callId.uuidString ?? "nil") | callKitUUID: \(self.callKitUUID?.uuidString ?? "nil") | match: \(call.callInfo?.callId == self.callKitUUID)")
        self.currentCall = call //Update the current call with the incoming call
        let headers = call.inviteCustomHeaders
        print("Custom Headers onPushCall: \(headers as AnyObject)")
    }
    
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason? = nil) {
        print("AppDelegate:: TxClientDelegate onRemoteCallEnded() callKitUUID [\(String(describing: self.callKitUUID))] callId [\(callId)], reason: \(reason?.cause ?? "None")")
        print("📞 [ID-MAP] onRemoteCallEnded -> callId: \(callId) | callKitUUID: \(self.callKitUUID?.uuidString ?? "nil") | match: \(callId == self.callKitUUID)")
        
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
        print("📞 [ID-MAP] onCallStateUpdated -> state: \(callState) | callId: \(callId) | callKitUUID: \(self.callKitUUID?.uuidString ?? "nil") | match: \(callId == self.callKitUUID)")
        self.voipDelegate?.onCallStateUpdated(callState: callState, callId: callId)
        self.handleMobileBlackboxCallState(callState: callState, callId: callId)
        
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
            }
        }
    }

    func scheduleMobileBlackboxAutoAnswer(callId: UUID) {
        guard TestConfiguration.shouldAutoAnswerMobileBlackboxCalls else {
            return
        }

        mobileBlackboxIncomingCallId = callId
        mobileBlackboxCallbackPending = false
        mobileBlackboxCallbackStarted = false
        mobileBlackboxInboundEndRequested = false

        let delay = TestConfiguration.mobileBlackboxAutoAnswerDelay
        print("MobileBBT:: scheduling auto-answer for \(callId) in \(delay)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self,
                  self.mobileBlackboxIncomingCallId == callId else {
                return
            }

            self.executeAnswerCallAction(uuid: callId)
        }
    }

    func handleMobileBlackboxCallState(callState: CallState, callId: UUID) {
        guard TestConfiguration.isMobileBlackboxAutomationEnabled,
              mobileBlackboxIncomingCallId == callId else {
            return
        }

        switch callState {
        case .ACTIVE:
            handleMobileBlackboxInboundActive(callId: callId)
        case .DONE:
            handleMobileBlackboxInboundDone(callId: callId)
        default:
            break
        }
    }

    private func handleMobileBlackboxInboundActive(callId: UUID) {
        guard TestConfiguration.mobileBlackboxCallbackDestination != nil,
              !mobileBlackboxCallbackPending,
              !mobileBlackboxCallbackStarted else {
            return
        }

        mobileBlackboxCallbackPending = true

        guard !mobileBlackboxInboundEndRequested else {
            return
        }

        mobileBlackboxInboundEndRequested = true
        let delay = TestConfiguration.mobileBlackboxInboundActiveHold
        print("MobileBBT:: inbound call \(callId) is active; ending in \(delay)s before callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self,
                  self.mobileBlackboxIncomingCallId == callId,
                  self.mobileBlackboxCallbackPending else {
                return
            }

            self.executeEndCallAction(uuid: callId)
        }
    }

    private func handleMobileBlackboxInboundDone(callId: UUID) {
        guard mobileBlackboxCallbackPending,
              !mobileBlackboxCallbackStarted else {
            resetMobileBlackboxAutomationIfNeeded(callId: callId)
            return
        }

        let delay = TestConfiguration.mobileBlackboxCallbackDelay
        print("MobileBBT:: inbound call \(callId) ended; starting callback in \(delay)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self,
                  self.mobileBlackboxIncomingCallId == callId,
                  self.mobileBlackboxCallbackPending,
                  !self.mobileBlackboxCallbackStarted else {
                return
            }

            self.startMobileBlackboxCallback()
        }
    }

    private func startMobileBlackboxCallback() {
        guard let destination = TestConfiguration.mobileBlackboxCallbackDestination else {
            print("MobileBBT:: callback skipped because MOBILE_BBT_CALLBACK_DESTINATION is not set")
            return
        }

        guard let sipCred = SipCredentialsManager.shared.getSelectedCredential() else {
            print("MobileBBT:: callback skipped because no selected SIP credential is available")
            return
        }

        let callUUID = UUID()
        let headers = [
            "X-Mobile-BBT": "ios-callback",
            "X-Mobile-BBT-Source": "TelnyxWebRTCDemo"
        ]
        let preferredCodecs = UserDefaults.standard.getPreferredAudioCodecs()

        do {
            let call = try telnyxClient?.newCall(
                callerName: sipCred.callerName ?? "",
                callerNumber: sipCred.callerNumber ?? "",
                destinationNumber: destination,
                callId: callUUID,
                clientState: "ios_mobile_bbt_callback",
                customHeaders: headers,
                preferredCodecs: preferredCodecs.isEmpty ? nil : preferredCodecs,
                debug: true
            )

            previousCall = currentCall
            currentCall = call
            mobileBlackboxCallbackStarted = true
            mobileBlackboxCallbackPending = false
            mobileBlackboxIncomingCallId = nil
            mobileBlackboxInboundEndRequested = false

            CallHistoryManager.shared.handleStartCallAction(
                callId: callUUID,
                destinationNumber: destination,
                callerName: sipCred.callerName ?? ""
            )
            print("MobileBBT:: callback started to \(destination) with callId \(callUUID)")
        } catch let error {
            print("MobileBBT:: callback failed: \(error)")
            mobileBlackboxCallbackPending = false
            mobileBlackboxCallbackStarted = false
            mobileBlackboxIncomingCallId = nil
            mobileBlackboxInboundEndRequested = false
        }
    }

    private func resetMobileBlackboxAutomationIfNeeded(callId: UUID) {
        guard mobileBlackboxIncomingCallId == callId else {
            return
        }

        mobileBlackboxIncomingCallId = nil
        mobileBlackboxCallbackPending = false
        mobileBlackboxInboundEndRequested = false
    }
}
