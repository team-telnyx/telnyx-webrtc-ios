**EXTENSION**

# `TxClient`
```swift
extension TxClient
```

## Methods
### `getCall(callId:)`

```swift
public func getCall(callId: UUID) -> Call?
```

This function can be used to access any active call tracked by the SDK.
 A call will be accessible until has ended (transitioned to the DONE state).
- Parameter callId: The unique identifier of a call.
- Returns: The` Call` object that matches the  requested `callId`. Returns `nil` if no call was found.

#### Parameters

| Name | Description |
| ---- | ----------- |
| callId | The unique identifier of a call. |

### `newCall(callerName:callerNumber:destinationNumber:callId:clientState:customHeaders:preferredCodecs:debug:)`

```swift
public func newCall(callerName: String,
                    callerNumber: String,
                    destinationNumber: String,
                    callId: UUID,
                    clientState: String? = nil,
                    customHeaders:[String:String] = [:],
                    preferredCodecs: [TxCodecCapability]? = nil,
                    debug:Bool = false) throws -> Call
```

Creates a new Call and starts the call sequence, negotiate the ICE Candidates and sends the invite.

This method initiates an outbound call to the specified destination. The call will go through
WebRTC negotiation, ICE candidate gathering, and SIP signaling to establish the connection.

### Examples:
```swift
// Basic call
let call = try telnyxClient.newCall(
    callerName: "John Doe",
    callerNumber: "1234567890",
    destinationNumber: "18004377950",
    callId: UUID()
)

// Call with preferred audio codecs
let preferredCodecs = [
    TxCodecCapability(mimeType: "audio/opus", clockRate: 48000, channels: 2),
    TxCodecCapability(mimeType: "audio/PCMU", clockRate: 8000, channels: 1)
]
let call = try telnyxClient.newCall(
    callerName: "John Doe",
    callerNumber: "1234567890",
    destinationNumber: "18004377950",
    callId: UUID(),
    preferredCodecs: preferredCodecs
)

// Call with codecs and debug mode enabled
let call = try telnyxClient.newCall(
    callerName: "John Doe",
    callerNumber: "1234567890",
    destinationNumber: "18004377950",
    callId: UUID(),
    customHeaders: ["X-Custom-Header": "Value"],
    preferredCodecs: preferredCodecs,
    debug: true
)
```

- Parameters:
  - callerName: The caller name. This will be displayed as the caller name in the remote's client.
  - callerNumber: The caller Number. The phone number of the current user.
  - destinationNumber: The destination `SIP user address` (sip:YourSipUser@sip.telnyx.com) or `phone number`.
  - callId: The current call UUID.
  - clientState: (optional) Custom state in string format encoded in base64
  - customHeaders: (optional) Custom Headers to be passed over webRTC Messages.
    Headers should be in the format `X-key:Value` where `X-` prefix is required for custom headers.
    When calling AI Agents, headers with the `X-` prefix will be mapped to dynamic variables
    (e.g., `X-Account-Number` becomes `{{account_number}}`). Hyphens in header names are
    converted to underscores in variable names.
  - preferredCodecs: (optional) Array of preferred audio codecs in priority order.
    The SDK will attempt to use these codecs in the specified order during negotiation.
    If none of the preferred codecs are available, WebRTC will fall back to its default codec selection.
    Use `getSupportedAudioCodecs()` to retrieve available codecs before setting preferences.
    See the [Preferred Audio Codecs Guide](https://github.com/team-telnyx/telnyx-webrtc-ios#preferred-audio-codecs) for more information.
  - debug: (optional) Enable debug mode for call quality metrics and WebRTC statistics.
    When enabled, real-time call quality metrics will be available through the call's `onCallQualityChange` callback.
- Throws:
  - sessionId is required if user is not logged in
  - socket connection error if socket is not connected
  - destination number is required to start a call.
- Returns: The call that has been created

#### Parameters

| Name | Description |
| ---- | ----------- |
| callerName | The caller name. This will be displayed as the caller name in the remote’s client. |
| callerNumber | The caller Number. The phone number of the current user. |
| destinationNumber | The destination `SIP user address` (sip:YourSipUser@sip.telnyx.com) or `phone number`. |
| callId | The current call UUID. |
| clientState | (optional) Custom state in string format encoded in base64 |
| customHeaders | (optional) Custom Headers to be passed over webRTC Messages. Headers should be in the format `X-key:Value` where `X-` prefix is required for custom headers. When calling AI Agents, headers with the `X-` prefix will be mapped to dynamic variables (e.g., `X-Account-Number` becomes `{{account_number}}`). Hyphens in header names are converted to underscores in variable names. |
| preferredCodecs | (optional) Array of preferred audio codecs in priority order. The SDK will attempt to use these codecs in the specified order during negotiation. If none of the preferred codecs are available, WebRTC will fall back to its default codec selection. Use `getSupportedAudioCodecs()` to retrieve available codecs before setting preferences. See the  for more information. |
| debug | (optional) Enable debug mode for call quality metrics and WebRTC statistics. When enabled, real-time call quality metrics will be available through the call’s `onCallQualityChange` callback. |

### `getSupportedAudioCodecs()`

```swift
public func getSupportedAudioCodecs() -> [TxCodecCapability]
```

Returns the list of supported audio codecs available for use in calls
- Returns: Array of TxCodecCapability objects representing available audio codecs

This method reuses the shared RTCPeerConnectionFactory instance for efficiency.
The codec list is queried from WebRTC's native capabilities and remains consistent
throughout the application lifecycle.

### Example:
```swift
let supportedCodecs = telnyxClient.getSupportedAudioCodecs()
for codec in supportedCodecs {
    print("Codec: \(codec.mimeType), Clock Rate: \(codec.clockRate)")
}
```

### `processVoIPNotification(txConfig:serverConfiguration:pushMetaData:)`

```swift
public func processVoIPNotification(txConfig: TxConfig,
                                    serverConfiguration: TxServerConfiguration,pushMetaData:[String: Any]) throws
```

Call this function to process a VoIP push notification of an incoming call.
This function will be executed when the app was closed and the user executes an action over the VoIP push notification.
 You will need to
- Parameters:
  - txConfig: The desired configuration to login to B2B2UA. User credentials must be the same as the
  - serverConfiguration : required to setup from  VoIP push notification metadata.
  - pushMetaData : meta data payload from VOIP Push notification
                   (this should be gotten from payload.dictionaryPayload["metadata"] as? [String: Any])
- Throws: Error during the connection process

#### Parameters

| Name | Description |
| ---- | ----------- |
| txConfig | The desired configuration to login to B2B2UA. User credentials must be the same as the |
| serverConfiguration | required to setup from  VoIP push notification metadata. |
| pushMetaData | meta data payload from VOIP Push notification (this should be gotten from payload.dictionaryPayload[“metadata”] as? [String: Any]) |

### `setEarpiece()`

```swift
public func setEarpiece()
```

Select the internal earpiece as the audio output

### `setSpeaker()`

```swift
public func setSpeaker()
```

Select the speaker as the audio output
