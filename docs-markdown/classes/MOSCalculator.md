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
- Returns: MOS score in the inclusive range `1.0...5.0`, or `NaN` when the
  inputs are non-finite or the computation overflows. Callers should pair
  the result with `getQuality(mos:)`, which maps `NaN` to `.unknown`.

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

Determines call quality based on MOS score.

Non-finite inputs (`NaN`, `±infinity`) are reported as `.unknown`. For
finite values the bands are continuous — every non-negative MOS value
maps to exactly one rating, with no gaps between bands.
- Parameter mos: Mean Opinion Score
- Returns: Call quality rating

#### Parameters

| Name | Description |
| ---- | ----------- |
| mos | Mean Opinion Score |