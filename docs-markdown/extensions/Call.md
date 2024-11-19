**EXTENSION**

# `Call`
```swift
extension Call
```

## Methods
### `hangup()`

```swift
public func hangup()
```

Hangup or reject an incoming call.
### Example:
    call.hangup()

### `answer(customHeaders:)`

```swift
public func answer(customHeaders:[String:String] = [:])
```

Starts the process to answer the incoming call.
### Example:
    call.answer()
 - Parameters:
        - customHeaders: (optional) Custom Headers to be passed over webRTC Messages, should be in the
    format `X-key:Value` `X` is required for headers to be passed.

### `dtmf(dtmf:)`

```swift
public func dtmf(dtmf: String)
```

Sends dual-tone multi-frequency (DTMF) signal
- Parameter dtmf: Single DTMF key
## Examples:
### Send DTMF signals:

```
   currentCall?.dtmf("0")
   currentCall?.dtmf("1")
   currentCall?.dtmf("*")
   currentCall?.dtmf("#")
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| dtmf | Single DTMF key |

### `muteAudio()`

```swift
public func muteAudio()
```

Turns off audio output, i.e. makes it so other call participants cannot hear your audio.
### Example:
    call.muteAudio()

### `unmuteAudio()`

```swift
public func unmuteAudio()
```

Turns on audio output, i.e. makes it so other call participants can hear your audio.
### Example:
    call.unmuteAudio()

### `hold()`

```swift
public func hold()
```

Holds the call.
### Example:
    call.hold()

### `unhold()`

```swift
public func unhold()
```

Removes hold from the call.
### Example:
    call.unhold()

### `toggleHold()`

```swift
public func toggleHold()
```

Toggles between `active` and `held`  state of the call.
### Example:
    call.toggleHold()
