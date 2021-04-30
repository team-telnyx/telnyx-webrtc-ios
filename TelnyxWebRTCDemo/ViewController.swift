//
//  ViewController.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 01/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import UIKit
import WebRTCSDK

class ViewController: UIViewController {

    var telnyxClient: TxClient?
    var currentCall: Call?
    var incomingCall: Bool = false

    @IBOutlet weak var sessionIdLabel: UILabel!
    @IBOutlet weak var socketStateLabel: UILabel!
    @IBOutlet weak var callView: UICallScreen!
    @IBOutlet weak var settingsView: UISettingsView!
    @IBOutlet weak var incomingCallView: UIIncomingCallView!
    @IBOutlet weak var connectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController:: viewDidLoad()")
        overrideUserInterfaceStyle = .light

        self.telnyxClient = appDelegate.getTelnyxClient()
        self.telnyxClient?.delegate = self
        initViews()
    }
    
    func initViews() {
        print("ViewController:: initViews()")
        self.callView.isHidden = true
        self.callView.delegate = self
        self.callView.hideEndButton(hide: true)
        self.settingsView.isHidden = false

        self.incomingCallView.isHidden = true
        self.incomingCallView.delegate = self

        self.hideKeyboardWhenTappedAround()
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
            
            //Here we are Login in with a SIP User and Password. In case token login is needed:
            //1) Generate a token following https://developers.telnyx.com/docs/v2/webrtc/quickstart
            //2) Pass the generated token to a TxConfig instance.
            //   let txConfig = TxConfig(token: "My Token generated")
            //3) Pass the txConfig object to the .connect() function.
            guard let sipUser = self.settingsView.sipUsernameLabel.text else { return }
            guard let password = self.settingsView.passwordUserNameLabel.text else { return }

            //Sets the login credentials and the ringtone/ringback configurations if required.
            //Ringtone / ringback tone files are not mandatory.
            let txConfig = TxConfig(sipUser: sipUser,
                                    password: password,
                                    ringtone: "incoming_call.mp3",
                                    ringBackTone: "ringback_tone.mp3",
                                    //You can choose the appropriate verbosity level of the SDK.
                                    logLevel: .all)

            do {
                try telnyxClient.connect(txConfig: txConfig)
            } catch let error {
                print("ViewController:: connect Error \(error)")
            }
        }
    }
}

// MARK: - TxClientDelegate
extension ViewController: TxClientDelegate {

    func onRemoteCallEnded(callId: UUID) {
        print("ViewController:: TxClientDelegate onRemoteCallEnded() callId: \(callId)")
    }
    

    func onSocketConnected() {
        print("ViewController:: TxClientDelegate onSocketConnected()")
        DispatchQueue.main.async {
            self.socketStateLabel.text = "Connected"
            self.connectButton.setTitle("Disconnect", for: .normal)
        }
        
    }
    
    func onSocketDisconnected() {
        print("ViewController:: TxClientDelegate onSocketConnected()")
        DispatchQueue.main.async {
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
        self.currentCall?.hangup() //Hangup the previous call if there's one active
        self.currentCall = call //Update the current call with the incoming call
        DispatchQueue.main.async {
            self.incomingCall = true
            self.updateButtonsState()
            self.incomingCallView.isHidden = false
            self.callView.isHidden = true
            //Hide the keyboard
            self.view.endEditing(true)
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
                self.incomingCall = false
                self.incomingCallView.isHidden = true
                self.callView.isHidden = false
                self.callView.muteUnmuteSwitch.setOn(false, animated: false)
                self.callView.holdUnholdSwitch.setOn(false, animated: false)
                self.callView.resetHoldUnholdState()
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
        guard let destinationNumber = self.callView.destinationNumberOrSip.text else { return }
        
        let callerName = self.settingsView.callerIdNameLabel.text ?? ""
        let callerNumber = self.settingsView.callerIdNumberLabel.text ?? ""

        do {
            self.currentCall = try self.telnyxClient?.newCall(callerName: callerName,
                                                              callerNumber: callerNumber,
                                                              destinationNumber: destinationNumber,
                                                              callId: UUID.init())
        } catch let error {
            print("ViewController:: newCall Error \(error)")
        }
    }
    
    func onEndCallButton() {
        self.currentCall?.hangup()
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
        //TODO: change between speaker and headsets
    }
}
