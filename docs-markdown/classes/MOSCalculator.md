**CLASS**

# `MOSCalculator`

```swift
public class MOSCalculator
```

Utility class for calculating Mean Opinion Score (MOS) and call quality metrics

## Methods
### `calculateMOS(jitter:rtt:packetsReceived:packetsLost:)`

```swift
public static func calculateMOS(jitter: Double, rtt: Double, packetsReceived: Int, packetsLost: Int) -> Double
```

Calculates the Mean Opinion Score (MOS) based on WebRTC statistics
- Parameters:
  - jitter: Jitter in milliseconds
  - rtt: Round-trip time in milliseconds
  - packetsReceived: Number of packets received
  - packetsLost: Number of packets lost
- Returns: MOS score between 1.0 and 5.0

#### Parameters

| Name | Description |
| ---- | ----------- |
| jitter | Jitter in milliseconds |
| rtt | Round-trip time in milliseconds |
| packetsReceived | Number of packets received |
| packetsLost | Number of packets lost |

### `getQuality(mos:)`

```swift
public static func getQuality(mos: Double) -> CallQuality
```

Determines call quality based on MOS score
- Parameter mos: Mean Opinion Score
- Returns: Call quality rating

#### Parameters

| Name | Description |
| ---- | ----------- |
| mos | Mean Opinion Score |