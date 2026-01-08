# Telnyx-webrtc-ios

Enable Telnyx real-time communication services on iOS. 

## Project Structure

- SDK project: Enable Telnyx WebRTC communications.
- SDK Tests project.
- Demo app project. 


## Project Setup:

1. Clone the repository
2. Run the command `pod install` to install the dependencies inside the project root folder.
3. Open the Workspace : `TelnyxRTC.xcworkspace`
4. **Configure the Demo App (Optional):**
   - The `Config.xcconfig` file is included in the repository with default values
   - To use the Pre-call Diagnosis feature, edit `Config.xcconfig` and set a valid phone number:
     ```
     PHONE_NUMBER = +15551234567
     ```
   - If you don't need Pre-call Diagnosis, you can leave `PHONE_NUMBER` empty
5. You will find 3 targets to build: 
      - The SDK
      - The SDK Tests
      - The Demo App
      
<p align="center">
  <img width="247" alt="Screen Shot 2021-05-04 at 18 34 45" src="https://user-images.githubusercontent.com/75636882/117073153-e8f9e680-ad07-11eb-9d1f-685397b071a6.png"/>
</p>

5. Select the target `TelnyxRTC (TelnyxRTC Project)` to build the SDK
<p align="center">
<img width="243" alt="Screen Shot 2021-05-04 at 18 35 18" src="https://user-images.githubusercontent.com/75636882/117073140-e3040580-ad07-11eb-8ac6-dc99531550e3.png"/>

</p>
7. Select the target `TelnyxRTCTests` to run the tests. You will need to long press over the Run button and select `Build for testing`

<p align="center">
<img width="153" align="center" alt="Screen Shot 2021-03-03 at 10 04 05" src="https://user-images.githubusercontent.com/75636882/109810077-d4b24400-7c07-11eb-91ec-d81e72ae9069.png"/>
</p>

7.  Select target `TelnyxWebRTCDemo` to run the demo app. The SDK should be manually built in order to get the app running (Step 5)




## SIP Credentials
In order to start making and receiving calls using the TelnyxRTC SDK you will need to get SIP Credentials:

1. Access to https://portal.telnyx.com/
2. Sign up for a Telnyx Account.
3. Create a Credential Connection to configure how you connect your calls.
4. Create an Outbound Voice Profile to configure your outbound call settings and assign it to your Credential Connection.

For more information on how to generate SIP credentials check the [Telnyx WebRTC quickstart guide](https://developers.telnyx.com/docs/v2/webrtc/quickstart). 

## Region Selection

The TelnyxRTC SDK supports connecting to different geographic regions to optimize call quality and reduce latency. The demo app includes a region selection feature that allows users to choose their preferred region.

### Available Regions

- **Auto (Default)**: Automatically selects the best region based on network conditions
- **US East**: East coast United States servers
- **US Central**: Central United States servers  
- **US West**: West coast United States servers
- **Canada Central**: Central Canada servers
- **Europe**: European servers
- **Asia Pacific**: Asia Pacific servers

### Using Region Selection

1. **In the Demo App**: Use the overflow menu (⋯) to access region selection. The current region is displayed as "Region: [current-region]".

2. **In Your App**: Configure the region when creating a `TxServerConfiguration`:

```swift
// Set specific region
let serverConfig = TxServerConfiguration(
    environment: .production,
    region: .usEast  // or .eu, .usCentral, .usWest, .caCentral, .apac
)

// Use auto region selection (default)
let serverConfig = TxServerConfiguration(
    environment: .production,
    region: .auto
)

try telnyxClient.connect(txConfig: txConfig, serverConfiguration: serverConfig)
```

### Region Selection Behavior

- **During Active Calls**: Region selection is automatically disabled during active calls to prevent connection disruption
- **When Connected**: Region selection is disabled when the client is connected to prevent disrupting the established connection
- **Fallback Logic**: If a regional server is unavailable, the SDK automatically falls back to the auto region
- **Persistence**: The selected region persists across app sessions until manually changed

### Best Practices

- Use **Auto** region for the best overall experience unless you have specific latency requirements
- Select a region **geographically close** to your users for optimal call quality
- Test different regions in your target deployment areas to determine the best performance 



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
<img width="743" alt="Screen Shot 2021-05-07 at 17 46 08" src="https://user-images.githubusercontent.com/75636882/117506545-235bc180-af5c-11eb-91eb-00d60f5844fa.png" />
</p>

6. Enable VoIP and Audio background modes: Go to Signing & Capabilities tab, press the +Capability button and add those background modes:
<p align="center">
<img width="719" alt="Screen Shot 2021-05-07 at 17 46 54" src="https://user-images.githubusercontent.com/75636882/117506607-3ff7f980-af5c-11eb-8df2-2f9170c12baf.png" />
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
                                       // Force TURN relay to avoid local network access
                                       forceRelayCandidate: true,
                                       //You can choose the appropriate verbosity level of the SDK.
                                       //Logs are disabled by default
                                       logLevel: .all)

// Or use a JWT Telnyx Token to authenticate
let txConfigToken = TxConfig(token: "MY_JWT_TELNYX_TOKEN",
                             pushDeviceToken: "DEVICE_APNS_TOKEN",
                             ringtone: "incoming_call.mp3",
                             ringBackTone: "ringback_tone.mp3",
                             // Force TURN relay to avoid local network access
                             forceRelayCandidate: true,
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
Note: you need to release the delegate manually when you are done.

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
      case .DONE(let reason):
          // The DONE state may include a termination reason with details about why the call ended
          if let reason = reason {
              print("Call ended with reason: \(reason.cause ?? "Unknown")")
              print("SIP code: \(reason.sipCode ?? 0), SIP reason: \(reason.sipReason ?? "None")")
          }
          break
      case .HELD:
          break
      case .RECONNECTING(let reason):
          print("Call reconnecting: \(reason.rawValue)")
          break
      case .DROPPED(let reason):
          print("Call dropped: \(reason.rawValue)")
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

## AI Agent Integration

The Telnyx iOS WebRTC SDK provides comprehensive support for AI Agent functionality, enabling intelligent voice applications with real-time conversation capabilities.

### Key Features

- **Anonymous Authentication**: Connect to AI assistants without SIP credentials
- **Real-time Transcripts**: Live conversation transcripts with role identification
- **Mixed Communication**: Send text messages during voice calls
- **Widget Settings**: Customizable AI assistant interface

### Quick Start

```swift
import TelnyxRTC

class AIAgentViewController: UIViewController {
    private let client = TxClient()
    private var currentCall: Call?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
        setupAIAgent()
    }
    
    private func setupAIAgent() {
        // Step 1: Anonymous login to AI assistant
        client.anonymousLogin(
            targetId: "your-ai-assistant-id",
            targetType: "ai_assistant"
        )
    }
    
    private func startConversation() {
        // Step 2: Start conversation (destination ignored after anonymous login)
        currentCall = client.newInvite(
            callerName: "User",
            callerNumber: "user",
            destinationNumber: "ai-assistant", // Ignored after anonymous login
            callId: UUID()
        )
    }
    
    private func sendTextMessage() {
        // Step 3: Send text message during call
        let success = client.sendAIAssistantMessage("Hello, can you help me?")
        print("Message sent: \(success)")
    }
    
    private func subscribeToTranscripts() {
        // Step 4: Listen to real-time transcripts
        let cancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { transcripts in
            DispatchQueue.main.async {
                self.updateTranscriptUI(transcripts)
            }
        }
        // Store cancellable to manage subscription lifecycle
    }
}

extension AIAgentViewController: TxClientDelegate {
    func onClientReady() {
        print("Client ready - can start AI conversation")
        startConversation()
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        switch callState {
        case .ACTIVE:
            print("AI conversation active")
            subscribeToTranscripts()
        case .DONE:
            print("AI conversation ended")
        default:
            break
        }
    }
}
```

### Implementation Steps

1. **[Anonymous Login](docs-markdown/ai-agent/anonymous-login.md)** - Authenticate with AI assistants without SIP credentials
2. **[Starting Conversations](docs-markdown/ai-agent/starting-conversations.md)** - Initiate calls with AI agents
3. **[Transcript Updates](docs-markdown/ai-agent/transcript-updates.md)** - Handle real-time conversation transcripts
4. **[Text Messaging](docs-markdown/ai-agent/text-messaging.md)** - Send text messages during voice calls

### Complete Documentation

For comprehensive AI Agent integration documentation, see:
- **[AI Agent Introduction](docs-markdown/ai-agent/introduction.md)** - Overview and architecture
- **[AIAssistantManager API](docs-markdown/classes/AIAssistantManager.md)** - Complete API reference
- **[TranscriptionItem Structure](docs-markdown/structs/TranscriptionItem.md)** - Transcript data format
- **[WidgetSettings Configuration](docs-markdown/structs/WidgetSettings.md)** - UI customization options

---

## Preferred Audio Codecs

The SDK allows you to configure preferred audio codecs for your WebRTC calls. This feature enables you to prioritize specific codecs based on your application's requirements for audio quality, bandwidth usage, or network conditions.

### Getting Supported Codecs

Query the list of audio codecs supported by the device and WebRTC framework:

```swift
// Get all supported audio codecs
let supportedCodecs = telnyxClient.getSupportedAudioCodecs()

// Print codec information
for codec in supportedCodecs {
    print("Codec: \(codec.mimeType), Clock Rate: \(codec.clockRate) Hz")
}
```

### Setting Preferred Codecs

**For Outbound Calls:**

```swift
// Define your preferred codecs in order of priority
let preferredCodecs = [
    TxCodecCapability(mimeType: "audio/opus", clockRate: 48000, channels: 2),
    TxCodecCapability(mimeType: "audio/PCMU", clockRate: 8000, channels: 1)
]

// Create a call with preferred codecs
let call = try telnyxClient.newCall(
    callerName: "John Doe",
    callerNumber: "1234567890",
    destinationNumber: "18004377950",
    callId: UUID(),
    preferredCodecs: preferredCodecs  // Pass preferred codecs
)
```

**For Inbound Calls:**

```swift
func onIncomingCall(call: Call) {
    let preferredCodecs = [
        TxCodecCapability(mimeType: "audio/opus", clockRate: 48000, channels: 2),
        TxCodecCapability(mimeType: "audio/PCMU", clockRate: 8000, channels: 1)
    ]

    // Answer with preferred codecs
    call.answer(preferredCodecs: preferredCodecs)
}
```

### Common Codec Configurations

**High Quality Audio (VoIP apps):**
```swift
let preferredCodecs = [
    TxCodecCapability(mimeType: "audio/opus", clockRate: 48000, channels: 2)
]
```

**Traditional Telephony Compatibility:**
```swift
let preferredCodecs = [
    TxCodecCapability(mimeType: "audio/PCMU", clockRate: 8000, channels: 1),
    TxCodecCapability(mimeType: "audio/PCMA", clockRate: 8000, channels: 1)
]
```

**Low Bandwidth Optimization:**
```swift
let preferredCodecs = [
    TxCodecCapability(mimeType: "audio/iLBC", clockRate: 8000),
    TxCodecCapability(mimeType: "audio/PCMU", clockRate: 8000)
]
```

For detailed documentation on codec selection, configuration options, and best practices, see the [Preferred Audio Codecs Guide](docs-markdown/audio-codecs/preferred-codecs.md).

---

## Call Termination Reasons

When a call ends, the SDK provides detailed information about why the call was terminated through the `CallTerminationReason` structure. This information is available in the `DONE` state of the call.

### CallTerminationReason Structure

The `CallTerminationReason` structure contains the following fields:

- `cause`: A string describing the general cause of the call termination (e.g., "CALL_REJECTED", "USER_BUSY")
- `causeCode`: A numerical code corresponding to the cause
- `sipCode`: The SIP response code (e.g., 403, 404)
- `sipReason`: The SIP reason phrase (e.g., "Dialed number is not included in whitelisted countries")

### Accessing Call Termination Reasons

You can access the termination reason in the `onCallStateUpdated` delegate method:

```swift
func onCallStateUpdated(callState: CallState, callId: UUID) {
    switch callState {
    case .DONE(let reason):
        if let reason = reason {
            // Access termination details
            let cause = reason.cause
            let sipCode = reason.sipCode
            let sipReason = reason.sipReason
            
            // Display or log the information
            print("Call ended: \(cause ?? "Unknown"), SIP: \(sipCode ?? 0) \(sipReason ?? "")")
        }
        break
    // Handle other states...
    }
}
```

### Common Termination Causes

The SDK provides various termination causes, including:

- `NORMAL_CLEARING`: Call ended normally
- `USER_BUSY`: The called party is busy
- `CALL_REJECTED`: The call was rejected
- `UNALLOCATED_NUMBER`: The dialed number is invalid
- `INCOMPATIBLE_DESTINATION`: The destination cannot handle the call type

## WebRTC Statistics

The SDK provides WebRTC statistics functionality to assist with troubleshooting and monitoring call quality. This feature is controlled through the `debug` flag in the `TxClient` configuration.

### Enabling WebRTC Statistics

To enable WebRTC statistics logging:

```Swift
let txConfig = TxConfig(sipUser: sipUser,
                       password: password,
                       pushDeviceToken: "DEVICE_APNS_TOKEN",
                       debug: true) // Enable WebRTC statistics
```

### Understanding WebRTC Statistics

When `debug: true` is configured:
- WebRTC statistics logs are automatically collected during calls
- Logs are sent to the Telnyx portal and are accessible in the Object Storage section
- Statistics are linked to the SIP credential used for testing
- The logs help the Telnyx support team diagnose issues and optimize call quality

### Real-time Call Quality Monitoring

The SDK provides real-time call quality metrics through the `onCallQualityChange` callback on the `Call` object. This allows you to monitor call quality in real-time and provide feedback to users.

#### Using onCallQualityChanged

```Swift
// When creating a new call set debug to true for CallQualityMetrics
let call = try telnyxClient.newCall(callerName: "Caller name",
                                   callerNumber: "155531234567",
                                   destinationNumber: "18004377950",
                                   callId: UUID.init(),debug:true)
                                   
//When accepting a call
telnyxClient?.answerFromCallkit(answerAction: action,debug:true) or call?.answer(debug:true)

// Set the onCallQualityChange callback
call.onCallQualityChange = { metrics in
    // Handle call quality metrics
    print("Call quality: \(metrics.quality.rawValue)")
    print("MOS score: \(metrics.mos)")
    print("Jitter: \(metrics.jitter * 1000) ms")
    print("Round-trip time: \(metrics.rtt * 1000) ms")
    
    // Update UI based on call quality
    switch metrics.quality {
    case .excellent, .good:
        // Show excellent/good quality indicator
        self.qualityIndicator.backgroundColor = .green
    case .fair:
        // Show fair quality indicator
        self.qualityIndicator.backgroundColor = .yellow
    case .poor, .bad:
        // Show poor/bad quality indicator
        self.qualityIndicator.backgroundColor = .red
        // Optionally show a message to the user
    case .unknown:
        // Quality couldn't be determined
        self.qualityIndicator.backgroundColor = .gray
    }
}
```
#### CallQualityMetrics Properties

The `CallQualityMetrics` object provides the following properties:

| Property             | Type            | Description |
|----------------------|-----------------|-------------|
| `jitter`             | Double          | Jitter in seconds (multiply by 1000 for milliseconds) |
| `rtt`                | Double          | Round-trip time in seconds (multiply by 1000 for milliseconds) |
| `mos`                | Double          | Mean Opinion Score (1.0-5.0) |
| `quality`            | CallQuality     | Call quality rating based on MOS |
| `inboundAudio`       | [String: Any]?  | Inbound audio statistics |
| `outboundAudio`      | [String: Any]?  | Outbound audio statistics |
| `remoteInboundAudio` | [String: Any]?  | Remote inbound audio statistics |
| `remoteOutboundAudio`| [String: Any]?  | Remote outbound audio statistics |



#### CallQuality Enum
| Value         | MOS Range       | Description |
|---------------|-----------------|-------------|
| `.excellent`  | MOS > 4.2       | Excellent call quality |
| `.good`       | 4.1 ≤ MOS ≤ 4.2 | Good call quality |
| `.fair`       | 3.7 ≤ MOS ≤ 4.0 | Fair call quality |
| `.poor`       | 3.1 ≤ MOS ≤ 3.6 | Poor call quality |
| `.bad`        | MOS ≤ 3.0       | Bad call quality |
| `.unknown`    | N/A             | Unable to calculate quality |


#### Best Practices for Call Quality Monitoring

1. **User Feedback**: 
   - Consider showing a visual indicator of call quality to users
   - For poor quality calls, provide suggestions (e.g., "Try moving to an area with better connectivity")

2. **Logging**:
   - Log quality metrics for later analysis
   - Track quality trends over time to identify patterns

3. **Adaptive Behavior**:
   - Implement adaptive behaviors based on call quality
   - For example, suggest switching to audio-only if video quality is poor

4. **Performance Considerations**:
   - The callback is triggered periodically (approximately every 2 seconds)

### Important Notes

1. **Log Access**: 
   - If you run the app using SIP credential A with `debug: true`, the WebRTC logs will be available in the Telnyx portal account associated with credential A
   - Logs are stored in the Object Storage section of your Telnyx portal

2. **Troubleshooting Support**:
   - WebRTC statistics are primarily intended to assist the Telnyx support team
   - When requesting support, enable `debug: true` in `TxClient` for all instances
   - Provide the `debug ID` or `callId` when contacting support
   - Statistics logging is disabled by default to optimize performance

3. **Best Practices**:
   - Enable `debug: true` only when troubleshooting is needed
   - Remember to provide the `debug ID` or `callId` in support requests
   - Consider disabling debug mode in production unless actively investigating issues

---


## Custom Logging

The SDK provides a flexible logging system that allows you to implement your own custom logger. This feature enables you to route SDK logs to your preferred logging framework or format.

### Implementing a Custom Logger

To create a custom logger, implement the `TxLogger` protocol:

```Swift
class MyCustomLogger: TxLogger {
    func log(level: LogLevel, message: String) {
        // Implement your custom logging logic here
        // Example: Send logs to your analytics service
        MyAnalyticsService.log(
            level: level,
            message: message,
        )
    }
}
```

### Using a Custom Logger

To use your custom logger, pass it to the `TxConfig` when initializing the client:

```Swift
let customLogger = MyCustomLogger()
let txConfig = TxConfig(
    sipUser: sipUser,
    password: password,
    logLevel: .all,           // Set desired log level
    customLogger: customLogger // Pass your custom logger
)
```

### Default Logger

If no custom logger is provided, the SDK uses `TxDefaultLogger` which prints logs to the console with appropriate formatting and emojis for different log levels.

### Important Notes

1. **Log Levels**: 
   - The `logLevel` parameter in `TxConfig` still controls which logs are processed
   - Custom loggers only receive logs that match the configured verbosity level

2. **Thread Safety**:
   - Ensure your custom logger implementation is thread-safe
   - Log callbacks may come from different threads

3. **Performance**:
   - Keep logging operations lightweight to avoid impacting call quality
   - Consider asynchronous logging for heavy operations

4. **Best Practices**:
   - Handle all log levels appropriately
   - Include timestamps for proper log sequencing
   - Consider log persistence for debugging
   - Handle errors gracefully within the logger

---


## Push Notifications Setup

In order to receive incoming calls while the app is running in background or closed, you will need to perform a set of configurations over your Mission Control Portal Account and your application. 

For detailed documentation on setting up push notifications, see:
- [App Setup](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/push-notification/app-setup) - Configure your iOS app to receive VoIP push notifications
- [Portal Setup](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/push-notification/portal-setup) - Set up your Telnyx Portal account with VoIP push credentials
- [Troubleshooting](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/push-notification/troubleshooting) - Debug common push notification issues

---

## Trickle ICE

The SDK supports Trickle ICE, which enables faster call setup by sending ICE candidates incrementally as they are discovered, rather than waiting for all candidates before establishing the connection.

### Key Features

- **Faster Call Establishment**: Candidates are sent immediately as discovered, reducing connection time
- **Automatic Management**: No configuration required - the SDK handles Trickle ICE automatically
- **Smart Queuing**: Answering side queues candidates until ANSWER is sent to prevent race conditions
- **Candidate Cleaning**: WebRTC extensions are removed for maximum server compatibility

### How It Works

**Outbound Calls**: Candidates are sent immediately as they are generated

**Inbound Calls**: Candidates are queued until the call is answered, then flushed all at once followed by real-time sending of new candidates

This approach prevents race conditions where candidates might arrive before the answer, ensuring reliable call setup.

For comprehensive documentation on Trickle ICE implementation, troubleshooting, and technical details, see the [Trickle ICE Guide](docs-markdown/trickle-ice/trickle-ice.md).

### Testing VoIP Push Notifications

The repository includes a dedicated testing tool to help validate your VoIP push notification setup. This tool allows you to send test push notifications directly to your device using your own certificates and configuration.

**Location**: `push-notification-tool/` in the repository root

#### Quick Setup

```bash
cd push-notification-tool
npm install 
npm run dev
```

#### What the Tool Does

- **Validates Configuration**: Tests your certificate files, bundle ID, and device token
- **Sends Test Pushes**: Generates VoIP notifications with SDK-compatible payload structure  
- **Provides Detailed Errors**: Clear error messages to help identify configuration issues
- **Supports Continuous Testing**: Send multiple pushes, switch configurations, test different scenarios
- **Smart Configuration Management**: Saves settings between sessions for faster iteration

#### Perfect for Testing

- Certificate and environment validation
- Device token verification  
- Payload structure compatibility
- Multi-device testing
- Troubleshooting push delivery issues

For complete setup instructions and usage examples, see the tool's [README](https://github.com/team-telnyx/telnyx-webrtc-ios/tree/main/push-notification-tool) or the [Troubleshooting Guide](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/push-notification/troubleshooting#testing-voip-push-notifications).



### VoIP Push - Portal setup

During this process you will learn how to create a VoIP push credential and assign the credential to a SIP Connection. 

This process requires:
* A Mission Control Portal Account. 
* A SIP Connection.
* Your Apple VoIP push certificate.

For complete instructions on how to setup Push Notifications got to this [link](https://developers.telnyx.com/docs/v2/webrtc/push-notifications).



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
        self.telnyxClient?.enableAudioSession(audioSession: audioSession)
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        self.telnyxClient?.disableAudioSession(audioSession: audioSession)
    }
}
```


__*Reporting calls with CallKit*__

To properly report calls to callKit with right statuses, you need to invoke the following callKit methods at the right instances: 

1. Starting A New Call : When ever you start a call, report to callkit using the `provider.reportCall()` method.

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

2. When user receives a Call : Use `provider.reportNewIncomingCall(with: uuid, update: callUpdate)` to report an incoming call. This sends a request to callKit the to provide the native call interface to the user.

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

3. When callee answers an outgoing call : Use `provider.reportOutgoingCall(with: callKitUUID, connectedAt:nil)` to report a connected outgoing call. This provides the time when the outgoing call goes to active to callKit.
```Swift
        if let provider = self.callKitProvider,
            let callKitUUID = self.callKitUUID {
            let date = Date()
            provider.reportOutgoingCall(with: callKitUUID, connectedAt:date)
        }
```
NB : This should be used only when the call is outgoing.


### Best Practices when Using PushNotifications with Callkit.

1. When receiving calls from push notifications, it is always required to wait for the connection to the WebSocket before fulfilling the call answer action. This can be achieved by implementing the CXProviderDelegate in the following way (SDK version >=0.1.11):
```Swift
func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        self.telnyxClient?.answerFromCallkit(answerAction: action)
}
```

When the `answerFromPush(answerAction: action)` is called, Callkit sets the call state to `connecting` to alert the user that the call is being connected. 
Once the call is active, the timer starts.

| Connecting State | Active Call |
|------------------|-------------|
| <img src="https://github.com/team-telnyx/telnyx-webrtc-ios/assets/134492608/13e9efd0-07e2-4a7e-9e7a-b2484b96be47" width="270"/> | <img src="https://github.com/team-telnyx/telnyx-webrtc-ios/assets/134492608/89d506a5-bf97-42f2-bd64-5aa54b202db8" width="270"/> |


   
The previous SDK versions requires handling the websocket connection state on the client side. It can be done in the following way:

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
   Calling this method solves the race condition, where call is ended before the client connects to the webserver. This way the call is
   ended on the callee side once a connection is established.
   
   
2. Logs on the receiver's end are essential for thorough debugging of issues related to push notifications. However, the debugger is not attached when the app is completely killed. To address this, you can simply put the app in the background. VOIP push notifications should then come through, and the debugger should capture all logs.

__*Handling Multiple Calls*__

To handle multiples, we can rely on the `CXProviderDelegate` delegate which invokes functions corresponding to 
what action was performed on the callkit user interface. 

1. End and Accept or Decline : The **end and accept** button on the callkit user interface accepts the new call and ends the previous call.
Callkit then invokes the `CXAnswerCallAction` and `CXEndCallAction` when the **end and accept** button is pressed.
You can handle this scenario by

```Swift 
 var currentCall: Call?
 var previousCall: Call?
 
 //current calkit uuid
 var callKitUUID: UUID?

     func onIncomingCall(call: Call) {
        guard let callId = call.callInfo?.callId else {
            print("AppDelegate:: TxClientDelegate onIncomingCall() Error unknown call UUID")
            return
        }
        print("AppDelegate:: TxClientDelegate onIncomingCall() callKitUUID [\(String(describing: self.callKitUUID))] callId [\(callId)]")

        self.callKitUUID = call.callInfo?.callId
        
        //Update the previous call with the current call
        self.previousCall = self.currentCall
        
        //Update the current call with the incoming call
        self.currentCall = call 
        ..
  }

```
Subsequently, when the user clicks on the End and Accept or Decline Button, you will need to determine which of these buttons was clicked.
You can do that as follows:

```Swift
    //Callkit invokes CXEndCallAction and  CXAnswerCallAction delegate function for accept and answer
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("AppDelegate:: END call action: callKitUUID [\(String(describing: self.callKitUUID))] action [\(action.callUUID)]")
        
        // if the callKitUUID is the same as the one provided by the action
        // callkit expects you to end the current call
        if(self.callKitUUID == action.callUUID){
            if let onGoingCall = self.previousCall {
                self.currentCall = onGoingCall
                self.callKitUUID = onGoingCall.callInfo?.callId
            }
        }else {
            // callkit expects you to end the previous call
            self.callKitUUID = self.currentCall?.callInfo?.callId
        }
        self.telnyxClient?.endCallFromCallkit(endAction:action)
    }
```

 **Note** 

While handling multiple calls, you should report the **call end** to callkit properly with the right callUUID. This will keep your  active calls with the callkit
user interface until there are no more active sessions.

2. Hold and Accept or Decline: The **hold and accept** button on the callkit user interface accepts the new call and holds the previous call.
Callkit then invokes the `CXSetHeldCallAction` when the **hold and accept** button is pressed. 

```Swift
 func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("provider:performSetHeldAction:")
        //request to hold previous call, since we have both the current and previous calls
        previousCall?.hold()
        action.fulfill()
 }
```
Also, you will need to un-hold the previous call when the current call gets ended on `CXEndCallAction`.

```Swift

   func provider(_ provider: CXProvider, perform action: CXEndCallAction) {        
        if(previousCall?.callState == .HELD){
            print("AppDelegate:: call held.. unholding call")
            previousCall?.unhold()
        }
        ...
   }
```
**Note**

While handling multiple calls, you should report the **call end** to callkit properly with the right callUUID. This will keep your  active calls with the callkit
user interface until there are no more active sessions.


### Disable Push Notification
 Push notifications can be disabled for the current user by calling : 
```
telnyxClient.disablePushNotifications()
```
Note : Signing back in, using same credentials will re-enable push notifications.

### Privacy Manifest
Support for privacy manifest is added from version 0.1.26

### Documentation:
For more information you can:
1. Clone the repository
2. And check the exported documentation in:  `docs/index.html`

## Support

Find official documentation [here](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk)

Questions? Comments? Building something rad? <a href="https://joinslack.telnyx.com/">Join our Slack channel</a> and share.

## License

[`MIT Licence`](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/LICENSE) © [Telnyx](https://github.com/team-telnyx)
