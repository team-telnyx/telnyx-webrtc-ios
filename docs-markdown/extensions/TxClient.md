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

### `newCall(callerName:callerNumber:destinationNumber:callId:clientState:customHeaders:)`

```swift
public func newCall(callerName: String,
                    callerNumber: String,
                    destinationNumber: String,
                    callId: UUID,
                    clientState: String? = nil,
                    customHeaders:[String:String] = [:]) throws -> Call
```

Creates a new Call and starts the call sequence, negotiate the ICE Candidates and sends the invite.
- Parameters:
  - callerName: The caller name. This will be displayed as the caller name in the remote's client.
  - callerNumber: The caller Number. The phone number of the current user.
  - destinationNumber: The destination `SIP user address` (sip:YourSipUser@sip.telnyx.com) or `phone number`.
  - callId: The current call UUID.
  - clientState: (optional) Custom state in string format encoded in base64
  - customHeaders: (optional) Custom Headers to be passed over webRTC Messages, should be in the
    format `X-key:Value` `X` is required for headers to be passed.
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
| customHeaders | (optional) Custom Headers to be passed over webRTC Messages, should be in the format `X-key:Value` `X` is required for headers to be passed. |

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
