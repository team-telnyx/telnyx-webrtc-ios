**EXTENSION**

# `Call`
```swift
extension Call
```

## Methods
### `iceRestart(completion:)`

```swift
public func iceRestart(completion: @escaping (_ success: Bool, _ error: Error?) -> Void)
```

Performs ICE restart to renegotiate ICE candidates when network conditions change
This helps resolve audio delay issues by establishing new network paths
- Parameter completion: Callback indicating success or failure of the ICE restart

#### Parameters

| Name | Description |
| ---- | ----------- |
| completion | Callback indicating success or failure of the ICE restart |

### `hangup()`

```swift
public func hangup()
```

Hangup or reject an incoming call.
### Example:
    call.hangup()

### `answer(customHeaders:debug:)`

```swift
public func answer(customHeaders:[String:String] = [:], debug:Bool = false)
```

Starts the process to answer the incoming call.

Use this method to accept an incoming call and establish the WebRTC connection.

### Examples:
```swift
// Basic answer
call.answer()

// Answer with custom headers
call.answer(customHeaders: ["X-Custom-Header": "Value"])

// Answer with debug mode
call.answer(debug: true)
```

- Parameters:
  - customHeaders: (optional) Custom Headers to be passed over webRTC Messages.
    Headers should be in the format `X-key:Value` where `X-` prefix is required for custom headers.
    When calling AI Agents, headers with the `X-` prefix will be mapped to dynamic variables
    (e.g., `X-Account-Number` becomes `{{account_number}}`). Hyphens in header names are
    converted to underscores in variable names.
  - debug: (optional) Enable debug mode for call quality metrics and WebRTC statistics.
    When enabled, real-time call quality metrics will be available through the `onCallQualityChange` callback.

#### Parameters

| Name | Description |
| ---- | ----------- |
| customHeaders | (optional) Custom Headers to be passed over webRTC Messages. Headers should be in the format `X-key:Value` where `X-` prefix is required for custom headers. When calling AI Agents, headers with the `X-` prefix will be mapped to dynamic variables (e.g., `X-Account-Number` becomes `{{account_number}}`). Hyphens in header names are converted to underscores in variable names. |
| debug | (optional) Enable debug mode for call quality metrics and WebRTC statistics. When enabled, real-time call quality metrics will be available through the `onCallQualityChange` callback. |

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

### `resetAudioDevice()`

```swift
public func resetAudioDevice()
```

Resets the audio device and clears accumulated buffers to resolve persistent audio delay issues.

This method addresses iOS audio delay problems where:
- AudioDeviceModule buffers stretch under poor network conditions
- WebRTC audio pacing causes frame accumulation
- iOS AudioUnit/AVAudioSession remains in large buffer state

### Example:
    call.resetAudioDevice()

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
