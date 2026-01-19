**STRUCT**

# `TxCodecCapability`

```swift
public struct TxCodecCapability: Codable, Equatable, Identifiable
```

Represents an audio codec capability that can be used for preferred codec selection
This mirrors the RTCRtpCodecCapability structure from WebRTC

## Properties
### `id`

```swift
public var id: String
```

Unique identifier for the codec combining mimeType, clockRate, and channels

### `mimeType`

```swift
public let mimeType: String
```

The MIME type of the codec (e.g., "audio/opus", "audio/PCMA")

### `clockRate`

```swift
public let clockRate: Int
```

The clock rate of the codec in Hz

### `channels`

```swift
public let channels: Int?
```

The number of audio channels (typically 1 or 2)

### `sdpFmtpLine`

```swift
public let sdpFmtpLine: String?
```

The SDP format-specific parameters line

## Methods
### `init(mimeType:clockRate:channels:sdpFmtpLine:)`

```swift
public init(mimeType: String, clockRate: Int, channels: Int? = nil, sdpFmtpLine: String? = nil)
```
