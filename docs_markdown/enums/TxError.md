**ENUM**

# `TxError`

```swift
public enum TxError : Error
```

`TxError` is the error type returned by Telnyx WebRTC SDK. It encompasses a few different types of errors, each with
their own associated reasons.

## Cases
### `socketConnectionFailed(reason:)`

```swift
case socketConnectionFailed(reason: SocketFailureReason)
```

Socket connection failures.

### `clientConfigurationFailed(reason:)`

```swift
case clientConfigurationFailed(reason: ClientConfigurationFailureReason)
```

There's an invalid parameter when setting up the SDK

### `callFailed(reason:)`

```swift
case callFailed(reason: CallFailureReason)
```

There's an invalid parameter when starting a call

### `serverError(reason:)`

```swift
case serverError(reason: ServerErrorReason)
```

When the signaling server sends an error
