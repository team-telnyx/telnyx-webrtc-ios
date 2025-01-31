**STRUCT**

# `TxConfig`

```swift
public struct TxConfig
```

This structure is intended to used for Telnyx SDK configurations.

## Properties
### `sipUser`

```swift
public internal(set) var sipUser: String?
```

### `password`

```swift
public internal(set) var password: String?
```

### `token`

```swift
public internal(set) var token: String?
```

### `pushNotificationConfig`

```swift
public internal(set) var pushNotificationConfig: TxPushConfig?
```

### `ringBackTone`

```swift
public internal(set) var ringBackTone: String?
```

### `ringtone`

```swift
public internal(set) var ringtone: String?
```

### `reconnectClient`

```swift
public internal(set) var reconnectClient: Bool = true
```

### `pushEnvironment`

```swift
public internal(set) var pushEnvironment: PushEnvironment?
```

### `debug`

```swift
public internal(set) var debug: Bool = false
```

Enables WebRTC communication statistics reporting to Telnyx servers.
- Note: This flag is different from `logLevel`:
  - `debug`: When enabled, sends WebRTC communication statistics to Telnyx servers for monitoring and debugging purposes.
    See `WebRTCStatsReporter` class for details on the statistics collected.
  - `logLevel`: Controls console log output in Xcode when running the app in debug mode.
- Important: The `debug` flag is disabled by default to minimize data usage.

## Methods
### `init(sipUser:password:pushDeviceToken:ringtone:ringBackTone:pushEnvironment:logLevel:reconnectClient:debug:)`

```swift
public init(sipUser: String, password: String,
            pushDeviceToken: String? = nil,
            ringtone: String? = nil,
            ringBackTone: String? = nil,
            pushEnvironment: PushEnvironment? = nil,
            logLevel: LogLevel = .none,
            reconnectClient: Bool = true,
            debug: Bool = false
)
```

Constructor for the Telnyx SDK configuration using SIP credentials.
- Parameters:
  - sipUser: The SIP username for authentication
  - password: The password associated with the SIP user
  - pushDeviceToken: (Optional) The device's push notification token, required for receiving inbound call notifications
  - ringtone: (Optional) The audio file name to play for incoming calls (e.g., "my-ringtone.mp3")
  - ringBackTone: (Optional) The audio file name to play while making outbound calls (e.g., "my-ringbacktone.mp3")
  - logLevel: (Optional) The verbosity level for SDK logs (defaults to `.none`)

#### Parameters

| Name | Description |
| ---- | ----------- |
| sipUser | The SIP username for authentication |
| password | The password associated with the SIP user |
| pushDeviceToken | (Optional) The device’s push notification token, required for receiving inbound call notifications |
| ringtone | (Optional) The audio file name to play for incoming calls (e.g., “my-ringtone.mp3”) |
| ringBackTone | (Optional) The audio file name to play while making outbound calls (e.g., “my-ringbacktone.mp3”) |
| logLevel | (Optional) The verbosity level for SDK logs (defaults to `.none`) |

### `init(token:pushDeviceToken:ringtone:ringBackTone:pushEnvironment:logLevel:debug:)`

```swift
public init(token: String,
            pushDeviceToken: String? = nil,
            ringtone: String? = nil,
            ringBackTone: String? = nil,
            pushEnvironment: PushEnvironment? = nil,
            logLevel: LogLevel = .none,
            debug: Bool = false)
```

Constructor for the Telnyx SDK configuration using JWT token authentication.
- Parameters:
  - token: JWT token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart
  - pushDeviceToken: (Optional) The device's push notification token, required for receiving inbound call notifications
  - ringtone: (Optional) The audio file name to play for incoming calls (e.g., "my-ringtone.mp3")
  - ringBackTone: (Optional) The audio file name to play while making outbound calls (e.g., "my-ringbacktone.mp3")
  - logLevel: (Optional) The verbosity level for SDK logs (defaults to `.none`)
  - serverConfiguration: (Optional) Custom configuration for signaling server and TURN/STUN servers (defaults to Telnyx Production servers)

#### Parameters

| Name | Description |
| ---- | ----------- |
| token | JWT token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart |
| pushDeviceToken | (Optional) The device’s push notification token, required for receiving inbound call notifications |
| ringtone | (Optional) The audio file name to play for incoming calls (e.g., “my-ringtone.mp3”) |
| ringBackTone | (Optional) The audio file name to play while making outbound calls (e.g., “my-ringbacktone.mp3”) |
| logLevel | (Optional) The verbosity level for SDK logs (defaults to `.none`) |
| serverConfiguration | (Optional) Custom configuration for signaling server and TURN/STUN servers (defaults to Telnyx Production servers) |

### `validateParams()`

```swift
public func validateParams() throws
```

Validate if TxConfig parameters are valid
- Throws: Throws TxConfig parameters errors
