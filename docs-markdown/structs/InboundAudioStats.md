**STRUCT**

# `InboundAudioStats`

```swift
public struct InboundAudioStats: Codable
```

Statistics for inbound audio stream

## Properties
### `packetsReceived`

```swift
public let packetsReceived: Int?
```

### `bytesReceived`

```swift
public let bytesReceived: Int?
```

### `packetsLost`

```swift
public let packetsLost: Int?
```

### `packetsDiscarded`

```swift
public let packetsDiscarded: Int?
```

### `jitterBufferDelay`

```swift
public let jitterBufferDelay: Double?
```

### `jitterBufferEmittedCount`

```swift
public let jitterBufferEmittedCount: Int?
```

### `totalSamplesReceived`

```swift
public let totalSamplesReceived: Int?
```

### `concealedSamples`

```swift
public let concealedSamples: Int?
```

### `concealmentEvents`

```swift
public let concealmentEvents: Int?
```

### `audioLevelAvg`

```swift
public let audioLevelAvg: Double?
```

### `jitterAvg`

```swift
public let jitterAvg: Double?
```

### `bitrateAvg`

```swift
public let bitrateAvg: Double?
```

### `nackCount`

```swift
public let nackCount: Int?
```

### `headerBytesReceived`

```swift
public let headerBytesReceived: Int?
```

### `fecPacketsReceived`

```swift
public let fecPacketsReceived: Int?
```

### `fecPacketsDiscarded`

```swift
public let fecPacketsDiscarded: Int?
```

### `jitterBufferTargetDelay`

```swift
public let jitterBufferTargetDelay: Double?
```

### `jitterBufferMinimumDelay`

```swift
public let jitterBufferMinimumDelay: Double?
```

### `totalSamplesDecoded`

```swift
public let totalSamplesDecoded: Int?
```

### `samplesDecodedWithSilence`

```swift
public let samplesDecodedWithSilence: Int?
```

### `samplesDecodedWithConcealment`

```swift
public let samplesDecodedWithConcealment: Int?
```

### `totalAudioEnergy`

```swift
public let totalAudioEnergy: Double?
```

### `totalSamplesDuration`

```swift
public let totalSamplesDuration: Double?
```

### `codec`

```swift
public let codec: AudioCodecStats?
```

## Methods
### `init(packetsReceived:bytesReceived:packetsLost:packetsDiscarded:jitterBufferDelay:jitterBufferEmittedCount:totalSamplesReceived:concealedSamples:concealmentEvents:audioLevelAvg:jitterAvg:bitrateAvg:nackCount:headerBytesReceived:fecPacketsReceived:fecPacketsDiscarded:jitterBufferTargetDelay:jitterBufferMinimumDelay:totalSamplesDecoded:samplesDecodedWithSilence:samplesDecodedWithConcealment:totalAudioEnergy:totalSamplesDuration:codec:)`

```swift
public init(
    packetsReceived: Int? = nil,
    bytesReceived: Int? = nil,
    packetsLost: Int? = nil,
    packetsDiscarded: Int? = nil,
    jitterBufferDelay: Double? = nil,
    jitterBufferEmittedCount: Int? = nil,
    totalSamplesReceived: Int? = nil,
    concealedSamples: Int? = nil,
    concealmentEvents: Int? = nil,
    audioLevelAvg: Double? = nil,
    jitterAvg: Double? = nil,
    bitrateAvg: Double? = nil,
    nackCount: Int? = nil,
    headerBytesReceived: Int? = nil,
    fecPacketsReceived: Int? = nil,
    fecPacketsDiscarded: Int? = nil,
    jitterBufferTargetDelay: Double? = nil,
    jitterBufferMinimumDelay: Double? = nil,
    totalSamplesDecoded: Int? = nil,
    samplesDecodedWithSilence: Int? = nil,
    samplesDecodedWithConcealment: Int? = nil,
    totalAudioEnergy: Double? = nil,
    totalSamplesDuration: Double? = nil,
    codec: AudioCodecStats? = nil
)
```
