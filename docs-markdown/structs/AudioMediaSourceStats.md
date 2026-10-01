**STRUCT**

# `AudioMediaSourceStats`

```swift
public struct AudioMediaSourceStats: Codable
```

Local audio-source telemetry linked from outbound RTP statistics.

## Properties
### `id`

```swift
public let id: String?
```

### `audioLevel`

```swift
public let audioLevel: Double?
```

### `totalAudioEnergy`

```swift
public let totalAudioEnergy: Double?
```

### `totalSamplesDuration`

```swift
public let totalSamplesDuration: Double?
```

### `echoReturnLoss`

```swift
public let echoReturnLoss: Double?
```

### `echoReturnLossEnhancement`

```swift
public let echoReturnLossEnhancement: Double?
```

### `trackIdentifier`

```swift
public let trackIdentifier: String?
```

## Methods
### `init(id:audioLevel:totalAudioEnergy:totalSamplesDuration:echoReturnLoss:echoReturnLossEnhancement:trackIdentifier:)`

```swift
public init(id: String? = nil, audioLevel: Double? = nil, totalAudioEnergy: Double? = nil, totalSamplesDuration: Double? = nil, echoReturnLoss: Double? = nil, echoReturnLossEnhancement: Double? = nil, trackIdentifier: String? = nil)
```
