**ENUM**

# `TxError.SocketFailureReason`

```swift
public enum SocketFailureReason
```

The underlying reason of the Socket connection failure

## Cases
### `socketNotConnected`

```swift
case socketNotConnected
```

Socket is not connected. Check that you have an active connection.

### `socketCancelled(nativeError:)`

```swift
case socketCancelled(nativeError:Error)
```

Socket connection was cancelled.
