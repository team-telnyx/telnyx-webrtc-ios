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
import SwiftUI

protocol VoIPDelegate: AnyObject {
    func onSocketConnected()
    func onSocketDisconnected()
    func onClientError(error: Error)
    func onClientReady()
    func onSessionUpdated(sessionId: String)
    func onCallStateUpdated(callState: CallState, callId: UUID)
    func onIncomingCall(call: Call)
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?)
    func executeCall(callUUID: UUID, completionHandler: @escaping (_ success: Call?) -> Void)
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var telnyxClient : TxClient?
    var currentCall: Call?
    var previousCall: Call?
    var callKitUUID: UUID?
    
    var userDefaults: UserDefaults = UserDefaults.init()
    var isCallOutGoing:Bool = false

    private var pushRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
    weak var voipDelegate: VoIPDelegate?
    var callKitProvider: CXProvider?
    let callKitCallController = CXCallController()

   
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure for UI testing if needed
        TestConfiguration.configureForTesting()
        
        
        // Create window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create hosting controller with background color
        let splashView = SplashScreen()
            .edgesIgnoringSafeArea(.all)
        
        let hostingController = UIHostingController(rootView: splashView)
        
        // Set as root
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
        
        // Instantiate the Telnyx Client SDK
        self.telnyxClient = TxClient()
        self.telnyxClient?.delegate = self
        self.initPushKit()
        self.initCallKit()
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("AppDelegate: applicationDidEnterBackground")
    }

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
        return formatter
    }()
    
    
    func initPushKit() {
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = Set([.voIP])
    }

    /**
     Initialize callkit framework
     */
    func initCallKit() {
        let configuration = CXProviderConfiguration(localizedName: "TelnyxRTC")
        configuration.maximumCallGroups = 2
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
            userDefaults.savePushToken(deviceToken)
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
        print("pushRegistry:didReceiveIncomingPushWithPayload:forType: old")
        if (payload.type == .voIP) {
            self.handleVoIPPushNotification(payload: payload)
        }
    }

    /**
     This delegate method is available on iOS 11 and above. Call the completion handler once the
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("pushRegistry:didReceiveIncomingPushWithPayload:forType:completion new: \(payload.dictionaryPayload)")
        if (payload.type == .voIP) {
            self.handleVoIPPushNotification(payload: payload)
        }

        if let version = Float(UIDevice.current.systemVersion), version >= 13.0 {
            completion()
        }
    }

    func handleVoIPPushNotification(payload: PKPushPayload) {
        if let metadata = payload.dictionaryPayload["metadata"] as? [String: Any] {
            var callID = UUID.init().uuidString
            if let newCallId = (metadata["call_id"] as? String),
               !newCallId.isEmpty {
                callID = newCallId
            }
            let callerName = (metadata["caller_name"] as? String) ?? ""
            let callerNumber = (metadata["caller_number"] as? String) ?? ""
            
            let caller = callerName.isEmpty ? (callerNumber.isEmpty ? "Unknown" : callerNumber) : callerName
            let uuid = UUID(uuidString: callID)
            self.processVoIPNotification(callUUID: uuid!,pushMetaData: metadata)
            self.newIncomingCall(from: caller, uuid: uuid!)
        } else {
            // If there's no available metadata, let's create the notification with dummy data.
            let uuid = UUID.init()
            self.processVoIPNotification(callUUID: uuid,pushMetaData: [String: Any]())
            self.newIncomingCall(from: "Incoming call", uuid: uuid)
        }
    }
}
