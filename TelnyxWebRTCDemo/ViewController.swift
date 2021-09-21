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
    var incomingCall: Bool = false

    var loadingView: UIAlertController?

    @IBOutlet weak var environment: UILabel!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var sessionIdLabel: UILabel!
    @IBOutlet weak var socketStateLabel: UILabel!
    @IBOutlet weak var callView: UICallScreen!
    @IBOutlet weak var settingsView: UISettingsView!
    @IBOutlet weak var incomingCallView: UIIncomingCallView!
    @IBOutlet weak var connectButton: UIButton!
    
    var serverConfig: TxServerConfiguration?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController:: viewDidLoad()")

        self.telnyxClient = appDelegate.telnyxClient
        self.initViews()
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

        // Environment Selector
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        self.logo.addGestureRecognizer(longPressRecognizer)
        self.logo.isUserInteractionEnabled = true

        if self.userDefaults.getEnvironment() == .development {
            self.serverConfig = TxServerConfiguration(environment: .development)
        }
        self.updateEnvironment()
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            // Internal use only
            self.showHiddenOptions()
        }
    }

    func showHiddenOptions() {
        let alert = UIAlertController(title: "Options", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Development Environment", style: .default , handler:{ (UIAlertAction)in
            self.serverConfig = TxServerConfiguration(environment: .development)
            self.userDefaults.saveEnvironment(environment: .development)
            self.updateEnvironment()
        }))
        
        alert.addAction(UIAlertAction(title: "Production Environment", style: .default , handler:{ (UIAlertAction)in
            self.serverConfig = nil
            self.userDefaults.saveEnvironment(environment: .production)
            self.updateEnvironment()
        }))

        alert.addAction(UIAlertAction(title: "Copy APNS token", style: .default , handler:{ (UIAlertAction)in
            // To copy the APNS push token to pasteboard
            let token = UserDefaults.init().getPushToken()
            UIPasteboard.general.string = token
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func updateEnvironment() {
        DispatchQueue.main.async {
            self.environment.text = (self.serverConfig?.environment == .development) ? "Development" : "Production"
        }
    }

    func updateButtonsState() {
        guard let callState = self.appDelegate.currentCall?.callState else {
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
                if let serverConfig = serverConfig {
                    try telnyxClient.connect(txConfig: txConfig!, serverConfiguration: serverConfig)
                } else {
                    try telnyxClient.connect(txConfig: txConfig!)
                }
                self.showLoadingView()
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

// MARK: - UIIncomingCallViewDelegate
/**
 Handle Incoming Call Views events
 */
extension ViewController : UIIncomingCallViewDelegate {

    func onAnswerButton() {
        guard let callID = self.appDelegate.currentCall?.callInfo?.callId else { return }
        self.appDelegate.executeAnswerCallAction(uuid: callID)
    }

    func onRejectButton() {
        self.appDelegate.currentCall?.hangup()
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
        
        appDelegate.executeStartCallAction(uuid: uuid, handle: handle)
    }
    
    func onEndCallButton() {
        guard let uuid = self.appDelegate.currentCall?.callInfo?.callId else { return }
        appDelegate.executeEndCallAction(uuid: uuid)
    }
    
    func onMuteUnmuteSwitch(isMuted: Bool) {
        if (isMuted) {
            self.appDelegate.currentCall?.muteAudio()
        } else {
            self.appDelegate.currentCall?.unmuteAudio()
        }
    }
    
    func onHoldUnholdSwitch(isOnHold: Bool) {
        if (isOnHold) {
            self.appDelegate.currentCall?.hold()
        } else {
            self.appDelegate.currentCall?.unhold()
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
