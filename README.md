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
  

_Don't have SIP credentials? [Follow our guide](https://developers.telnyx.com/docs/v2/sip-trunking/quickstarts/portal-setup) to get set up on our portal and generate them._

-----
</br>

## Adding Telnyx SDK to your iOS Client Application:
Currently the iOS SDK is supported using cocoapods. 

### Cocoapods

If your xcode project is not using [cocoapods](https://cocoapods.org/) yet, you will need to configure it.

1. Open your podfile and add the TelnyxRTC. 
```
pod 'TelnyxRTC', '~> 0.0.1'
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
// This is what we are currently using on the Demo App
let txConfigUserAndPassowrd = TxConfig(sipUser: sipUser,
                                       password: password,
                                       ringtone: "incoming_call.mp3",
                                       ringBackTone: "ringback_tone.mp3",
                                       //You can choose the appropriate verbosity level of the SDK.
                                       //Logs are disabled by default
                                       logLevel: .all)

// Or use a JWT Telnyx Token to authenticate (recommended)
let txConfigToken = TxConfig(token: "MY_JWT_TELNYX_TOKEN",
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
    }

    // You can update your UI from here base on the call states.
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
        //We are automatically answering any incoming call as an example, but
        //maybe you want to store a reference of the call, and answer the call after a button press.
        self.myCall = call.answer()
    }
}
```

### Documentation:
For more information you can:
1. Clone the repository
2. And check the exported documentation in:  `docs/index.html`



-----
Questions? Comments? Building something rad? [Join our Slack channel](https://joinslack.telnyx.com/) and share.

## License

[`MIT Licence`](./LICENSE) © [Telnyx](https://github.com/team-telnyx)
