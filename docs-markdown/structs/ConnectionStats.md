**STRUCT**

# `ConnectionStats`

```swift
public struct ConnectionStats: Codable
```

Connection statistics for a reporting interval

## Properties
### `roundTripTimeAvg`

```swift
public let roundTripTimeAvg: Double?
```

### `packetsSent`

```swift
public let packetsSent: Int?
```

### `packetsReceived`

```swift
public let packetsReceived: Int?
```

### `bytesSent`

```swift
public let bytesSent: Int?
```

### `bytesReceived`

```swift
public let bytesReceived: Int?
```

### `currentRoundTripTime`

```swift
public let currentRoundTripTime: Double?
```

### `roundTripTimeSource`

```swift
public let roundTripTimeSource: String?
```

## Methods
### `init(roundTripTimeAvg:packetsSent:packetsReceived:bytesSent:bytesReceived:currentRoundTripTime:roundTripTimeSource:)`

```swift
public init(
    roundTripTimeAvg: Double? = nil,
    packetsSent: Int? = nil,
    packetsReceived: Int? = nil,
    bytesSent: Int? = nil,
    bytesReceived: Int? = nil,
    currentRoundTripTime: Double? = nil,
    roundTripTimeSource: String? = nil
)
```
