**STRUCT**

# `TxServerConfiguration`

```swift
public struct TxServerConfiguration
```

This class contains all the properties related to: Signaling server URL and  STUN / TURN servers

## Properties
### `environment`

```swift
public internal(set) var environment: WebRTCEnvironment = .production
```

### `signalingServer`

```swift
public internal(set) var signalingServer: URL
```

### `pushMetaData`

```swift
public internal(set) var pushMetaData: [String:Any]?
```

### `webRTCIceServers`

```swift
public internal(set) var webRTCIceServers: [RTCIceServer]
```

## Methods
### `init(signalingServer:webRTCIceServers:environment:pushMetaData:)`

```swift
public init(signalingServer: URL? = nil, webRTCIceServers: [RTCIceServer]? = nil, environment: WebRTCEnvironment = .production,pushMetaData:[String: Any]? = nil)
```

Constructor for the Server configuration parameters.
- Parameters:
  - signalingServer: To define the signaling server URL `wss://address:port`
  - webRTCIceServers: To define custom ICE servers
  - pushMetaData: Contains push info when a PN is received

#### Parameters

| Name | Description |
| ---- | ----------- |
| signalingServer | To define the signaling server URL `wss://address:port` |
| webRTCIceServers | To define custom ICE servers |
| pushMetaData | Contains push info when a PN is received |