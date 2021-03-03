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

    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController:: viewDidLoad()")
        
        self.telnyxClient = appDelegate.getTelnyxClient()
        versionLabel.text = self.telnyxClient?.getVersion()
        self.telnyxClient?.connect()
    }
}

// MARK: - TxClientDelegate
extension ViewController: TxClientDelegate {
    
    func onSocketConnected() {
        print("ViewController:: TxClientDelegate onSocketConnected()")
    }
    
    func onSocketDisconnected() {
        print("ViewController:: TxClientDelegate onSocketConnected()")
    }
    
    func onClientError(error: String) {
        print("ViewController:: TxClientDelegate onClientError() error \(error)")
    }
}
