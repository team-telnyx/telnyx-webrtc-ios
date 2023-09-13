# telnyx-webrtc-ios

Enable Telnyx real-time communication services on iOS. :telephone_receiver: :fire:

## Project structure: 

- SDK project: Enable Telnyx WebRTC communications.
- SDK Tests project.
- Demo app project. 


## Project Setup:

1. Clone the repository
2. Run the command `pod install` to install de dependencies inside the project root folder. 
3. Open the Workspace : `TelnyxRTC.xcworkspace`
4. You will find 3 targets to build: 
      - The SDK
      - The SDK Tests
      - The Demo App
      
<p align="center">
<img width="247" alt="Screen Shot 2021-05-04 at 18 34 45" src="https://user-images.githubusercontent.com/75636882/117073153-e8f9e680-ad07-11eb-9d1f-685397b071a6.png">
</p>

5. Select the target `TelnyxRTC (TelnyxRTC Project)` to build the SDK
<p align="center">
<img width="243" alt="Screen Shot 2021-05-04 at 18 35 18" src="https://user-images.githubusercontent.com/75636882/117073140-e3040580-ad07-11eb-8ac6-dc99531550e3.png">

</p>
7. Select the target `TelnyxRTCTests` to run the tests. You will need to long press over the Run button and select `Build for testing`

<p align="center">
<img width="153" align="center" alt="Screen Shot 2021-03-03 at 10 04 05" src="https://user-images.githubusercontent.com/75636882/109810077-d4b24400-7c07-11eb-91ec-d81e72ae9069.png">
</p>

7.  Select target `TelnyxWebRTCDemo` to run the demo app. The SDK should be manually builded in order to get the app running (Step 5)

8. Enjoy 😎
</br>
</br>
<table>
  <tr>
    <td>Credentials</td>
     <td>Outbound call</td>
     <td>Incoming call</td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/75636882/116748486-eaf53a00-a9d5-11eb-9093-968e8f2bde6e.gif" width=270></td>
    <td><img src="https://user-images.githubusercontent.com/75636882/116748473-e597ef80-a9d5-11eb-94a3-2a4a044ea4ff.gif" width=270></td>
    <td><img src="https://user-images.githubusercontent.com/75636882/116748481-e92b7680-a9d5-11eb-9fb5-6fe4cb10b797.gif" width=270></td>
  </tr>
 </table>
  
-----
</br>

## SIP Credentials
In order to start making and receiving calls using the TelnyxRTC SDK you will need to get SIP Credentials:

1. Access to https://portal.telnyx.com/
2. Sign up for a Telnyx Account.
3. Create a Credential Connection to configure how you connect your calls.
4. Create an Outbound Voice Profile to configure your outbound call settings and assign it to your Credential Connection.

For more information on how to generate SIP credentials check the [Telnyx WebRTC quickstart guide](https://developers.telnyx.com/docs/v2/webrtc/quickstart). 

</br>

## Adding Telnyx SDK to your iOS Client Application:
Currently the iOS SDK is supported using cocoapods. 

### Cocoapods

If your xcode project is not using [cocoapods](https://cocoapods.org/) yet, you will need to configure it.

1. Open your podfile and add the TelnyxRTC. 
```
pod 'TelnyxRTC', '~> 0.1.0'
```
2. Install your pods. You can add the flag --repo-update to ensure your cocoapods has the specs updated.
```
pod install --repo-update
```
3. Open your .xcworkspace 
4. Import TelnyxRTC at the top level of your class:
```
import TelnyxRTC
```
5. Disable BITCODE (The GoogleWebRTC dependency has BITCODE disabled):  Go to the Build Settings tab of your app target, search for “bitcode” and set it to “NO”
<p align="center">
<img width="743" alt="Screen Shot 2021-05-07 at 17 46 08" src="https://user-images.githubusercontent.com/75636882/117506545-235bc180-af5c-11eb-91eb-00d60f5844fa.png">
</p>

6. Enable VoIP and Audio background modes: Go to Signing & Capabilities tab, press the +Capability button and add those background modes:
<p align="center">
<img width="719" alt="Screen Shot 2021-05-07 at 17 46 54" src="https://user-images.githubusercontent.com/75636882/117506607-3ff7f980-af5c-11eb-8df2-2f9170c12baf.png">
</p>

7. Go to your Info.plist file and add the “Privacy - Microphone Usage Description” key with a description that your app requires microphone access in order to make VoIP calls. 
<p align="center">
<img width="911" alt="Screen Shot 2021-05-07 at 17 48 17" src="https://user-images.githubusercontent.com/75636882/117506706-6d44a780-af5c-11eb-87e2-d6be092474f2.png">
</p>

8. You are all set!
</br>

### Swift Package Manager

Xcode has a built-in support for Swift package manager. To add a package : 

1. Select Files > Add Packages
2. On the Swift Package Manager Screen, Search for the https://github.com/team-telnyx/telnyx-webrtc-ios.git package.
3. Select the **main brach** and click Add Package

<p align="center">
<img width="911" alt="Screen Shot 2021-05-07 at 17 48 17" src="https://github.com/isaacakakpo1/telnyx-webrtc-ios-smp/assets/134492608/39be0ab7-222f-478c-bba9-cb2813bcb81d">
</p>

NB: if Add Package is stuck downloading try File > Packages > Reset Package Caches or Run the command
`rm -rf ~/Library/Caches/org.swift.swiftpm/`  in terminal

Read more in [Apple documentation](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

**Hint: Use either Cocoapods or Swift Package Manager for Individual Packages to avoid Duplicate binaries**

## Usage

### Telnyx client setup

```Swift
// Initialize the client
let telnyxClient = TxClient()

// Register to get SDK events
telnyxClient.delegate = self

// Setup yor connection parameters.

// Set the login credentials and the ringtone/ringback configurations if required.
// Ringtone / ringback tone files are not mandatory.
// You can user your sipUser and password
let txConfigUserAndPassowrd = TxConfig(sipUser: sipUser,
                                       password: password,
                                       pushDeviceToken: "DEVICE_APNS_TOKEN",
                                       ringtone: "incoming_call.mp3",
                                       ringBackTone: "ringback_tone.mp3",
                                       //You can choose the appropriate verbosity level of the SDK.
                                       //Logs are disabled by default
                                       logLevel: .all)

// Or use a JWT Telnyx Token to authenticate
let txConfigToken = TxConfig(token: "MY_JWT_TELNYX_TOKEN",
                             pushDeviceToken: "DEVICE_APNS_TOKEN",
                             ringtone: "incoming_call.mp3",
                             ringBackTone: "ringback_tone.mp3",
                             //You can choose the appropriate verbosity level of the SDK. Logs are disabled by default
                             logLevel: .all)

do {
   // Connect and login
   // Use `txConfigUserAndPassowrd` or `txConfigToken`
   try telnyxClient.connect(txConfig: txConfigToken)
} catch let error {
   print("ViewController:: connect Error \(error)")
}

// You can call client.disconnect() when you're done.
Note: you need to relese the delegate manually when you are done.

// Disconnecting and Removing listeners.
telnyxClient.disconnect();

// Release the delegate
telnyxClient.delegate = nil

```

### Telnyx client delegate

You will need to instantiate the client and set the delegate. 

```Swift
// Initialize the client
let telnyxClient = TxClient()

// Register to get SDK events
telnyxClient.delegate = self
```

Then you will receive the following events:


```Swift
extension ViewController: TxClientDelegate {

    func onRemoteCallEnded(callId: UUID) {
        // Call has been removed internally.
    }

    func onSocketConnected() {
       // When the client has successfully connected to the Telnyx Backend.
    }

    func onSocketDisconnected() {
       // When the client from the Telnyx backend
    }

    func onClientError(error: Error)  {
        // Something went wrong.
    }

    func onClientReady()  {
       // You can start receiving incoming calls or
       // start making calls once the client was fully initialized.
    }

    func onSessionUpdated(sessionId: String)  {
       // This function will be executed when a sessionId is received.
    }

    func onIncomingCall(call: Call)  {
       // Someone is calling you.
       // This delegate method will be called when the app is in foreground and the Telnyx Client is connected.
    }

    func onPushCall(call: Call) {
       // If you have configured Push Notifications and app is in background or the Telnyx Client is disconnected
       // this delegate method will be called after the push notification is received.
       // Update the current call with the incoming call
       self.currentCall = call 
    }
    

    // You can update your UI from here based on the call states.
    // Check that the callId is the same as your current call.
    func onCallStateUpdated(callState: CallState, callId: UUID) {
      // handle the new call state
      switch (callState) {
      case .CONNECTING:
          break
      case .RINGING:
          break
      case .NEW:
          break
      case .ACTIVE:
          break
      case .DONE:
          break
      case .HELD:
          break
      }
    }
}
```

## Calls

### Outboud call

```Swift
   // Create a client instance
   self.telnyxClient = TxClient()

   // Asign the delegate to get SDK events
   self.telnyxClient?.delegate = self

   // Connect the client (Check TxClient class for more info)
   self.telnyxClient?.connect(....)

   // Create the call and start calling
   self.currentCall = try self.telnyxClient?.newCall(callerName: "Caller name",
                                                     callerNumber: "155531234567",
                                                     // Destination is required and can be a phone number or SIP URI
                                                     destinationNumber: "18004377950",
                                                     callId: UUID.init())
```


This is a general example: In order to fully support outbound calls you will need to implement CallKit to properly handle audio states. For more information check `Audio Session Handling WebRTC + CallKit` section.

### Inbound call

How to answer an incoming call:
```Swift
//Init your client
func initTelnyxClient() {
   //
   self.telnyxClient = TxClient()

   // Asign the delegate to get SDK events
   self.telnyxClient?.delegate = self

   // Connect the client (Check TxClient class for more info)
   self.telnyxClient?.connect(....)
}

extension ViewController: TxClientDelegate {
    //....
    func onIncomingCall(call: Call) {
        // We are automatically answering any incoming call as an example, but
        // maybe you want to store a reference of the call, and answer the call after a button press.
        self.myCall = call.answer()
    }
}
```

This is a general example: In order to fully support inbound calls you will need to implement PushKit + CallKit. For more information check `Setting up VoIP push notifications` section.

---
</br>

## Setting up VoIP push notifications: 

In order to receive incoming calls while the app is running in background or closed, you will need to perform a set of configurations over your Mission Control Portal Account and your application. 

</br>

### VoIP Push - Portal setup

During this process you will learn how to create a VoIP push credential and assign the credential to a SIP Connection. 

This process requires:
* A Mission Control Portal Account. 
* A SIP Connection.
* Your Apple VoIP push certificate.

For complete instructions on how to setup Push Notifications got to this [link](https://developers.telnyx.com/docs/v2/webrtc/push-notifications).

</br>

### VoIP Push - App Setup

The following setup is required in your application to receive Telnyx VoIP push notifications:

#### a. Add Push Notifications capability to your Xcode project

1. Open the xcode workspace associated with your app.
2. In the Project Navigator (the left-hand menu), select the project icon that represents your mobile app.
3. In the top-left corner of the right-hand pane in Xcode, select your app's target.
4. Press the  +Capabilities button.
<p align="center">
      <img width="294" alt="Screen Shot 2021-11-26 at 13 34 12" src="https://user-images.githubusercontent.com/75636882/143610180-04e2a98c-bb08-4f06-b81a-9a3a4231d389.png">
</p>

6. Enable Push Notifications
<p align="center">
      <img width="269" alt="Screen Shot 2021-11-26 at 13 35 51" src="https://user-images.githubusercontent.com/75636882/143610372-abab46cc-dd2a-4712-9020-240f9dbaaaf7.png">
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
- You will need to provide `TxPushIPConfig(rtc_ip: .., rtc_port: ..)` to `TxServerConfiguration(pushIPConfig:..)` to get Push calls to work. 
- You will need to implement 'CallKit' to report an incoming call when there’s a VoIP push notification. On iOS 13.0 and later, if you fail to report a call to CallKit, the system will terminate your app. More information on [Apple docs](https://developer.apple.com/documentation/pushkit/pkpushregistrydelegate/2875784-pushregistry) 


#### c. Configure CallKit into your App:
`PushKit` requires you to use `CallKit` when handling VoIP calls. `CallKit` ensures that apps providing call-related services on a user’s device work seamlessly together on the user's device, and respect features like Do Not Disturb. `CallKit` also operates the system's call-related UIs, including the incoming or outgoing call screens. Use `CallKit` to present these interfaces and manage interactions with them.

For more information about `CallKit` you can check the official [Apple docs](https://developer.apple.com/documentation/callkit]). 

__*General Setup:*__
1. Import CallKit:
```Swift
import CallKit
```
2. Initialize CallKit
```Swift
func initCallKit() {
  let configuration = CXProviderConfiguration(localizedName: "TelnyxRTC")
  configuration.maximumCallGroups = 1
  configuration.maximumCallsPerCallGroup = 1
  callKitProvider = CXProvider(configuration: configuration)
  if let provider = callKitProvider {
      provider.setDelegate(self, queue: nil)
  }
}
```

3. Implement `CXProviderDelegate` methods.


__*Audio Session Handling WebRTC + CallKit*__  
 
To get `CallKit` properly working with the `TelnyxRTC SDK` you need to set the audio device state based on the `CallKit` AudioSession state like follows:
```Swift
extension AppDelegate : CXProviderDelegate {

    ...
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        self.telnyxClient?.isAudioDeviceEnabled = true
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        self.telnyxClient?.isAudioDeviceEnabled = false
    }
}
```
</br>

### Disable Push Notification
 Push notfications can be disabled for the current user by calling : 
```
telnyxClient.disablePushNotifications()
```


### Documentation:
For more information you can:
1. Clone the repository
2. And check the exported documentation in:  `docs/index.html`



-----
Questions? Comments? Building something rad? [Join our Slack channel](https://joinslack.telnyx.com/) and share.

## License

[`MIT Licence`](./LICENSE) © [Telnyx](https://github.com/team-telnyx)
