//
//  AppDelegate.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 01/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import UIKit
import WebRTCSDK
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var telnyxClient : TxClient?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //Instantiate the Telnyx Client SDK
        self.telnyxClient = TxClient()

        return true
    }


    func getTelnyxClient() -> TxClient? {
        return self.telnyxClient
    }
}

