**CLASS**

# `TxClient`

```swift
public class TxClient
```

The `TelnyxRTC` client connects your application to the Telnyx backend,
enabling you to make outgoing calls and handle incoming calls.

## Examples
### Connect and login:

```
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
                                       ringtone: "incoming_call.mp3",
                                       ringBackTone: "ringback_tone.mp3",
                                       //You can choose the appropriate verbosity level of the SDK.
                                       //Logs are disabled by default
                                       logLevel: .all)

// Use a JWT Telnyx Token to authenticate (recommended)
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

### Listen TxClient delegate events.

```
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
        DispatchQueue.main.async {
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
}
```

## Properties
### `calls`

```swift
public internal(set) var calls: [UUID: Call] = [UUID: Call]()
```

Keeps track of all the created calls by theirs UUIDs

### `delegate`

```swift
public weak var delegate: TxClientDelegate?
```

Subscribe to TxClient delegate to receive Telnyx SDK events

### `aiAssistantManager`

```swift
public let aiAssistantManager = AIAssistantManager()
```

AI Assistant Manager for handling AI-related functionality

### `isSpeakerEnabled`

```swift
public private(set) var isSpeakerEnabled: Bool
```

### `isAudioDeviceEnabled`

```swift
public var isAudioDeviceEnabled : Bool
```

Controls the audio device state when using CallKit integration.
This property manages the WebRTC audio session activation and deactivation.

When implementing CallKit, you must manually handle the audio session state:
- Set to `true` in `provider(_:didActivate:)` to enable audio
- Set to `false` in `provider(_:didDeactivate:)` to disable audio

Example usage with CallKit:
```swift
extension CallKitProvider: CXProviderDelegate {
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        telnyxClient.isAudioDeviceEnabled = true
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        telnyxClient.isAudioDeviceEnabled = false
    }
}
```

### `isRegistered`

```swift
public var isRegistered: Bool
```

Client must be registered in order to receive or place calls.

## Methods
### `enableAudioSession(audioSession:)`

```swift
public func enableAudioSession(audioSession: AVAudioSession)
```

Enables and configures the audio session for a call.
This method sets up the appropriate audio configuration and activates the session.

- Parameter audioSession: The AVAudioSession instance to configure
- Important: This method MUST be called from the CXProviderDelegate's `provider(_:didActivate:)` callback
            to properly handle audio routing when using CallKit integration.

Example usage:
```swift
func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    print("provider:didActivateAudioSession:")
    self.telnyxClient.enableAudioSession(audioSession: audioSession)
}
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| audioSession | The AVAudioSession instance to configure |

### `disableAudioSession(audioSession:)`

```swift
public func disableAudioSession(audioSession: AVAudioSession)
```

Disables and resets the audio session.
This method cleans up the audio configuration and deactivates the session.

- Parameter audioSession: The AVAudioSession instance to reset
- Important: This method MUST be called from the CXProviderDelegate's `provider(_:didDeactivate:)` callback
            to properly clean up audio resources when using CallKit integration.

Example usage:
```swift
func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    print("provider:didDeactivateAudioSession:")
    self.telnyxClient.disableAudioSession(audioSession: audioSession)
}
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| audioSession | The AVAudioSession instance to reset |

### `init()`

```swift
public init()
```

TxClient has to be instantiated.

### `deinit`

```swift
deinit
```

Deinitializer to ensure proper cleanup of resources

### `connect(txConfig:serverConfiguration:)`

```swift
public func connect(txConfig: TxConfig, serverConfiguration: TxServerConfiguration = TxServerConfiguration()) throws
```

Connects to the iOS cloglient to the Telnyx signaling server using the desired login credentials.
- Parameters:
  - txConfig: The desired login credentials. See TxConfig docummentation for more information.
  - serverConfiguration: (Optional) To define a custom `signaling server` and `TURN/ STUN servers`. As default we use the internal Telnyx Production servers.
- Throws: TxConfig parameters errors

#### Parameters

| Name | Description |
| ---- | ----------- |
| txConfig | The desired login credentials. See TxConfig docummentation for more information. |
| serverConfiguration | (Optional) To define a custom `signaling server` and `TURN/ STUN servers`. As default we use the internal Telnyx Production servers. |

### `disconnect()`

```swift
public func disconnect()
```

Disconnects the TxClient from the Telnyx signaling server.

### `isConnected()`

```swift
public func isConnected() -> Bool
```

To check if TxClient is connected to Telnyx server.
- Returns: `true` if TxClient socket is connected, `false` otherwise.

### `answerFromCallkit(answerAction:customHeaders:debug:)`

```swift
public func answerFromCallkit(answerAction:CXAnswerCallAction,customHeaders:[String:String] = [:], debug:Bool = false)
```

Answers an incoming call from CallKit and manages the active call flow.

This method should be called from the CXProviderDelegate's `provider(_:perform:)` method
when handling a `CXAnswerCallAction`. It properly integrates with CallKit to answer incoming calls.

### Examples:
```swift
extension CallKitProvider: CXProviderDelegate {
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // Basic answer
        telnyxClient.answerFromCallkit(answerAction: action)

        // Answer with custom headers and debug mode
        telnyxClient.answerFromCallkit(
            answerAction: action,
            customHeaders: ["X-Custom-Header": "Value"],
            debug: true
        )
    }
}
```

- Parameters:
  - answerAction: The `CXAnswerCallAction` provided by CallKit's provider delegate.
  - customHeaders: (optional) Custom Headers to be passed over webRTC Messages.
    Headers should be in the format `X-key:Value` where `X-` prefix is required for custom headers.
    When calling AI Agents, headers with the `X-` prefix will be mapped to dynamic variables
    (e.g., `X-Account-Number` becomes `{{account_number}}`). Hyphens in header names are
    converted to underscores in variable names.
  - debug: (optional) Enable debug mode for call quality metrics and WebRTC statistics.
    When enabled, real-time call quality metrics will be available through the call's `onCallQualityChange` callback.

#### Parameters

| Name | Description |
| ---- | ----------- |
| answerAction | The `CXAnswerCallAction` provided by CallKit’s provider delegate. |
| customHeaders | (optional) Custom Headers to be passed over webRTC Messages. Headers should be in the format `X-key:Value` where `X-` prefix is required for custom headers. When calling AI Agents, headers with the `X-` prefix will be mapped to dynamic variables (e.g., `X-Account-Number` becomes `{{account_number}}`). Hyphens in header names are converted to underscores in variable names. |
| debug | (optional) Enable debug mode for call quality metrics and WebRTC statistics. When enabled, real-time call quality metrics will be available through the call’s `onCallQualityChange` callback. |

### `endCallFromCallkit(endAction:callId:)`

```swift
public func endCallFromCallkit(endAction:CXEndCallAction,callId:UUID? = nil)
```

To end and control callKit active and conn

### `disablePushNotifications()`

```swift
public func disablePushNotifications()
```

To disable push notifications for the current user

### `getSessionId()`

```swift
public func getSessionId() -> String
```

Get the current session ID after logging into Telnyx Backend.
- Returns: The current sessionId. If this value is empty, that means that the client is not connected to Telnyx server.

### `anonymousLogin(targetId:targetType:targetVersionId:userVariables:reconnection:serverConfiguration:)`

```swift
public func anonymousLogin(
    targetId: String, 
    targetType: String = "ai_assistant", 
    targetVersionId: String? = nil,
    userVariables: [String: Any] = [:],
    reconnection: Bool = false,
    serverConfiguration: TxServerConfiguration = TxServerConfiguration()
)
```

Performs an anonymous login to the Telnyx backend for AI assistant connections.
This method allows connecting to AI assistants without traditional authentication.

If the socket is already connected, the anonymous login message is sent immediately.
If not connected, the socket connection process is started, and the anonymous login 
message is sent once the connection is established.

- Parameters:
  - targetId: The target ID for the AI assistant
  - targetType: The target type (defaults to "ai_assistant")
  - targetVersionId: Optional target version ID
  - userVariables: Optional user variables to include in the login
  - reconnection: Whether this is a reconnection attempt (defaults to false)
  - serverConfiguration: Server configuration to use for connection (defaults to TxServerConfiguration())

#### Parameters

| Name | Description |
| ---- | ----------- |
| targetId | The target ID for the AI assistant |
| targetType | The target type (defaults to “ai_assistant”) |
| targetVersionId | Optional target version ID |
| userVariables | Optional user variables to include in the login |
| reconnection | Whether this is a reconnection attempt (defaults to false) |
| serverConfiguration | Server configuration to use for connection (defaults to TxServerConfiguration()) |

### `sendRingingAck(callId:)`

```swift
public func sendRingingAck(callId: String)
```

Send a ringing acknowledgment message for a specific call
- Parameter callId: The call ID to acknowledge

#### Parameters

| Name | Description |
| ---- | ----------- |
| callId | The call ID to acknowledge |

### `sendAIAssistantMessage(_:)`

```swift
public func sendAIAssistantMessage(_ message: String) -> Bool
```

Send a text message to AI Assistant during active call (mixed-mode communication)
- Parameter message: The text message to send to AI assistant
- Returns: True if message was sent successfully, false otherwise

#### Parameters

| Name | Description |
| ---- | ----------- |
| message | The text message to send to AI assistant |

### `sendAIAssistantMessage(_:base64Images:imageFormat:)`

```swift
public func sendAIAssistantMessage(_ message: String, base64Images: [String]?, imageFormat: String = "jpeg") -> Bool
```

Send a text message with multiple Base64 encoded images to AI Assistant during active call
- Parameters:
  - message: The text message to send to AI assistant
  - base64Images: Optional array of Base64 encoded image data (without data URL prefix)
  - imageFormat: Image format (jpeg, png, etc.). Defaults to "jpeg"
- Returns: True if message was sent successfully, false otherwise

#### Parameters

| Name | Description |
| ---- | ----------- |
| message | The text message to send to AI assistant |
| base64Images | Optional array of Base64 encoded image data (without data URL prefix) |
| imageFormat | Image format (jpeg, png, etc.). Defaults to “jpeg” |