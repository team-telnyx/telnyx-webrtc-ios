**STRUCT**

# `TxConfig`

```swift
public struct TxConfig
```

This structure is intended to used for Telnyx SDK configurations.

## Properties
### `DEFAULT_TIMEOUT`

```swift
public static let DEFAULT_TIMEOUT = 60.0
```

Default timeout value for reconnection attempts in seconds.
After this period, if a call hasn't successfully reconnected, it will be terminated.

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

Controls whether the SDK should force TURN relay for peer connections.
When enabled, the SDK will only use TURN relay candidates for ICE gathering,
which prevents the "local network access" permission popup from appearing.
- Note: Enabling this may affect the quality of calls when devices are on the same local network,
        as all media will be relayed through TURN servers.
- Important: This setting is disabled by default to maintain optimal call quality.

### `reconnectTimeout`

```swift
public internal(set) var reconnectTimeout: Double = DEFAULT_TIMEOUT
```

Maximum time (in seconds) the SDK will attempt to reconnect a call after network disruption.
- If a call is successfully reconnected within this time, the call continues normally.
- If reconnection fails after this timeout period, the call will be terminated and a `reconnectFailed` error will be triggered.
- Default value is 60 seconds (defined by `DEFAULT_TIMEOUT`).
- This timeout helps prevent calls from being stuck in a "reconnecting" state indefinitely.

### `customLogger`

```swift
public internal(set) var customLogger: TxLogger?
```

Custom logger implementation for handling SDK logs
If not provided, the default logger will be used

## Methods
### `init(sipUser:password:pushDeviceToken:ringtone:ringBackTone:pushEnvironment:logLevel:customLogger:reconnectClient:debug:forceRelayCandidate:reconnectTimeOut:)`

```swift
public init(sipUser: String, password: String,
            pushDeviceToken: String? = nil,
            ringtone: String? = nil,
            ringBackTone: String? = nil,
            pushEnvironment: PushEnvironment? = nil,
            logLevel: LogLevel = .none,
            customLogger: TxLogger? = nil,
            reconnectClient: Bool = true,
            debug: Bool = false,
            forceRelayCandidate: Bool = false,
            reconnectTimeOut: Double = DEFAULT_TIMEOUT
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
  - customLogger: (Optional) Custom logger implementation for handling SDK logs. If not provided, the default logger will be used
  - reconnectTimeOut: (Optional) Maximum time in seconds the SDK will attempt to reconnect a call after network disruption. Default is 60 seconds.

#### Parameters

| Name | Description |
| ---- | ----------- |
| sipUser | The SIP username for authentication |
| password | The password associated with the SIP user |
| pushDeviceToken | (Optional) The device’s push notification token, required for receiving inbound call notifications |
| ringtone | (Optional) The audio file name to play for incoming calls (e.g., “my-ringtone.mp3”) |
| ringBackTone | (Optional) The audio file name to play while making outbound calls (e.g., “my-ringbacktone.mp3”) |
| logLevel | (Optional) The verbosity level for SDK logs (defaults to `.none`) |
| customLogger | (Optional) Custom logger implementation for handling SDK logs. If not provided, the default logger will be used |
| reconnectTimeOut | (Optional) Maximum time in seconds the SDK will attempt to reconnect a call after network disruption. Default is 60 seconds. |

### `init(token:pushDeviceToken:ringtone:ringBackTone:pushEnvironment:logLevel:customLogger:reconnectClient:debug:forceRelayCandidate:reconnectTimeOut:)`

```swift
public init(token: String,
            pushDeviceToken: String? = nil,
            ringtone: String? = nil,
            ringBackTone: String? = nil,
            pushEnvironment: PushEnvironment? = nil,
            logLevel: LogLevel = .none,
            customLogger: TxLogger? = nil,
            reconnectClient: Bool = true,
            debug: Bool = false,
            forceRelayCandidate: Bool = false,
            reconnectTimeOut: Double = DEFAULT_TIMEOUT
)
```

Constructor for the Telnyx SDK configuration using JWT token authentication.
- Parameters:
  - token: JWT token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart
  - pushDeviceToken: (Optional) The device's push notification token, required for receiving inbound call notifications
  - ringtone: (Optional) The audio file name to play for incoming calls (e.g., "my-ringtone.mp3")
  - ringBackTone: (Optional) The audio file name to play while making outbound calls (e.g., "my-ringbacktone.mp3")
  - logLevel: (Optional) The verbosity level for SDK logs (defaults to `.none`)
  - customLogger: (Optional) Custom logger implementation for handling SDK logs. If not provided, the default logger will be used
  - serverConfiguration: (Optional) Custom configuration for signaling server and TURN/STUN servers (defaults to Telnyx Production servers)
  - reconnectTimeOut: (Optional) Maximum time in seconds the SDK will attempt to reconnect a call after network disruption. Default is 60 seconds.

#### Parameters

| Name | Description |
| ---- | ----------- |
| token | JWT token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart |
| pushDeviceToken | (Optional) The device’s push notification token, required for receiving inbound call notifications |
| ringtone | (Optional) The audio file name to play for incoming calls (e.g., “my-ringtone.mp3”) |
| ringBackTone | (Optional) The audio file name to play while making outbound calls (e.g., “my-ringbacktone.mp3”) |
| logLevel | (Optional) The verbosity level for SDK logs (defaults to `.none`) |
| customLogger | (Optional) Custom logger implementation for handling SDK logs. If not provided, the default logger will be used |
| serverConfiguration | (Optional) Custom configuration for signaling server and TURN/STUN servers (defaults to Telnyx Production servers) |
| reconnectTimeOut | (Optional) Maximum time in seconds the SDK will attempt to reconnect a call after network disruption. Default is 60 seconds. |

### `validateParams()`

```swift
public func validateParams() throws
```

Validate if TxConfig parameters are valid
- Throws: Throws TxConfig parameters errors
