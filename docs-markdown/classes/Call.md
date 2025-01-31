**CLASS**

# `Call`

```swift
public class Call
```

A Call represents an audio or video communication session between two endpoints: WebRTC Clients, SIP clients, or phone numbers.
The Call object manages the entire lifecycle of a call, from initiation to termination, handling both outbound and inbound calls.

A Call object is created in two scenarios:
1. When you initiate a new outbound call using TxClient's newCall method
2. When you receive an inbound call through the TxClientDelegate's onIncomingCall callback

## Key Features
- Audio and video call support
- Call state management (NEW, CONNECTING, RINGING, ACTIVE, HELD, DONE)
- Mute/unmute functionality
- DTMF tone sending
- Custom headers support for both INVITE and ANSWER messages
- Call statistics reporting when debug mode is enabled

## Examples
### Creating an Outbound Call:
```swift
   // Initialize the client
   self.telnyxClient = TxClient()
   self.telnyxClient?.delegate = self

   // Connect the client (see TxClient documentation for connection options)
   self.telnyxClient?.connect(....)

   // Create and initiate a call
   self.currentCall = try self.telnyxClient?.newCall(
       callerName: "John Doe",           // The name to display for the caller
       callerNumber: "155531234567",     // The caller's phone number
       destinationNumber: "18004377950", // The target phone number or SIP URI
       callId: UUID.init(),              // Unique identifier for the call
       clientState: nil,                 // Optional client state information
       customHeaders: [:]                // Optional custom SIP headers
   )
```

### Handling an Incoming Call:
```swift
class CallHandler: TxClientDelegate {
    var activeCall: Call?

    func initTelnyxClient() {
        let client = TxClient()
        client.delegate = self
        client.connect(....)
    }

    func onIncomingCall(call: Call) {
        // Store the call reference
        self.activeCall = call

        // Option 1: Auto-answer the call
        call.answer()

        // Option 2: Answer with custom headers
        call.answer(customHeaders: ["X-Custom-Header": "Value"])

        // Option 3: Reject the call
        // call.hangup()
    }
}
```

## Properties
### `inviteCustomHeaders`

```swift
public internal(set) var inviteCustomHeaders: [String:String]?
```

Custom headers received from the WebRTC INVITE message.
These headers are passed during call initiation and can contain application-specific information.
Format should be ["X-Header-Name": "Value"] where header names must start with "X-".

### `answerCustomHeaders`

```swift
public internal(set) var answerCustomHeaders: [String:String]?
```

Custom headers received from the WebRTC ANSWER message.
These headers are passed during call acceptance and can contain application-specific information.
Format should be ["X-Header-Name": "Value"] where header names must start with "X-".

### `sessionId`

```swift
public internal(set) var sessionId: String?
```

The unique session identifier for the current WebRTC connection.
This ID is established during client connection and remains constant for the session duration.

### `telnyxSessionId`

```swift
public internal(set) var telnyxSessionId: UUID?
```

The unique Telnyx session identifier for this call.
This ID can be used to track the call in Telnyx's systems and logs.

### `telnyxLegId`

```swift
public internal(set) var telnyxLegId: UUID?
```

The unique Telnyx leg identifier for this call.
A call can have multiple legs (e.g., in call transfers). This ID identifies this specific leg.

### `debug`

```swift
public internal(set) var debug: Bool = false
```

Enables WebRTC statistics reporting for debugging purposes.
When true, the SDK will collect and send WebRTC statistics to Telnyx servers.
This is useful for troubleshooting call quality issues.

### `callInfo`

```swift
public var callInfo: TxCallInfo?
```

Contains essential information about the current call including:
- callId: Unique identifier for this call
- callerName: Display name of the caller
- callerNumber: Phone number or SIP URI of the caller
See `TxCallInfo` for complete details.

### `callState`

```swift
public var callState: CallState = .NEW
```

The current state of the call. Possible values:
- NEW: Call object created but not yet initiated
- CONNECTING: Outbound call is being established
- RINGING: Incoming call waiting to be answered
- ACTIVE: Call is connected and media is flowing
- HELD: Call is temporarily suspended
- DONE: Call has ended

The state changes are notified through the `CallProtocol` delegate.

### `isMuted`

```swift
public var isMuted: Bool
```

Indicates whether the local audio is currently muted.
- Returns: `true` if the call is muted (audio track disabled)
- Returns: `false` if the call is not muted (audio track enabled)

Use `muteAudio()` and `unmuteAudio()` to change the mute state.
