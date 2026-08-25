**STRUCT**

# `AudioCodecStats`

```swift
public struct AudioCodecStats: Codable
```

Codec metadata linked from an RTP statistics record.

## Properties
### `codecId`

```swift
public let codecId: String?
```

### `mimeType`

```swift
public let mimeType: String?
```

### `payloadType`

```swift
public let payloadType: Int?
```

### `clockRate`

```swift
public let clockRate: Int?
```

### `channels`

```swift
public let channels: Int?
```

### `sdpFmtpLine`

```swift
public let sdpFmtpLine: String?
```

## Methods
### `init(codecId:mimeType:payloadType:clockRate:channels:sdpFmtpLine:)`

```swift
public init(codecId: String? = nil, mimeType: String? = nil, payloadType: Int? = nil, clockRate: Int? = nil, channels: Int? = nil, sdpFmtpLine: String? = nil)
```
