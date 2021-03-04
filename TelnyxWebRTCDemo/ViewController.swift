//
//  ViewController.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 01/03/2021.
//

import UIKit
import WebRTCSDK

class ViewController: UIViewController {

    var telnyxClient: TxClient?

    @IBOutlet weak var sessionIdLabel: UILabel!
    @IBOutlet weak var socketStateLabel: UILabel!
    @IBOutlet weak var callView: UICallScreen!
    @IBOutlet weak var settingsView: UISettingsView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController:: viewDidLoad()")
        
        self.telnyxClient = appDelegate.getTelnyxClient()
        self.telnyxClient?.delegate = self
        initViews()
    }
    
    func initViews() {
        self.callView.isHidden = true
        self.callView.delegate = self
        self.callView.hideEndButton(hide: true)
        self.settingsView.isHidden = false
        self.versionLabel.text = self.telnyxClient?.getVersion()
    }
    
    @IBAction func connectButtonTapped(_ sender: Any) {
        guard let telnyxClient = self.telnyxClient else {
            return
        }
        if (telnyxClient.isConnected()) {
            telnyxClient.disconnect()
        } else {
            
            guard let sipUser = self.settingsView.sipUsernameLabel.text else { return }
            guard let password = self.settingsView.passwordUserNameLabel.text else { return }

            let txConfig = TxConfig(sipUser: sipUser,
                                    password: password)
            self.telnyxClient?.connect(txConfig: txConfig)
        }
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
        print("ViewController:: TxClientDelegate onSocketConnected()")
        DispatchQueue.main.async {
            self.socketStateLabel.text = "Disconnected"
            self.connectButton.setTitle("Connect", for: .normal)
            self.sessionIdLabel.text = "-"
            self.settingsView.isHidden = false
            self.callView.isHidden = true
        }
    }
    
    func onClientError(error: String) {
        print("ViewController:: TxClientDelegate onClientError() error: \(error)")
        DispatchQueue.main.async {
            self.socketStateLabel.text = "Error"
        }
    }
    
    func onClientReady() {
        print("ViewController:: TxClientDelegate onClientReady()")
        DispatchQueue.main.async {
            self.socketStateLabel.text = "Client ready"
            self.settingsView.isHidden = true
            self.callView.isHidden = false
        }
    }
    
    func onSessionUpdated(sessionId: String) {
        print("ViewController:: TxClientDelegate onSessionUpdated() sessionId: \(sessionId)")
        DispatchQueue.main.async {
            self.sessionIdLabel.text = sessionId
        }
    }
    
    func onCallStateUpdated(callState: CallState) {
        //TODO: Update call state on UI
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
        
        //+18722348663
        //sip:webrtcsquad44613@sip.telnyx.com
        self.telnyxClient?.newCall(callerName: callerName, callerNumber: callerNumber, destinationNumber: destinationNumber, callId: UUID.init())
    }
    
    func onEndCallButton() {
        //TODO: Implement end call
    }
    
    func onMuteUnmuteSwitch(isMuted: Bool) {
        //TODO: Implement mute / unmute
    }
    
    func onHoldUnholdSwitch(isOnHold: Bool) {
        //TODO: Implement hold / unhold
    }

    func onVideoTapped() {
        //TODO: Implement video
    }

    func onToggleSpeaker(isSpeakerActive: Bool) {
        //TODO: change between speaker and headsets
    }
}
