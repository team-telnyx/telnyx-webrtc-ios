//
//  AppDelegate.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 01/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import UIKit
import PushKit
import CallKit
import TelnyxRTC

protocol VoIPDelegate: AnyObject {
    func onPushNotificationReceived(payload: PKPushPayload)
    func executeAnswerCall(uuid: UUID, completionHandler: @escaping (_ success: Bool) -> Void)
    func executeEndCall(uuid: UUID, completionHandler: @escaping (_ success: Bool) -> Void)
    func executeCall(action: CXStartCallAction, completionHandler: @escaping (_ success: Bool) -> Void)
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var telnyxClient : TxClient?
    private var pushRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
    weak var voipDelegate: VoIPDelegate?
    var callKitProvider: CXProvider?
    let callKitCallController = CXCallController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Set delegate
        let viewController = UIApplication.shared.windows.first?.rootViewController as? ViewController
        self.voipDelegate = viewController

        // Instantiate the Telnyx Client SDK
        self.telnyxClient = TxClient()

        //init pushkit to handle VoIP push notifications
        self.initPushKit()
        self.initCallKit()
        return true
    }

    func initPushKit() {
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = Set([.voIP])
    }

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

    deinit {
        // CallKit has an odd API contract where the developer must call invalidate or the CXProvider is leaked.
        if let provider = callKitProvider {
            provider.invalidate()
        }
    }
}

// MARK: - PKPushRegistryDelegate
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print("pushRegistry:didUpdatePushCredentials:forType:")
        if (type == .voIP) {
            // Store incoming token in user defaults
            let userDefaults = UserDefaults.standard
            let deviceToken = credentials.token.reduce("", {$0 + String(format: "%02X", $1) })
            userDefaults.savePushToken(pushToken: deviceToken)
            print("Device push token: \(deviceToken)")
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
            self.newIncomingCall(from: "Incoming call", uuid: UUID.init())
            self.voipDelegate?.onPushNotificationReceived(payload: payload)
        }
    }

    /**
     This delegate method is available on iOS 11 and above. Call the completion handler once the
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("pushRegistry:didReceiveIncomingPushWithPayload:forType:completion: \(payload.dictionaryPayload)")
        if (payload.type == .voIP) {
            if let metadata = payload.dictionaryPayload["metadata"] as? [String: Any] {
                let callId = (metadata["callID"] as? String) ?? UUID.init().uuidString
                let callerName = (metadata["caller_name"] as? String) ?? ""
                let callerNumber = (metadata["caller_number"] as? String) ?? ""
                
                let caller = callerName.isEmpty ? (callerNumber.isEmpty ? "Unknown" : callerNumber) : callerName
                self.newIncomingCall(from: caller, uuid: UUID(uuidString: callId)!)
                self.voipDelegate?.onPushNotificationReceived(payload: payload)
            }
        }

        if let version = Float(UIDevice.current.systemVersion), version >= 13.0 {
            completion()
        }
    }
}

