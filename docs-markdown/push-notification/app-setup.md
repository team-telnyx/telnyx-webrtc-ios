## Push Notification App Setup

### VoIP Push - App Setup

The following setup is required in your application to receive Telnyx VoIP push notifications:

#### a. Add Push Notifications capability to your Xcode project

1. Open the xcode workspace associated with your app.
2. In the Project Navigator (the left-hand menu), select the project icon that represents your mobile app.
3. In the top-left corner of the right-hand pane in Xcode, select your app's target.
4. Press the  +Capabilities button.
<p align="center">
      <img width="294" alt="Screen Shot 2021-11-26 at 13 34 12" src="https://user-images.githubusercontent.com/75636882/143610180-04e2a98c-bb08-4f06-b81a-9a3a4231d389.png" />
</p>

6. Enable Push Notifications
<p align="center">
      <img width="269" alt="Screen Shot 2021-11-26 at 13 35 51" src="https://user-images.githubusercontent.com/75636882/143610372-abab46cc-dd2a-4712-9020-240f9dbaaaf7.png" />
</p>

#### b. Configure PushKit into your app:
1. Import pushkit
```Swift
import PushKit
```
2. Initialize PushKit:
```Swift
private var pushRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
...

func initPushKit() {
  pushRegistry.delegate = self
  pushRegistry.desiredPushTypes = Set([.voIP])
}
```
3. Implement PKPushRegistryDelegate
```Swift
extension AppDelegate: PKPushRegistryDelegate {

    // New push notification token assigned by APNS.
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        if (type == .voIP) {
            // This push notification token has to be sent to Telnyx when connecting the Client.
            let deviceToken = credentials.token.reduce("", {$0 + String(format: "%02X", $1) })
            UserDefaults.standard.savePushToken(pushToken: deviceToken)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        if (type == .voIP) {
            // Delete incoming token in user defaults
            let userDefaults = UserDefaults.init()
            userDefaults.deletePushToken()
        }
    }

    /**
     This delegate method is available on iOS 11 and above. 
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        if (payload.type == .voIP) {
            self.handleVoIPPushNotification(payload: payload)
        }

        if let version = Float(UIDevice.current.systemVersion), version >= 13.0 {
            completion()
        }
    }

    func handleVoIPPushNotification(payload: PKPushPayload) {
        if let metadata = payload.dictionaryPayload["metadata"] as? [String: Any] {

            let callId = metadata["call_id"] as? String
            let callerName = (metadata["caller_name"] as? String) ?? ""
            let callerNumber = (metadata["caller_number"] as? String) ?? ""
            let caller = callerName.isEmpty ? (callerNumber.isEmpty ? "Unknown" : callerNumber) : callerName
            

            let uuid = UUID(uuidString: callId)
            
            // Re-connect the client and process the push notification when is received.
            // You will need to use the credentials of the same user that is receiving the call. 
            let txConfig = TxConfig(sipUser: sipUser,
                                password: password,
                                pushDeviceToken: "APNS_PUSH_TOKEN")
                                
                        
            //Call processVoIPNotification method 
        
            try telnyxClient?.processVoIPNotification(txConfig: txConfig, serverConfiguration: serverConfig,pushMetaData: metadata)
            

            
            // Report the incoming call to CallKit framework.
            let callHandle = CXHandle(type: .generic, value: from)
            let callUpdate = CXCallUpdate()
            callUpdate.remoteHandle = callHandle
            callUpdate.hasVideo = false

            provider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
                  if let error = error {
                      print("AppDelegate:: Failed to report incoming call: \(error.localizedDescription).")
                  } else {
                      print("AppDelegate:: Incoming call successfully reported.")
                  }
            }
    }
}
```

4. If everything is correctly set-up when the app runs APNS should assign a Push Token.
5. In order to receive VoIP push notifications. You will need to send your push token when connecting to the Telnyx Client.

```Swift
 
 let txConfig = TxConfig(sipUser: sipUser,
                         password: password,
                         pushDeviceToken: "DEVICE_APNS_TOKEN",
                         //You can choose the appropriate verbosity level of the SDK. 
                         logLevel: .all)

 // Or use a JWT Telnyx Token to authenticate
 let txConfigToken = TxConfig(token: "MY_JWT_TELNYX_TOKEN",
                             pushDeviceToken: "DEVICE_APNS_TOKEN",
                             //You can choose the appropriate verbosity level of the SDK. Logs are disabled by default
                             logLevel: .all)
```

For more information about Pushkit you can check the official [Apple docs](https://developer.apple.com/documentation/pushkit]).


__*Important*__:
- You will need to login at least once to send your device token to Telnyx before start getting Push notifications.
- You will need to provide `pushMetaData` to `processVoIPNotification()` to get Push calls to work.
- You will need to implement 'CallKit' to report an incoming call when there’s a VoIP push notification. On iOS 13.0 and later, if you fail to report a call to CallKit, the system will terminate your app. More information on [Apple docs](https://developer.apple.com/documentation/pushkit/pkpushregistrydelegate/2875784-pushregistry) 


## Multidevice Push Notifications

Telnyx WebRTC supports multidevice push notifications. A single user can have up to 5 device tokens (either iOS - APNS or Android - FCM). When a user logs into the socket and provides a push token, our services will register this token to that user - allowing it to receive push notifications for incoming calls. If a 6th registration is made, the least recently used token will be removed.

This effectively means that you can have up to 5 devices that can receive push notifications for the same incoming call.

## Disable Push Notification

Push notifications can be disabled for the current user by calling :
```
telnyxClient.disablePushNotifications()
```
Note : Signing back in, using same credentials will re-enable push notifications.
