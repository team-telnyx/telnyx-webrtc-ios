**STRUCT**

# `CallReportInterval`

```swift
public struct CallReportInterval: Codable
```

Statistics collected during a single reporting interval

## Properties
### `intervalStartUtc`

```swift
public let intervalStartUtc: String
```

### `intervalEndUtc`

```swift
public let intervalEndUtc: String
```

### `audio`

```swift
public let audio: AudioStats?
```

### `connection`

```swift
public let connection: ConnectionStats?
```

### `ice`

```swift
public let ice: ICECandidatePairStats?
```

### `transport`

```swift
public let transport: TransportStats?
```

### `mediaPlayout`

```swift
public let mediaPlayout: MediaPlayoutStats?
```

### `remoteRtcp`

```swift
public let remoteRtcp: RemoteRTCPStats?
```

## Methods
### `init(intervalStartUtc:intervalEndUtc:audio:connection:ice:transport:mediaPlayout:remoteRtcp:)`

```swift
public init(intervalStartUtc: String, intervalEndUtc: String, audio: AudioStats? = nil, connection: ConnectionStats? = nil, ice: ICECandidatePairStats? = nil, transport: TransportStats? = nil, mediaPlayout: MediaPlayoutStats? = nil, remoteRtcp: RemoteRTCPStats? = nil)
```
