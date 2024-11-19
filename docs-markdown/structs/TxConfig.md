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

## Methods
### `init(sipUser:password:pushDeviceToken:ringtone:ringBackTone:pushEnvironment:logLevel:reconnectClient:)`

```swift
public init(sipUser: String, password: String,
            pushDeviceToken: String? = nil,
            ringtone: String? = nil,
            ringBackTone: String? = nil,
            pushEnvironment: PushEnvironment? = nil,
            logLevel: LogLevel = .none,
            reconnectClient:Bool = true
)
```

Constructor of the Telnyx SDK configuration: Login using sip user  and password.
- Parameters:
  - sipUser: sipUser the SIP user
  - password: password the password of the SIP user.
  - pushDeviceToken: (Optional) the device push notification token. This is required to receive Inbound calls notifications.
  - ringtone: (Optional) The audio file name to be played when receiving an incoming call. e.g.: "my-ringtone.mp3"
  - ringBackTone: (Optional) The audio file to be played when calling. e.g.: "my-ringbacktone.mp3"
  - logLevel: (Optional) Can select the verbosity level of the SDK logs. Is set to `.none` as default

#### Parameters

| Name | Description |
| ---- | ----------- |
| sipUser | sipUser the SIP user |
| password | password the password of the SIP user. |
| pushDeviceToken | (Optional) the device push notification token. This is required to receive Inbound calls notifications. |
| ringtone | (Optional) The audio file name to be played when receiving an incoming call. e.g.: “my-ringtone.mp3” |
| ringBackTone | (Optional) The audio file to be played when calling. e.g.: “my-ringbacktone.mp3” |
| logLevel | (Optional) Can select the verbosity level of the SDK logs. Is set to `.none` as default |

### `init(token:pushDeviceToken:ringtone:ringBackTone:pushEnvironment:logLevel:)`

```swift
public init(token: String,
            pushDeviceToken: String? = nil,
            ringtone: String? = nil,
            ringBackTone: String? = nil,
            pushEnvironment: PushEnvironment? = nil,
            logLevel: LogLevel = .none)
```

Constructor of the Telnyx SDK configuration: Login using a token.
- Parameters:
  - token: Token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart
  - pushDeviceToken: (Optional) the device push notification token. This is required to receive Inbound calls notifications.
  - ringtone: (Optional) The audio file name to be played when receiving an incoming call. e.g.: "my-ringtone.mp3"
  - ringBackTone: (Optional) The audio file name to be played when calling. e.g.: "my-ringbacktone.mp3"
  - logLevel: (Optional) Can select the verbosity level of the SDK logs. Is set to `.none` as default
  - serverConfiguration: (Optional) To define a custom `signaling server` and `TURN/ STUN servers`. As default we use the internal Telnyx Production servers.

#### Parameters

| Name | Description |
| ---- | ----------- |
| token | Token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart |
| pushDeviceToken | (Optional) the device push notification token. This is required to receive Inbound calls notifications. |
| ringtone | (Optional) The audio file name to be played when receiving an incoming call. e.g.: “my-ringtone.mp3” |
| ringBackTone | (Optional) The audio file name to be played when calling. e.g.: “my-ringbacktone.mp3” |
| logLevel | (Optional) Can select the verbosity level of the SDK logs. Is set to `.none` as default |
| serverConfiguration | (Optional) To define a custom `signaling server` and `TURN/ STUN servers`. As default we use the internal Telnyx Production servers. |

### `validateParams()`

```swift
public func validateParams() throws
```

Validate if TxConfig parameters are valid
- Throws: Throws TxConfig parameters errors
