# Native iOS Client SDK

Enable Telnyx real-time communication services on IOS.
The Telnyx iOS WebRTC Client SDK provides all the functionality you need to start making voice calls from an iPhone.

## Project structure: 

- SDK project: sdk module, containing all Telnyx SDK components as well as tests.
- Demo application: app module, containing a sample demo application utilizing the sdk module. 

## Project Setup:

1. Clone the repository
2. Open the cloned repository in Xcode and hit the build button to build both the sdk and sample app:
3. Connect a device or start an emulated device and hit the run button

## Usage 
### Cocoapods
**Adding Telnyx to your iOS Client Application:**

If your xcode project is not using [cocoapods](https://cocoapods.org) yet, you will need to configure it.

1. Open your podfile and add the TelnyxRTC. 
```
pod 'TelnyxRTC', '~> 0.1.38'
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
<img width="743" alt="Screen Shot 2021-05-07 at 17 46 08" src="https://user-images.githubusercontent.com/75636882/117506545-235bc180-af5c-11eb-91eb-00d60f5844fa.png" />
</p>

6. Enable VoIP and Audio background modes: Go to Signing & Capabilities tab, press the +Capability button and add those background modes:
<p align="center">
<img width="719" alt="Screen Shot 2021-05-07 at 17 46 54" src="https://user-images.githubusercontent.com/75636882/117506607-3ff7f980-af5c-11eb-8df2-2f9170c12baf.png"/>
</p>

7. Go to your Info.plist file and add the “Privacy - Microphone Usage Description” key with a description that your app requires microphone access in order to make VoIP calls. 
<p align="center">
<img width="911" alt="Screen Shot 2021-05-07 at 17 48 17" src="https://user-images.githubusercontent.com/75636882/117506706-6d44a780-af5c-11eb-87e2-d6be092474f2.png"/>
</p>

8. You are all set!


### Swift Package Manager
Xcode has a built-in support for Swift package manager. To add a package : 

1. Select Files > Add Packages
2. On the Swift Package Manager Screen, Search for the https://github.com/team-telnyx/telnyx-webrtc-ios.git package.
3. Select the **main brach** and click Add Package

<p align="center">
<img width="911" alt="Screen Shot 2021-05-07 at 17 48 17" src="https://github.com/isaacakakpo1/telnyx-webrtc-ios-smp/assets/134492608/39be0ab7-222f-478c-bba9-cb2813bcb81d"/>
</p>

NB: if Add Package gets stuck downloading binaries try File > Packages > Reset Package Caches or Run the command
`rm -rf ~/Library/Caches/org.swift.swiftpm/`  in terminal

Read more in [Apple documentation](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

**Hint: Use either Cocoapods or Swift Package Manager for Individual Packages to avoid Duplicate binaries**

## Telnyx Client

The TelnyxClient connects your application to the Telnyx backend, enabling you to make outgoing calls and handle incoming calls.

The main steps to get the SDK working are:
 1. Initialize the client.
 2. Set the delegate to listen to SDK events.
 3. Connect the client: Login to the backend to receive and start calls.
 4. Place outbound calls.
 5. Incoming calls.


### **1. Initialize the client:**

To begin you will need to instantiate the Telnyx Client:



```Swift
// Initialize the client
let telnyxClient = TxClient()
```

> **Note:** After pasting the above content, Kindly check and remove any new lines added


### **2. Listen to SDK updates:**

To begin you will need to instantiate the Telnyx Client:



Then you will need to set the client delegate to get SDK events and you should implement the protocol wherever you want to receive the events: 

Example of the delegate usage on a ViewController:

```Swift
// Set the delegate
telnyxClient.delegate = self
```

> **Note:** After pasting the above content, Kindly check and remove any new lines added


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
       // start making calls once the client is fully initialized.
    }

    func onSessionUpdated(sessionId: String)  {
       // This function will be executed when a sessionId is received.
    }

    func onIncomingCall(call: Call)  {
       // Someone is calling you.
    }

    func onPushCall(call: Call) {
       // If you have configured Push Notifications and app is in background or the Telnyx Client is disconnected
       // this delegate method will be called after the push notification is received.
       // Update the current call with the incoming call
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

> **Note:** After pasting the above content, Kindly check and remove any new lines added



### **3 - Connect the client:**

In this step, you need to set the parameters to configure your connection. The main parameters are the login credentials used to register into the Telnyx backend.



You can connect using your SIP credentials (sip user and password) or by an access token. You can check how to create your credentials on the following [link](/docs/voice/sip-trunking/quickstart)



**Login with SIP credentials:**

```Swift
let txConfigUserAndPassword = TxConfig(sipUser: “SIP_USER”,
                                       password: “SIP_PASSWORD”)
do {
   // Connect and login
   try telnyxClient.connect(txConfig: txConfigUserAndPassword)
} catch let error {
   print("Error \(error)")
}
```

> **Note:** After pasting the above content, Kindly check and remove any new lines added



**Login with Access Token:**

```Swift
// Use a JWT Telnyx Token to authenticate
let txConfigToken = TxConfig(token: "MY_JWT_TELNYX_TOKEN")

do {
   // Connect and login
   // Use `txConfigToken` 
   try telnyxClient.connect(txConfig: txConfigToken)
} catch let error {
   print("Error \(error)")
}

```

> **Note:** After pasting the above content, Kindly check and remove any new lines added



**The TxConfig Structure:**

Through the TxConfig structure, you can configure the following optional parameters:
<ul>
<li>The Ringtone audio file.</li>
<li>The Ringback tone audio file.</li>
<li>The logging level. </li>
</ul>



### **4 - Outbound calls:**

Once your client is fully connected and logged in you can place outbound calls from your iPhone. You can call a phone number or a SIP URI. To call a SIP URI pass the following as the destinationNumber parameter: **YOUR_DESTINATION_SIP_USER@sip.telnyx.com**



Your client will be ready to place outbound calls only when is logged in. To determine whether your client is ready or not, you need to implement the *TxClientDelegate* and wait for the *onClientReady()* method to be called. 



Example of usage:
```Swift
 // Create a client instance
   self.telnyxClient = TxClient()

   // Assign the delegate to get SDK events
   self.telnyxClient?.delegate = self

   // Connect the client (Check TxClient class for more info)
   self.telnyxClient?.connect(....)

   // Create the call and start calling
   self.currentCall = try self.telnyxClient?.newCall(callerName: "Caller name",
                                                     callerNumber: "155531234567",
                                                     // Destination is required and can be a phone number or SIP URI
                                                     destinationNumber: "18004377950",
                                                     callId: UUID.init(),
                                                     customHeaders:[String:String] = [:])
```

> **Note:** After pasting the above content, Kindly check and remove any new lines added



### **5 - Incoming calls:**

In order to answer an incoming call you will need to be fully connected and logged in.



```Swift
//Init your client
func initTelnyxClient() {
   self.telnyxClient = TxClient()

   // Assign the delegate to get SDK events
   self.telnyxClient?.delegate = self

   // Connect the client (Check TxClient class for more info)
   self.telnyxClient?.connect(....)
}

extension ViewController: TxClientDelegate {
    //....
    func onIncomingCall(call: Call) {
        //We are automatically answering any incoming call as an example, but
        //maybe you want to store a reference of the call, and answer the call after a button press.
        self.myCall = call.answer()
        //We can retrieve custom headers passed from the caller side from our call object :
        self.myCall.inviteCustomHeaders
    }
}
```

> **Note:** After pasting the above content, Kindly check and remove any new line added



## Configure CallKit into your App:
`PushKit` requires you to use `CallKit` when handling VoIP calls. `CallKit` ensures that apps providing call-related services on a user’s device work seamlessly together on the user's device, and respect features like Do Not Disturb. `CallKit` also operates the system's call-related UIs, including the incoming or outgoing call screens. Use `CallKit` to present these interfaces and manage interactions with them.

For more information about `CallKit` you can check the official [Apple docs](https://developer.apple.com/documentation/callkit). 

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

__*Reporting calls with CallKit*__

To properly report calls to callKit with right statuses, you need to invoke the following callKit methods at the right instances: 

1. Starting A New Call : Whenever you start a call, report to callkit using the `provider.reportCall()` method.

```Swift
        let callUpdate = CXCallUpdate()

        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false
        provider.reportCall(with: uuid, updated: callUpdate)
```

2. When user receives a Call: Use `provider.reportNewIncomingCall(with: uuid, update: callUpdate)` to report an incoming call. This sends a request to callKit the to provide the native call interface to the user.

```Swift
        guard let provider = callKitProvider else {
            print("AppDelegate:: CallKit provider not available")
            return
        }

        let callHandle = CXHandle(type: .generic, value: from)
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle

        provider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
            // handle error
        }
```

3. When callee answers an outgoing call: Use `provider.reportOutgoingCall(with: callKitUUID, connectedAt:nil)` to report a connected outgoing call. This provides the time when the outgoing call goes to active to callKit.
```Swift
        if let provider = self.callKitProvider,
            let callKitUUID = self.callKitUUID {
            let date = Date()
            provider.reportOutgoingCall(with: callKitUUID, connectedAt:date)
        }
```
NB: This should be used only when the call is outgoing.


### Best Practices when Using PushNotifications with Callkit.

1. When receiving calls from push notifications, it is always required to wait for the connection to the WebSocket before fulfilling the call answer action. This can be achieved by implementing the CXProviderDelegate in the following way (SDK version >=0.1.11):
```Swift
func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        self.telnyxClient?.answerFromCallkit(answerAction: action)
}
```

When the `answerFromPush(answerAction: action)` is called, Callkit sets the call state to `connecting` to alert the user that the call is being connected. 
Once the call is active, the timer starts.

<table align="center">
<tbody>
        <tr>
           <td>Connecting State</td>
           <td>Active call</td>
        </tr>
        <tr>
          <td><img src="https://github.com/team-telnyx/telnyx-webrtc-ios/assets/134492608/13e9efd0-07e2-4a7e-9e7a-b2484b96be47" width="270"/></td>
          <td><img src="https://github.com/team-telnyx/telnyx-webrtc-ios/assets/134492608/89d506a5-bf97-42f2-bd64-5aa54b202db8" width="270"/></td>
        </tr>
</tbody>
</table>
   
The previous SDK versions require handling the websocket connection state on the client side. It can be done in the following way:

```Swift
var callAnswerPendingFromPush:Bool = false

func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("AppDelegate:: ANSWER call action: callKitUUID [\(String(describing: self.callKitUUID))] action [\(action.callUUID)]")
        if(currentCall != nil){
            self.currentCall?.answer()
        }else {
            self.callAnswerPendingFromPush = true
        }
        action.fulfill()
}

func onPushCall(call: Call) {
        print("AppDelegate:: TxClientDelegate onPushCall() \(call)")
        self.currentCall = call //Update the current call with the incoming call
        
        //Answer Call if call was answered from callkit
        //This happens when there's a race condition between login and receiving PN
        // when User answer's the call from PN and there's no Call or INVITE message yet. Set callAnswerPendingFromPush = true
        // Whilst we wait fot onPushCall Method to be called
         if(self.callAnswerPendingFromPush){
            self.currentCall?.answer()
            self.callAnswerPendingFromPush = false
        }
        
}
```

Likewise for ending calls, the  `endCallFromCallkit(endAction:action)` method should be called from :
   
```Swift
func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
     
        self.telnyxClient?.endCallFromCallkit(endAction:action)
     
}
```
Calling this method solves the race condition, where the call is ended before the client connects to the webserver. This way the call is
ended on the callee side once a connection is established.
   
   
2. Logs on the receiver's end are essential for thorough debugging of issues related to push notifications. However, the debugger is not attached when the app is completely killed. To address this, you can simply put the app in the background. VOIP push notifications should then come through, and the debugger should capture all logs.



## Add Push Notifications capability to your Xcode project

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

For more information about Pushkit you can check the official [Apple docs](https://developer.apple.com/documentation/pushkit). 



### Disable Push Notification
 Push notfications can be disabled for the current user by calling : 
```
telnyxClient.disablePushNotifications()
```
Note : Signing back in, using same credentials will re-enable push notifications.



## Custum Headers 
### Passing Custom Headers 
Custom headers can be passed to the `telnyxClient?.newCall(..)` and `currentCall?.answer(..)` method, as a dictionary with the key in the fromat `X-[Name-of-Header]` and a string value.

```Swift
 let headers =  ["X-test1":"ios-header-test","X-test2":"ios-header-2"]

self.telnyxClient?.newCall(callerName: "Caller name",
                                                     callerNumber: "155531234567",
                                                     // Destination is required and can be a phone number or SIP URI
                                                     destinationNumber: "18004377950",
                                                     callId: UUID.init(),
                                                     customHeaders: headers)

// Passed for answerFromCallkit
telnyxClient?.answerFromCallkit(answerAction: action,customHeaders:headers)

// Passed for answer
currentCall?.answer(customHeaders: headers)

```
### Accessing Custom Headers
Custom headers can be accessed for both incoming calls and outgoing calls using `call.inviteCustomHeaders` and `call.answerCustomHeaders` which return a disctionary.
```Swift

// access inviteCustomHeaders for incoming call
func onIncomingCall(call: Call) {
        print("AppDelegate:: TxClientDelegate onPushCall() \(call)")
        self.currentCall = call //Update the current call with the incoming call
        let headers = call.inviteCustomHeaders
 }

// access inviteCustomHeaders for push notification call
func onPushCall(call: Call) {
        print("AppDelegate:: TxClientDelegate onPushCall() \(call)")
        self.currentCall = call //Update the current call with the incoming call
        let headers = call.inviteCustomHeaders
 }

 //access headers for when callstate is updated
 func onCallStateUpdated(callState: CallState, callId: UUID) {
        if(callState == .ACTIVE){
            // check if custom headers was passed for answered message
            let headers = self.currentCall?.answerCustomHeaders
        }
    }
```

**Before uploading your app to TestFlight:**

The WebRTC SDK requires access to the device microphone to make audio calls. To avoid rejection from Apple when uploading a build to TestFlight, remember to add the following key to your info.plist:

<ol>
<li>Privacy - Microphone Usage Description</li>
</ol>


Microphone permission will be requested when making the first outbound call or when receiving the first inbound call.



Questions? Comments? Building something rad? <a href="https://joinslack.telnyx.com/">Join our Slack channel</a> and share.
