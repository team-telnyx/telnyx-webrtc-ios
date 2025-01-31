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

### `answerFromCallkit(answerAction:customHeaders:)`

```swift
public func answerFromCallkit(answerAction:CXAnswerCallAction,customHeaders:[String:String] = [:])
```

To answer and control callKit active flow
- Parameters:
    - answerAction : `CXAnswerCallAction` from callKit
    - customHeaders: (Optional)

#### Parameters

| Name | Description |
| ---- | ----------- |
| answerAction | `CXAnswerCallAction` from callKit |
| customHeaders | (Optional) |

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
