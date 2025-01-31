**PROTOCOL**

# `TxClientDelegate`

```swift
public protocol TxClientDelegate: AnyObject
```

The TxClientDelegate protocol defines methods for receiving events and updates from a TxClient instance.
Implement this protocol to handle various states and events in your WebRTC-enabled application,
including connection status, call state changes, and push notifications.

## Usage Example:
```swift
class CallHandler: TxClientDelegate {
    func onSocketConnected() {
        print("Connected to Telnyx backend")
    }

    func onIncomingCall(call: Call) {
        // Handle incoming call
        call.answer()
    }

    // Implement other required methods...
}
```

## Methods
### `onSocketConnected()`

```swift
func onSocketConnected()
```

Called when the WebSocket connection to Telnyx's backend is established.
This indicates a successful network connection, but the client may not be fully ready yet.
Wait for `onClientReady` before initiating calls.

### `onSocketDisconnected()`

```swift
func onSocketDisconnected()
```

Called when the WebSocket connection to Telnyx's backend is lost or closed.
The client will automatically attempt to reconnect unless explicitly disconnected.

### `onClientError(error:)`

```swift
func onClientError(error: Error)
```

Called when an error occurs in the TxClient.
- Parameter error: The error that occurred. Check the error type and message for details.
Common errors include authentication failures and network connectivity issues.

#### Parameters

| Name | Description |
| ---- | ----------- |
| error | The error that occurred. Check the error type and message for details. Common errors include authentication failures and network connectivity issues. |

### `onClientReady()`

```swift
func onClientReady()
```

Called when the client has successfully connected AND authenticated.
The client is now ready to make and receive calls.
This is the appropriate time to enable UI elements for calling functionality.

### `onPushDisabled(success:message:)`

```swift
func onPushDisabled(success: Bool, message: String)
```

Called when push notification status changes for the current user.
- Parameters:
  - success: Whether the push notification operation succeeded
  - message: Descriptive message about the operation result

#### Parameters

| Name | Description |
| ---- | ----------- |
| success | Whether the push notification operation succeeded |
| message | Descriptive message about the operation result |

### `onSessionUpdated(sessionId:)`

```swift
func onSessionUpdated(sessionId: String)
```

Called when the client's session is updated, typically after a reconnection.
- Parameter sessionId: The new session identifier for the connection.
Store this ID if you need to track or debug connection issues.

#### Parameters

| Name | Description |
| ---- | ----------- |
| sessionId | The new session identifier for the connection. Store this ID if you need to track or debug connection issues. |

### `onCallStateUpdated(callState:callId:)`

```swift
func onCallStateUpdated(callState: CallState, callId: UUID)
```

Called whenever a call's state changes (e.g., ringing, answered, ended).
- Parameters:
  - callState: The new state of the call (NEW, CONNECTING, RINGING, ACTIVE, HELD, DONE)
  - callId: The unique identifier of the affected call
Use this to update your UI to reflect the current call state.

#### Parameters

| Name | Description |
| ---- | ----------- |
| callState | The new state of the call (NEW, CONNECTING, RINGING, ACTIVE, HELD, DONE) |
| callId | The unique identifier of the affected call Use this to update your UI to reflect the current call state. |

### `onIncomingCall(call:)`

```swift
func onIncomingCall(call: Call)
```

Called when a new incoming call is received.
- Parameter call: The Call object representing the incoming call.
You can use this object to answer or reject the call.

#### Parameters

| Name | Description |
| ---- | ----------- |
| call | The Call object representing the incoming call. You can use this object to answer or reject the call. |

### `onRemoteCallEnded(callId:)`

```swift
func onRemoteCallEnded(callId: UUID)
```

Called when a remote party ends the call.
- Parameter callId: The unique identifier of the ended call.
Use this to clean up any call-related UI elements or state.

#### Parameters

| Name | Description |
| ---- | ----------- |
| callId | The unique identifier of the ended call. Use this to clean up any call-related UI elements or state. |

### `onPushCall(call:)`

```swift
func onPushCall(call: Call)
```

Called when a push notification triggers an incoming call.
- Parameter call: The Call object created from the push notification data.
This is specifically for handling calls that arrive via push notifications
when the app is in the background.

#### Parameters

| Name | Description |
| ---- | ----------- |
| call | The Call object created from the push notification data. This is specifically for handling calls that arrive via push notifications when the app is in the background. |