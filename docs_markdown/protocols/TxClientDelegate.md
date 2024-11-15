**PROTOCOL**

# `TxClientDelegate`

```swift
public protocol TxClientDelegate: AnyObject
```

Delegate protocol asociated with the TxClient
Methods for receiving TxClient events.

## Methods
### `onSocketConnected()`

```swift
func onSocketConnected()
```

Tells the delegate when the Telnyx Client has successfully connected to the Telnyx Backend

### `onSocketDisconnected()`

```swift
func onSocketDisconnected()
```

Tells the delegate when the Telnyx Client has disconnected from the Telnyx Backend

### `onClientError(error:)`

```swift
func onClientError(error: Error)
```

Tells the delegate when there's an error in the Telnyx Client
- Parameter error: error occurred inside the Telnyx Client

#### Parameters

| Name | Description |
| ---- | ----------- |
| error | error occurred inside the Telnyx Client |

### `onClientReady()`

```swift
func onClientReady()
```

Tells the delegate that the The Telnyx Client is ready to be used.
Has successfully connected and logged in

### `onPushDisabled(success:message:)`

```swift
func onPushDisabled(success:Bool,message:String)
```

Push notification is disabled for the current user

### `onSessionUpdated(sessionId:)`

```swift
func onSessionUpdated(sessionId: String)
```

Tells the delegate that the Telnyx Client session has been updated.
- Parameter sessionId: The new sessionId assigned to the client connection.

#### Parameters

| Name | Description |
| ---- | ----------- |
| sessionId | The new sessionId assigned to the client connection. |

### `onCallStateUpdated(callState:callId:)`

```swift
func onCallStateUpdated(callState: CallState, callId: UUID)
```

Tells the delegate that a call has been updated.
- Parameters:
  - callState: The new call state
  - callId: The UUID of the affected call

#### Parameters

| Name | Description |
| ---- | ----------- |
| callState | The new call state |
| callId | The UUID of the affected call |

### `onIncomingCall(call:)`

```swift
func onIncomingCall(call: Call)
```

Tells the delegate that someone is calling
- Parameter call: The call object of the incoming call.

#### Parameters

| Name | Description |
| ---- | ----------- |
| call | The call object of the incoming call. |

### `onRemoteCallEnded(callId:)`

```swift
func onRemoteCallEnded(callId: UUID)
```

Tells the delegate that a call has ended
- Parameter callId: the UUID of the call that has ended.

#### Parameters

| Name | Description |
| ---- | ----------- |
| callId | the UUID of the call that has ended. |

### `onPushCall(call:)`

```swift
func onPushCall(call: Call)
```

Tells the delegate that an INVITE has been received for the incoming push
- Parameter call: The call object of the incoming call.

#### Parameters

| Name | Description |
| ---- | ----------- |
| call | The call object of the incoming call. |