**ENUM**

# `CallState`

```swift
public enum CallState: Equatable
```

`CallState` represents the state of the call

## Cases
### `NEW`

```swift
case NEW
```

New call has been created in the client.

### `CONNECTING`

```swift
case CONNECTING
```

The outbound call is being sent to the server.

### `RINGING`

```swift
case RINGING
```

Call is pending to be answered. Someone is attempting to call you.

### `ACTIVE`

```swift
case ACTIVE
```

Call is active when two clients are fully connected.

### `HELD`

```swift
case HELD
```

Call has been held.

### `DONE(reason:)`

```swift
case DONE(reason: CallTerminationReason? = nil)
```

Call has ended.

### `RECONNECTING(reason:)`

```swift
case RECONNECTING(reason: Reason)
```

The active call is being recovered. Usually after a network switch or bad network

### `DROPPED(reason:)`

```swift
case DROPPED(reason: Reason)
```

The active call is dropped. Usually when the network is lost.

## Methods
### `getReason()`

```swift
public func getReason() -> String?
```

Helper function to get the reason for the state (if applicable).

### `==(_:_:)`

```swift
public static func == (lhs: CallState, rhs: CallState) -> Bool
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| lhs | A value to compare. |
| rhs | Another value to compare. |