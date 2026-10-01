**STRUCT**

# `OutboundAudioStats`

```swift
public struct OutboundAudioStats: Codable
```

Statistics for outbound audio stream

## Properties
### `packetsSent`

```swift
public let packetsSent: Int?
```

### `bytesSent`

```swift
public let bytesSent: Int?
```

### `audioLevelAvg`

```swift
public let audioLevelAvg: Double?
```

### `bitrateAvg`

```swift
public let bitrateAvg: Double?
```

### `retransmittedPacketsSent`

```swift
public let retransmittedPacketsSent: Int?
```

### `retransmittedBytesSent`

```swift
public let retransmittedBytesSent: Int?
```

### `headerBytesSent`

```swift
public let headerBytesSent: Int?
```

### `nackCount`

```swift
public let nackCount: Int?
```

### `targetBitrate`

```swift
public let targetBitrate: Double?
```

### `totalPacketSendDelay`

```swift
public let totalPacketSendDelay: Double?
```

### `active`

```swift
public let active: Bool?
```

### `codec`

```swift
public let codec: AudioCodecStats?
```

### `mediaSource`

```swift
public let mediaSource: AudioMediaSourceStats?
```

## Methods
### `init(packetsSent:bytesSent:audioLevelAvg:bitrateAvg:retransmittedPacketsSent:retransmittedBytesSent:headerBytesSent:nackCount:targetBitrate:totalPacketSendDelay:active:codec:mediaSource:)`

```swift
public init(packetsSent: Int? = nil, bytesSent: Int? = nil, audioLevelAvg: Double? = nil, bitrateAvg: Double? = nil, retransmittedPacketsSent: Int? = nil, retransmittedBytesSent: Int? = nil, headerBytesSent: Int? = nil, nackCount: Int? = nil, targetBitrate: Double? = nil, totalPacketSendDelay: Double? = nil, active: Bool? = nil, codec: AudioCodecStats? = nil, mediaSource: AudioMediaSourceStats? = nil)
```
