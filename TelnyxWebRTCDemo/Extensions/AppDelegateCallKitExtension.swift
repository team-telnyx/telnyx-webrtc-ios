//
//  AppDelegateCallKitExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 25/08/2021.
//

import Foundation
import AVFoundation
import TelnyxRTC
import CallKit

// MARK: - CXProviderDelegate
extension AppDelegate : CXProviderDelegate {

    /// Call this function to tell the CX provider to request the OS to create a new call.
    /// - Parameters:
    ///   - uuid: The UUID of the outbound call
    ///   - handle: A handle for this call
    func executeStartCallAction(uuid: UUID, handle: String) {
        guard let provider = callKitProvider else {
            print("CallKit provider not available")
            return
        }

        let callHandle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        let transaction = CXTransaction(action: startCallAction)

        callKitCallController.request(transaction) { error in
            if let error = error {
                print("StartCallAction transaction request failed: \(error.localizedDescription)")
                return
            }

            print("StartCallAction transaction request successful")

            let callUpdate = CXCallUpdate()
            

            callUpdate.remoteHandle = callHandle
            callUpdate.supportsDTMF = true
            callUpdate.supportsHolding = true
            callUpdate.supportsGrouping = false
            callUpdate.supportsUngrouping = false
            callUpdate.hasVideo = false
            provider.reportCall(with: uuid, updated: callUpdate)
        }
    }
    
    func executeOutGoingCall() {
        if let provider = self.callKitProvider,
           let callKitUUID = self.callKitUUID {
            let date = Date()
            provider.reportOutgoingCall(with: callKitUUID, connectedAt:nil)
            print("Outgoing Call Reported at \(date)")
            self.isCallOutGoing = false
        }
    }

    /// Report a new incoming call. This will generate the Native Incoming call notification
    /// - Parameters:
    ///   - from: Caller name
    ///   - uuid: uuid of the incoming call
    func newIncomingCall(from: String, uuid: UUID) {
        print("AppDelegate:: report NEW incoming call from [\(from)] uuid [\(uuid)]")
        
        // Track incoming call in call history
        CallHistoryManager.shared.handleIncomingCall(
            callId: uuid,
            phoneNumber: from,
            callerName: nil
        )
        
        #if targetEnvironment(simulator)
        //Do not execute this function when debugging on the simulator.
        //By reporting a call through CallKit from the simulator, it automatically cancels the call.
        return
        #endif

        guard let provider = callKitProvider else {
            print("AppDelegate:: CallKit provider not available")
            return
        }

        let callHandle = CXHandle(type: .generic, value: from)
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.hasVideo = false

        provider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
            if let error = error {
                print("AppDelegate:: Failed to report incoming call: \(error.localizedDescription).")
                // Track failed incoming call
                CallHistoryManager.shared.handleCallFailed(callId: uuid)
            } else {
                print("AppDelegate:: Incoming call successfully reported.")
            }
        }
    }
    
    /// To answer a call using CallKit
    /// - Parameter uuid: the UUID of the CallKit call.
    func executeAnswerCallAction(uuid: UUID) {
        print("AppDelegate:: execute ANSWER call action: callKitUUID [\(String(describing: self.callKitUUID))] uuid [\(uuid)]")
        var endUUID = uuid
        if let callkitUUID = self.callKitUUID {
            endUUID = callkitUUID
        }
        let answerCallAction = CXAnswerCallAction(call: endUUID)
        let transaction = CXTransaction(action: answerCallAction)
        callKitCallController.request(transaction) { error in
            if let error = error {
                print("AppDelegate:: AnswerCallAction transaction request failed: \(error.localizedDescription).")
            } else {
                print("AppDelegate:: AnswerCallAction transaction request successful")
            }
        }
    }

    /// End the current call
    /// - Parameter uuid: The uuid of the call
    func executeEndCallAction(uuid: UUID) {
        print("AppDelegate:: execute END call action: callKitUUID [\(String(describing: self.callKitUUID))] uuid [\(uuid)]")

        var endUUID = uuid
        if let callkitUUID = self.callKitUUID {
            endUUID = callkitUUID
        }

        let endCallAction = CXEndCallAction(call: endUUID)
        let transaction = CXTransaction(action: endCallAction)
        

        callKitCallController.request(transaction) { error in
            if let error = error {
                #if targetEnvironment(simulator)
                //The simulator does not support to register an incoming call through CallKit.
                //For that reason when an incoming call is received on the simulator,
                //we are updating the UI and not registering the callID to callkit.
                //When the user wants to hangup the call and the incoming call was not registered in callkit,
                //the CXEndCallAction fails. That's why we are manually ending the call in this case.
                self.telnyxClient?.calls[uuid]?.hangup() // end the active call
                #endif
                print("AppDelegate:: EndCallAction transaction request failed: \(error.localizedDescription).")
            } else {
                print("AppDelegate:: EndCallAction transaction request successful")
            }
            self.callKitUUID = nil
        }
    }
    
    func executeMuteUnmuteAction(uuid: UUID, mute: Bool) {
        let muteAction = CXSetMutedCallAction(call: uuid, muted: mute)
        let transaction = CXTransaction(action: muteAction)
        
        callKitCallController.request(transaction) { error in
            if let error = error {
                print("Error executing mute/unmute action: \(error.localizedDescription)")
            } else {
                print("Successfully executed mute/unmute action. Mute: \(mute)")
            }
        }
    }
    
    // MARK: - CXProviderDelegate -
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("AppDelegate:: START call action: callKitUUID [\(String(describing: self.callKitUUID))] action [\(action.callUUID)]")
        self.callKitUUID = action.callUUID
        self.voipDelegate?.executeCall(callUUID: action.callUUID) { call in
            self.currentCall = call
            if let call = call {
                print("AppDelegate:: performVoiceCall() successful")
                self.isCallOutGoing = true
                
                // Track outgoing call in call history
                if let destinationNumber = call.callOptions?.destinationNumber {
                    CallHistoryManager.shared.handleStartCallAction(
                        action: action,
                        phoneNumber: destinationNumber,
                        callerName: call.callInfo?.callerName
                    )
                }
            } else {
                print("AppDelegate:: performVoiceCall() failed")
                // Track failed call
                CallHistoryManager.shared.handleCallFailed(callId: action.callUUID)
            }
        }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("AppDelegate:: ANSWER call action: callKitUUID [\(String(describing: self.callKitUUID))] action [\(action.callUUID)]")
        
        // Track incoming call answer in call history
        if let call = self.telnyxClient?.calls[action.callUUID] {
            let phoneNumber = call.callInfo?.callerNumber ?? "Unknown"
            let callerName = call.callInfo?.callerName
            CallHistoryManager.shared.handleAnswerCallAction(
                action: action,
                phoneNumber: phoneNumber,
                callerName: callerName
            )
        }
        
        self.telnyxClient?.answerFromCallkit(answerAction: action, customHeaders:  ["X-test-answer":"ios-test"],debug: true)
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("AppDelegate:: END call action: callKitUUID [\(String(describing: self.callKitUUID))] action [\(action.callUUID)]")
        
        // Track call end in call history
        if let call = self.telnyxClient?.calls[action.callUUID] {
            // Determine if this was a rejection or normal end
            let status: CallStatus
            switch call.callState {
            case .RINGING:
                status = .rejected
            case .CONNECTING, .NEW:
                status = .cancelled
            default:
                status = .answered
            }
            CallHistoryManager.shared.trackCallEnd(callId: action.callUUID, status: status)
        }
        
        if previousCall?.callState == .HELD {
            print("AppDelegate:: call held.. unholding call")
            previousCall?.unhold()
        }
        //Run when we want to end or accept/Decline
        if self.callKitUUID == action.callUUID {
            //request to end current call
            print("AppDelegate:: End Current Call")
            if let onGoingCall = self.previousCall {
                self.currentCall = onGoingCall
                self.callKitUUID = onGoingCall.callInfo?.callId
            }
        } else {
            //request to end Previous Call
            print("AppDelegate:: End Previous Call")
        }
        self.telnyxClient?.endCallFromCallkit(endAction: action)
    }

    func providerDidReset(_ provider: CXProvider) {
        print("providerDidReset:")
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("providerDidBegin")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("provider:didActivateAudioSession:")
        self.telnyxClient!.enableAudioSession(audioSession: audioSession)
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("provider:didDeactivateAudioSession:")
        self.telnyxClient!.disableAudioSession(audioSession: audioSession)
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("provider:timedOutPerformingAction:")
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("provider:performSetHeldAction:")
        //request to hold previous call
        previousCall?.hold()
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("provider:performSetMutedAction: \(action.isMuted)")
        if let call = currentCall {
            if action.isMuted {
                print("provider:performSetMutedAction: incoming action to mute call")
                call.muteAudio()
            } else {
                print("provider:performSetMutedAction: incoming action to unmute call")
                call.unmuteAudio()
            }
            print("provider:performSetMutedAction: call.isMuted \(call.isMuted)")
        }
        action.fulfill()
    }
    
    func processVoIPNotification(callUUID: UUID,pushMetaData:[String: Any]) {
        print("AppDelegate:: processVoIPNotification \(callUUID)")
        self.callKitUUID = callUUID
        var serverConfig: TxServerConfiguration
        let userDefaults = UserDefaults.init()
        if userDefaults.getEnvironment() == .development {
            serverConfig = TxServerConfiguration(environment: .development)
        } else {
            serverConfig = TxServerConfiguration(environment: .production)
        }
        
        let selectedCredentials = SipCredentialsManager.shared.getSelectedCredential()
        
        if selectedCredentials?.isToken ?? false {
            let token = selectedCredentials?.username ?? ""
            let deviceToken = userDefaults.getPushToken()
            //Sets the login credentials and the ringtone/ringback configurations if required.
            //Ringtone / ringback tone files are not mandatory.
            let txConfig = TxConfig(token: token,
                                    pushDeviceToken: deviceToken,
                                    ringtone: "incoming_call.mp3",
                                    ringBackTone: "ringback_tone.mp3",
                                    //You can choose the appropriate verbosity level of the SDK.
                                    logLevel: .all,
                                    reconnectClient: true,
                                    // Enable WebRTC stats debug
                                    debug: true,
                                    // Force relay candidate
                                    forceRelayCandidate: false,
                                    // Enable Call Quality Metrics
                                    enableQualityMetrics: true)
            
            do {
                try telnyxClient?.processVoIPNotification(txConfig: txConfig, serverConfiguration: serverConfig,pushMetaData: pushMetaData)
            } catch let error {
                print("AppDelegate:: processVoIPNotification Error \(error)")
            }
        } else {
            let sipUser = selectedCredentials?.username ?? ""
            let password = selectedCredentials?.password ?? ""
            let deviceToken = userDefaults.getPushToken()
            //Sets the login credentials and the ringtone/ringback configurations if required.
            //Ringtone / ringback tone files are not mandatory.
            let txConfig = TxConfig(sipUser: sipUser,
                                    password: password,
                                    pushDeviceToken: deviceToken,
                                    ringtone: "incoming_call.mp3",
                                    ringBackTone: "ringback_tone.mp3",
                                    //You can choose the appropriate verbosity level of the SDK.
                                    logLevel: .all,
                                    reconnectClient: true,
                                    // Enable WebRTC stats debug
                                    debug: true,
                                    // Force relay candidate
                                    forceRelayCandidate: false,
                                    // Enable Call Quality Metrics
                                    enableQualityMetrics: true)
            
            do {
                try telnyxClient?.processVoIPNotification(txConfig: txConfig, serverConfiguration: serverConfig,pushMetaData: pushMetaData)
            } catch let error {
                print("AppDelegate:: processVoIPNotification Error \(error)")
            }
        }
        
        
       
    }
}
