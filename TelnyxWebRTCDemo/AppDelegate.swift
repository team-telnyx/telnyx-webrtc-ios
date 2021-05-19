//
//  AppDelegate.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 01/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import UIKit
import PushKit
import TelnyxRTC


protocol PushKitDelegate {
    func onPushNotificationReceived(payload: PKPushPayload) -> Void
    func onPushNotificationReceived(payload: PKPushPayload, completion: @escaping () -> Void) -> Void
}


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var telnyxClient : TxClient?
    private var pushRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
    var pushKitDelegate: PushKitDelegate?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Set delegate
        let viewController = UIApplication.shared.windows.first?.rootViewController as? ViewController
        self.pushKitDelegate = viewController

        // Instantiate the Telnyx Client SDK
        self.telnyxClient = TxClient()

        //init pushkit to handle VoIP push notifications
        self.initPushKit()
        return true
    }

    func getTelnyxClient() -> TxClient? {
        return self.telnyxClient
    }

    func initPushKit() {
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = Set([.voIP])
    }
}

// MARK: - PKPushRegistryDelegate
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print("pushRegistry:didUpdatePushCredentials:forType:")
        if (type == .voIP) {
            // Store incoming token in user defaults
            let userDefaults = UserDefaults.standard
            let deviceToken = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
            userDefaults.savePushToken(pushToken: deviceToken)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry:didInvalidatePushTokenForType:")
        if (type == .voIP) {
            // Delete incoming token in user defaults
            let userDefaults = UserDefaults.init()
            userDefaults.deletePushToken()
        }
    }

    /**
     .According to the docs, this delegate method is deprecated by Apple.
    */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        print("pushRegistry:didReceiveIncomingPushWithPayload:forType:")
        if (payload.type == .voIP) {
            self.pushKitDelegate?.onPushNotificationReceived(payload: payload)
        }
    }

    /**
     This delegate method is available on iOS 11 and above. Call the completion handler once the
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("pushRegistry:didReceiveIncomingPushWithPayload:forType:completion:")
        if (payload.type == .voIP) {
            self.pushKitDelegate?.onPushNotificationReceived(payload: payload, completion: completion)
        }

        if let version = Float(UIDevice.current.systemVersion), version >= 13.0 {
            completion()
        }
    }
}

