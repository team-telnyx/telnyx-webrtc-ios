**STRUCT**

# `CallQualityMetrics`

```swift
public struct CallQualityMetrics
```

Represents real-time call quality metrics derived from WebRTC statistics

## Properties
### `jitter`

```swift
public let jitter: Double
```

Jitter in seconds

### `rtt`

```swift
public let rtt: Double
```

Round-trip time in seconds

### `mos`

```swift
public let mos: Double
```

Mean Opinion Score (1.0-5.0)

### `quality`

```swift
public let quality: CallQuality
```

Call quality rating based on MOS

### `inboundAudio`

```swift
public let inboundAudio: [String: Any]?
```

Remote inbound audio statistics

### `outboundAudio`

```swift
public let outboundAudio: [String: Any]?
```

Remote outbound audio statistics

### `remoteInboundAudio`

```swift
public let remoteInboundAudio: [String: Any]?
```

Remote inbound audio statistics

### `remoteOutboundAudio`

```swift
public let remoteOutboundAudio: [String: Any]?
```

Remote outbound audio statistics

## Methods
### `toDictionary()`

```swift
public func toDictionary() -> [String: Any]
```

Creates a dictionary representation of the metrics
- Returns: Dictionary containing the metrics

### `init(jitter:rtt:mos:quality:inboundAudio:outboundAudio:remoteInboundAudio:remoteOutboundAudio:)`

```swift
public init(
    jitter: Double,
    rtt: Double,
    mos: Double,
    quality: CallQuality,
    inboundAudio: [String: Any]?,
    outboundAudio: [String: Any]?,
    remoteInboundAudio: [String: Any]?,
    remoteOutboundAudio: [String: Any]?
)
```
