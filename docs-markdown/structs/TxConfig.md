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

### `forceRelayCandidate`

```swift
public internal(set) var forceRelayCandidate: Bool = false
```

Forces the WebRTC connection to use TURN relay candidates only.
- When enabled, all WebRTC traffic is routed through TURN servers, avoiding direct peer-to-peer connections.
- This setting is useful when:
  - You need to bypass local network access restrictions
  - You want to ensure consistent network behavior across different environments
  - Privacy or security requirements mandate avoiding direct connections
- Important: Enabling this flag may slightly increase latency but provides more predictable connectivity.

## Methods
### `init(sipUser:password:pushDeviceToken:ringtone:ringBackTone:pushEnvironment:logLevel:reconnectClient:debug:forceRelayCandidate:)`

```swift
public init(sipUser: String, password: String,
            pushDeviceToken: String? = nil,
            ringtone: String? = nil,
            ringBackTone: String? = nil,
            pushEnvironment: PushEnvironment? = nil,
            logLevel: LogLevel = .none,
            reconnectClient: Bool = true,
            debug: Bool = false,
            forceRelayCandidate: Bool = false
)
```

Constructor for the Telnyx SDK configuration using SIP credentials.
- Parameters:
  - sipUser: The SIP username for authentication
  - password: The password associated with the SIP user
  - pushDeviceToken: (Optional) The device's push notification token, required for receiving inbound call notifications
  - ringtone: (Optional) The audio file name to play for incoming calls (e.g., "my-ringtone.mp3")
  - ringBackTone: (Optional) The audio file name to play while making outbound calls (e.g., "my-ringbacktone.mp3")
  - pushEnvironment: (Optional) The environment for push notifications (development or production)
  - logLevel: (Optional) The verbosity level for SDK logs (defaults to `.none`)
  - reconnectClient: (Optional) Whether to automatically reconnect when connection is lost (defaults to `true`)
  - debug: (Optional) Enable WebRTC statistics reporting (defaults to `false`)
  - forceRelayCandidate: (Optional) Force WebRTC to use TURN relay candidates only (defaults to `false`)

#### Parameters

| Name | Description |
| ---- | ----------- |
| sipUser | The SIP username for authentication |
| password | The password associated with the SIP user |
| pushDeviceToken | (Optional) The device's push notification token, required for receiving inbound call notifications |
| ringtone | (Optional) The audio file name to play for incoming calls (e.g., "my-ringtone.mp3") |
| ringBackTone | (Optional) The audio file name to play while making outbound calls (e.g., "my-ringbacktone.mp3") |
| pushEnvironment | (Optional) The environment for push notifications (development or production) |
| logLevel | (Optional) The verbosity level for SDK logs (defaults to `.none`) |
| reconnectClient | (Optional) Whether to automatically reconnect when connection is lost (defaults to `true`) |
| debug | (Optional) Enable WebRTC statistics reporting (defaults to `false`) |
| forceRelayCandidate | (Optional) Force WebRTC to use TURN relay candidates only (defaults to `false`) |

### `init(token:pushDeviceToken:ringtone:ringBackTone:pushEnvironment:logLevel:debug:forceRelayCandidate:)`

```swift
public init(token: String,
            pushDeviceToken: String? = nil,
            ringtone: String? = nil,
            ringBackTone: String? = nil,
            pushEnvironment: PushEnvironment? = nil,
            logLevel: LogLevel = .none,
            debug: Bool = false,
            forceRelayCandidate: Bool = false)
```

Constructor for the Telnyx SDK configuration using JWT token authentication.
- Parameters:
  - token: JWT token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart
  - pushDeviceToken: (Optional) The device's push notification token, required for receiving inbound call notifications
  - ringtone: (Optional) The audio file name to play for incoming calls (e.g., "my-ringtone.mp3")
  - ringBackTone: (Optional) The audio file name to play while making outbound calls (e.g., "my-ringbacktone.mp3")
  - pushEnvironment: (Optional) The environment for push notifications (development or production)
  - logLevel: (Optional) The verbosity level for SDK logs (defaults to `.none`)
  - debug: (Optional) Enable WebRTC statistics reporting (defaults to `false`)
  - forceRelayCandidate: (Optional) Force WebRTC to use TURN relay candidates only (defaults to `false`)

#### Parameters

| Name | Description |
| ---- | ----------- |
| token | JWT token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart |
| pushDeviceToken | (Optional) The device's push notification token, required for receiving inbound call notifications |
| ringtone | (Optional) The audio file name to play for incoming calls (e.g., "my-ringtone.mp3") |
| ringBackTone | (Optional) The audio file name to play while making outbound calls (e.g., "my-ringbacktone.mp3") |
| pushEnvironment | (Optional) The environment for push notifications (development or production) |
| logLevel | (Optional) The verbosity level for SDK logs (defaults to `.none`) |
| debug | (Optional) Enable WebRTC statistics reporting (defaults to `false`) |
| forceRelayCandidate | (Optional) Force WebRTC to use TURN relay candidates only (defaults to `false`) |

### `validateParams()`

```swift
public func validateParams() throws
```

Validate if TxConfig parameters are valid
- Throws: Throws TxConfig parameters errors