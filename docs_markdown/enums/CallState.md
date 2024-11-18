**ENUM**

# `CallState`

```swift
public enum CallState
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

### `DONE`

```swift
case DONE
```

Call has ended.
