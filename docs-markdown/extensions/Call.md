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

### `answer(customHeaders:debug:)`

```swift
public func answer(customHeaders:[String:String] = [:],debug:Bool = false)
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

Sends a DTMF (Dual-Tone Multi-Frequency) signal during an active call.
DTMF signals are used to send digits and symbols over a phone line, typically
for interacting with automated systems, voicemail, or IVR menus.

- Parameter dtmf: A string containing a single DTMF character. Valid characters are:
  - Digits: 0-9
  - Special characters: * (asterisk), # (pound)
  - Letters: A-D (less commonly used)

## Examples:
```swift
// Navigate an IVR menu
currentCall?.dtmf("1")    // Select option 1
currentCall?.dtmf("0")    // Select option 0

// Special characters
currentCall?.dtmf("*")    // Send asterisk
currentCall?.dtmf("#")    // Send pound/hash
```

Note: The call must be in ACTIVE state for DTMF signals to be sent successfully.
Each DTMF tone should be sent individually with appropriate timing between tones
when sending multiple digits.

#### Parameters

| Name | Description |
| ---- | ----------- |
| dtmf | A string containing a single DTMF character. Valid characters are: |

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
