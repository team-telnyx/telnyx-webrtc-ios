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

    /// Report a new incoming call. This will generate the Native Incoming call notification
    /// - Parameters:
    ///   - from: Caller name
    ///   - uuid: uuid of the incoming call
    func newIncomingCall(from: String, uuid: UUID) {
        #if targetEnvironment(simulator)
        //Do not execute this function when debugging on the simulator.
        //By reporting a call through CallKit from the simulator, it automatically cancels the call.
        return
        #endif

        guard let provider = callKitProvider else {
            print("CallKit provider not available")
            return
        }

        let callHandle = CXHandle(type: .generic, value: from)
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.hasVideo = false

        provider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
            if let error = error {
                print("Failed to report incoming call: \(error.localizedDescription).")
            } else {
                print("Incoming call successfully reported.")
            }
        }
    }

    /// End the current call
    /// - Parameter uuid: The uuid of the call
    func executeEndCallAction(uuid: UUID) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        callKitCallController.request(transaction) { error in
            if let error = error {
                #if targetEnvironment(simulator)
                //The simulator does not support to register an incoming call through CallKit.
                //For that reason when an incoming call is received on the simulator,
                //we are updating the UI and not registering the callID to callkit.
                //When the user whats to hangup the call and the incoming call was not registered in callkit,
                //the CXEndCallAction fails. That's why we are manually ending the call in this case.
                self.telnyxClient?.calls[uuid]?.hangup() // end the active call
                #endif
                print("EndCallAction transaction request failed: \(error.localizedDescription).")
            } else {
                print("EndCallAction transaction request successful")
            }
        }
    }
    // MARK: - CXProviderDelegate -
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("provider: CXStartCallAction:")
        self.voipDelegate?.executeCall(action: action) { call in
            self.currentCall = call
            if call != nil {
                print("performVoiceCall() successful")
                provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
            } else {
                print("performVoiceCall() failed")
            }
        }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("provider: performAnswerCallAction: \(action.callUUID)")
        self.currentCall?.answer()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("provider:performEndCallAction: \(action.callUUID)")
        self.currentCall?.hangup()
        action.fulfill()
    }

    func providerDidReset(_ provider: CXProvider) {
        print("providerDidReset:")
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("providerDidBegin")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("provider:didActivateAudioSession:")
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("provider:didDeactivateAudioSession:")
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("provider:timedOutPerformingAction:")
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("provider:performSetHeldAction:")
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("provider:performSetMutedAction:")
    }
    
    func processVoIPNotification(callUUID: UUID) {
        var serverConfig: TxServerConfiguration
        let userDefaults = UserDefaults.init()
        if userDefaults.getEnvironment() == .development {
            serverConfig = TxServerConfiguration(environment: .development)
        } else {
            serverConfig = TxServerConfiguration()
        }
        
        let sipUser = userDefaults.getSipUser()
        let password = userDefaults.getSipUserPassword()
        let deviceToken = userDefaults.getPushToken()
        //Sets the login credentials and the ringtone/ringback configurations if required.
        //Ringtone / ringback tone files are not mandatory.
        let txConfig = TxConfig(sipUser: sipUser,
                                password: password,
                                pushDeviceToken: deviceToken,
                                ringtone: "incoming_call.mp3",
                                ringBackTone: "ringback_tone.mp3",
                                //You can choose the appropriate verbosity level of the SDK.
                                logLevel: .all)
        
        do {
            try telnyxClient?.processVoIPNotification(txConfig: txConfig, serverConfiguration: serverConfig)
        } catch let error {
            print("ViewController:: processVoIPNotification Error \(error)")
        }
    }
}
