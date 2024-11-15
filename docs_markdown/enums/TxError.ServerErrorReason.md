**ENUM**

# `TxError.ServerErrorReason`

```swift
public enum ServerErrorReason
```

The underlying reason of the server errors

## Cases
### `signalingServerError(message:code:)`

```swift
case signalingServerError(message: String, code: String)
```

Any server signaling error. We get the message and code from the server

### `gatewayNotRegistered`

```swift
case gatewayNotRegistered
```

Gateway is not registered.
