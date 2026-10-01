**STRUCT**

# `CallReportMediaSummary`

```swift
public struct CallReportMediaSummary: Codable
```

## Properties
### `audio`

```swift
public let audio: Bool?
```

### `video`

```swift
public let video: Bool?
```

### `mutedMicOnStart`

```swift
public let mutedMicOnStart: Bool?
```

### `prefetchIceCandidates`

```swift
public let prefetchIceCandidates: Bool?
```

### `forceRelayCandidate`

```swift
public let forceRelayCandidate: Bool?
```

### `trickleIce`

```swift
public let trickleIce: Bool?
```

### `iceServers`

```swift
public let iceServers: [CallReportIceServerSummary]?
```

## Methods
### `init(audio:video:mutedMicOnStart:prefetchIceCandidates:forceRelayCandidate:trickleIce:iceServers:)`

```swift
public init(
    audio: Bool? = nil,
    video: Bool? = nil,
    mutedMicOnStart: Bool? = nil,
    prefetchIceCandidates: Bool? = nil,
    forceRelayCandidate: Bool? = nil,
    trickleIce: Bool? = nil,
    iceServers: [CallReportIceServerSummary]? = nil
)
```
