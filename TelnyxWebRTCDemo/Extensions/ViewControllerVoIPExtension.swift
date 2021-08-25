//
//  ViewControllerVoIPExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 25/08/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.

import Foundation
import UIKit
import AVFoundation
import CallKit
import PushKit
import TelnyxRTC

// MARK: - VoIPDelegate
extension ViewController : VoIPDelegate {
    
    func executeAnswerCall(uuid: UUID, completionHandler: @escaping (_ success: Bool) -> Void) {
        if telnyxClient?.isConnected() ?? false {
            // If we are already connected, then answer the call
            // TODO: find the call that matches the UUID
            self.currentCall?.answer()
            completionHandler(true)
        } else {
            // If we are not connected, we need to connect the telnyx client.
            // TODO: we need to automatically ANSWER the call after connecting an receiving the INVITE that matches the
            // UUID of the call
            self.reconnect()
            completionHandler(true)
        }
    }
    
    func executeEndCall(uuid: UUID, completionHandler: @escaping (Bool) -> Void) {
        if telnyxClient?.isConnected() ?? false {
            // If we are already connected, then hangup the call
            // TODO: find the call that matches the UUID
            self.currentCall?.hangup()
            completionHandler(true)
        } else {
            // If we are not connected, we need to connect the telnyx client.
            // TODO: we need to automatically HANGUP the call after connecting an receiving the INVITE that matches the
            // UUID of the call
            self.reconnect()
            completionHandler(true)
        }
    }
    
    func executeCall(action: CXStartCallAction, completionHandler: @escaping (Bool) -> Void) {
        do {
            guard let callerName = self.settingsView.callerIdNameLabel.text,
                  let callerNumber = self.settingsView.callerIdNumberLabel.text,
                  let destinationNumber = self.callView.destinationNumberOrSip.text else {
                print("ERROR: executeCall can't be performed. Check callerName - callerNumber and destinationNumber")
                return
            }
            
            self.currentCall = try telnyxClient?.newCall(callerName: callerName,
                                                         callerNumber: callerNumber,
                                                         destinationNumber: destinationNumber,
                                                         callId: action.callUUID)
            completionHandler(true)
        } catch let error {
            print("ViewController:: executeCall Error \(error)")
            completionHandler(false)
        }
    }
    
    func onPushNotificationReceived(payload: PKPushPayload) {
        // no-op for now
    }
    
    func reconnect() {
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
            if let serverConfig = serverConfig {
                try telnyxClient?.connect(txConfig: txConfig, serverConfiguration: serverConfig)
            } else {
                try telnyxClient?.connect(txConfig: txConfig)
            }
        } catch let error {
            print("ViewController:: processVoIPNotification Error \(error)")
        }
    }
}
