//
//  ViewControllerCallKitExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 18/05/2021.
//

import UIKit
import Foundation
import AVFoundation
import CallKit
import PushKit
import TelnyxRTC

// CallKit related functions
extension ViewController {

    /**
     Initialize callkit framework
     */
    func initCallKit() {
        let configuration = CXProviderConfiguration(localizedName: "TelnyxRTC")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        callKitProvider = CXProvider(configuration: configuration)
        if let provider = callKitProvider {
            provider.setDelegate(self, queue: nil)
        }
    }

    /// Start calling action
    /// - Parameters:
    ///   - uuid: The uuid of the outbound call
    ///   - handle: call handle
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

    /// Report a new incoming call
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
                print("Failed to report incoming call successfully: \(error.localizedDescription).")
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

    /// Start calling
    /// - Parameters:
    ///   - uuid: the uuid of the call.
    ///   - completionHandler: completionHandler
    func executeCall(uuid: UUID, completionHandler: @escaping (Bool) -> Void) {
        guard let destinationNumber = self.callView.destinationNumberOrSip.text else { return }

        let callerName = self.settingsView.callerIdNameLabel.text ?? ""
        let callerNumber = self.settingsView.callerIdNumberLabel.text ?? ""

        do {
            self.currentCall = try self.telnyxClient?.newCall(callerName: callerName,
                                                              callerNumber: callerNumber,
                                                              destinationNumber: destinationNumber,
                                                              callId: uuid)
        } catch let error {
            print("ViewController:: newCall Error \(error)")
            completionHandler(false)
        }
        completionHandler(true)
    }

    /// Answers an incoming call
    /// - Parameters:
    ///   - uuid: The uuid of the call to be answered
    ///   - completionHandler: completionHandler
    func executeAnswerCall(uuid: UUID, completionHandler: @escaping (Bool) -> Void) {
        self.currentCall?.answer()
        completionHandler(true)
    }
}

// MARK: - CXProviderDelegate
extension ViewController : CXProviderDelegate {
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

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("provider: CXStartCallAction:")
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())

        executeCall(uuid: action.callUUID) { success in
            if success {
                print("performVoiceCall() successful")
                provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
            } else {
                print("performVoiceCall() failed")
            }
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("provider: performAnswerCallAction:")

        executeAnswerCall(uuid: action.callUUID) { success in
            if success {
                print("performAnswerVoiceCall() successful")
            } else {
                print("performAnswerVoiceCall() failed")
            }
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("provider:performEndCallAction:")
        self.currentCall?.hangup()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("provider:performSetHeldAction:")
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("provider:performSetMutedAction:")
        DispatchQueue.main.async {
            //Update the switch state and call the telnyx SDK to mute / unmute
            self.callView.muteUnmuteSwitch.setOn(action.isMuted, animated: true)
            self.onMuteUnmuteSwitch(isMuted: action.isMuted)
            action.fulfill()
        }
    }
}

// MARK: - PushKitDelegate
extension ViewController : PushKitDelegate {

    func processPush(payload: PKPushPayload) {
        // TODO: Process payload
        let userDefaults = UserDefaults.init()
        let sipUser = userDefaults.getSipUser()
        let password = userDefaults.getSipUserPassword()
        let deviceToken = UserDefaults.init().getPushToken()
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
            try self.telnyxClient?.processVoIPNotification(txConfig: txConfig)
        } catch let error {
            print("ViewController:: processVoIPNotification Error \(error)")
        }
    }

    func onPushNotificationReceived(payload: PKPushPayload) {
        self.processPush(payload: payload)
    }

    func onPushNotificationReceived(payload: PKPushPayload, completion: @escaping () -> Void) {
        self.processPush(payload: payload)
        if let version = Float(UIDevice.current.systemVersion), version < 13.0 {
            // Save for later when the notification is properly handled.
            completion()
        }
    }
}
