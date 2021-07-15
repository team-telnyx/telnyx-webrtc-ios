//
//  ViewController.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 01/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import UIKit
import CallKit
import TelnyxRTC

class ViewController: UIViewController {

    var userDefaults: UserDefaults = UserDefaults.init()
    var telnyxClient: TxClient?
    var currentCall: Call?
    var incomingCall: Bool = false

    var callKitProvider: CXProvider?
    let callKitCallController = CXCallController()

    @IBOutlet weak var sessionIdLabel: UILabel!
    @IBOutlet weak var socketStateLabel: UILabel!
    @IBOutlet weak var callView: UICallScreen!
    @IBOutlet weak var settingsView: UISettingsView!
    @IBOutlet weak var incomingCallView: UIIncomingCallView!
    @IBOutlet weak var connectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController:: viewDidLoad()")

        self.telnyxClient = appDelegate.getTelnyxClient()
        self.telnyxClient?.delegate = self
        self.initViews()

        self.initCallKit()
    }

    deinit {
        // CallKit has an odd API contract where the developer must call invalidate or the CXProvider is leaked.
        if let provider = callKitProvider {
            provider.invalidate()
        }
    }

    func initViews() {
        print("ViewController:: initViews()")
        self.callView.isHidden = true
        self.callView.delegate = self
        self.callView.hideEndButton(hide: true)

        self.incomingCallView.isHidden = true
        self.incomingCallView.delegate = self

        self.hideKeyboardWhenTappedAround()

        // Restore last user credentials
        self.settingsView.isHidden = false
        self.settingsView.sipUsernameLabel.text = userDefaults.getSipUser()
        self.settingsView.passwordUserNameLabel.text = userDefaults.getSipUserPassword()
    }

    func updateButtonsState() {
        guard let callState = self.currentCall?.callState else {
            self.callView.updateButtonsState(callState: .DONE, incomingCall: false)
            self.incomingCallView.updateButtonsState(callState: .DONE, incomingCall: incomingCall)
            return
        }
        self.callView.updateButtonsState(callState: callState, incomingCall: self.incomingCall)
        self.incomingCallView.updateButtonsState(callState: callState, incomingCall: incomingCall)
    }

    @IBAction func connectButtonTapped(_ sender: Any) {
        guard let telnyxClient = self.telnyxClient else {
            return
        }
        if (telnyxClient.isConnected()) {
            telnyxClient.disconnect()
        } else {

            let deviceToken = userDefaults.getPushToken() //Get stored token from APNS

            var txConfig: TxConfig? = nil
            // Set the connection configuration object.
            // We can login with a user token: https://developers.telnyx.com/docs/v2/webrtc/quickstart
            // Or we can use SIP credentials (SIP user and password)
            if self.settingsView.isTokenSelected {
                guard let telnyxToken = self.settingsView.tokenLabel.text, !telnyxToken.isEmpty else {
                    print("ViewController:: connectButtonTapped() ERROR: Telnyx Token should not be empty. Go to https://developers.telnyx.com/docs/v2/webrtc/quickstart to learn on how to create On-demand tokens.")
                    return
                }
                txConfig = TxConfig(token: telnyxToken,
                                    pushDeviceToken: deviceToken,
                                    ringtone: "incoming_call.mp3",
                                    ringBackTone: "ringback_tone.mp3",
                                    //You can choose the appropriate verbosity level of the SDK.
                                    logLevel: .all)
            } else {
                // To obtain SIP credentials, please go to https://portal.telnyx.com
                guard let sipUser = self.settingsView.sipUsernameLabel.text, !sipUser.isEmpty,
                      let password = self.settingsView.passwordUserNameLabel.text, !password.isEmpty else {
                    print("ViewController:: connectButtonTapped() ERROR: SIP User and Password should not be empty.")
                    return
                }

                txConfig = TxConfig(sipUser: sipUser,
                         password: password,
                         pushDeviceToken: deviceToken,
                         ringtone: "incoming_call.mp3",
                         ringBackTone: "ringback_tone.mp3",
                         //You can choose the appropriate verbosity level of the SDK.
                         logLevel: .all)

                //store user / password in user defaults
                userDefaults.saveUser(sipUser: sipUser, password: password)
            }

            do {
                try telnyxClient.connect(txConfig: txConfig!)
            } catch let error {
                print("ViewController:: connect Error \(error)")
            }
        }
    }

    func resetCallStates() {
        self.incomingCall = false
        self.incomingCallView.isHidden = true
        self.callView.isHidden = false
        self.callView.resetMuteUnmuteState()
        self.callView.resetHoldUnholdState()
        self.callView.resetSpeakerState()
    }
}

// MARK: - TxClientDelegate
extension ViewController: TxClientDelegate {

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
            self.socketStateLabel.text = error.localizedDescription
            self.incomingCallView.isHidden = true
        }
    }
    
    func onClientReady() {
        print("ViewController:: TxClientDelegate onClientReady()")
        DispatchQueue.main.async {
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
        guard let callId = call.callInfo?.callId else {
            print("ViewController:: TxClientDelegate onIncomingCall() Error unknown call UUID")
            return
        }
        print("ViewController:: TxClientDelegate onIncomingCall() Error unknown call UUID: \(callId)")
        
        if let currentCallUUID = self.currentCall?.callInfo?.callId {
            self.executeEndCallAction(uuid: currentCallUUID) //Hangup the previous call if there's one active
        }
        self.currentCall = call //Update the current call with the incoming call
        self.incomingCall = true
        DispatchQueue.main.async {
            self.updateButtonsState()
            self.incomingCallView.isHidden = false
            self.callView.isHidden = true
            //Hide the keyboard
            self.view.endEditing(true)
        }

        self.newIncomingCall(from: call.callInfo?.callerName ?? "Unknown", uuid: callId)
    }

    func onRemoteCallEnded(callId: UUID) {
        print("ViewController:: TxClientDelegate onRemoteCallEnded() callId: \(callId)")
        let reason = CXCallEndedReason.remoteEnded
        if let provider = callKitProvider {
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
                if let currentCallId = self.currentCall?.callInfo?.callId,
                   currentCallId == callId {
                    self.currentCall = nil // clear current call
                }
                self.resetCallStates()
                break
            case .HELD:
                break
            }
            self.updateButtonsState()
        }
    }
}
// MARK: - UIIncomingCallViewDelegate
/**
 Handle Incoming Call Views events
 */
extension ViewController : UIIncomingCallViewDelegate {

    func onAnswerButton() {
        self.currentCall?.answer()
    }

    func onRejectButton() {
        self.currentCall?.hangup()
    }
}
// MARK: - UICallScreenDelegate
/**
 Handle Call Screen events
 */
extension ViewController : UICallScreenDelegate {

    func onCallButton() {
        guard let destinationNumber = self.callView.destinationNumberOrSip.text, !destinationNumber.isEmpty else {
            print("ViewController:: onCallButton() ERROR: destination number or SIP user should not be empty")
            return
        }

        let uuid = UUID()
        let handle = "Telnyx"
        
        self.executeStartCallAction(uuid: uuid, handle: handle)
    }
    
    func onEndCallButton() {
        guard let uuid = self.currentCall?.callInfo?.callId else { return }
        self.executeEndCallAction(uuid: uuid)
    }
    
    func onMuteUnmuteSwitch(isMuted: Bool) {
        if (isMuted) {
            self.currentCall?.muteAudio()
        } else {
            self.currentCall?.unmuteAudio()
        }
    }
    
    func onHoldUnholdSwitch(isOnHold: Bool) {
        if (isOnHold) {
            self.currentCall?.hold()
        } else {
            self.currentCall?.unhold()
        }
    }

    func onToggleSpeaker(isSpeakerActive: Bool) {
        if (isSpeakerActive) {
            self.telnyxClient?.setSpeaker()
        } else {
            self.telnyxClient?.setEarpiece()
        }
    }
}
