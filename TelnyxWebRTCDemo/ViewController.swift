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
    @IBOutlet weak var settingsView: UISettingsView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController:: viewDidLoad()")
        
        self.telnyxClient = appDelegate.getTelnyxClient()
        self.telnyxClient?.delegate = self
        versionLabel.text = self.telnyxClient?.getVersion()

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
        }
    }
    
    func onSessionUpdated(sessionId: String) {
        print("ViewController:: TxClientDelegate onSessionUpdated() sessionId: \(sessionId)")
        DispatchQueue.main.async {
            self.sessionIdLabel.text = sessionId
        }
    }
    
}
