**ENUM**

# `TxError.CallFailureReason`

```swift
public enum CallFailureReason
```

The underlying reason of the call errors

## Cases
### `destinationNumberIsRequired`

```swift
case destinationNumberIsRequired
```

There's no destination number when placing an outbound call

### `sessionIdIsRequired`

```swift
case sessionIdIsRequired
```

Session Id is missing when starting a call. Check you're logged in before starting a call.

### `reconnectFailed`

```swift
case reconnectFailed
```

Call reconnection failed after the configured timeout period.
This error occurs when a call cannot be reconnected after network disruption within the time specified by `TxConfig.reconnectTimeout`.

### `callNotFound`

```swift
case callNotFound
```

Call not found when trying to perform an operation

### `noMetricsCollected`

```swift
case noMetricsCollected
```

No metrics were collected during pre-call diagnosis
