**STRUCT**

# `TransportStats`

```swift
public struct TransportStats: Codable
```

DTLS/ICE transport snapshot for a reporting interval.

## Properties
### `iceState`

```swift
public let iceState: String?
```

### `dtlsState`

```swift
public let dtlsState: String?
```

### `srtpCipher`

```swift
public let srtpCipher: String?
```

### `tlsVersion`

```swift
public let tlsVersion: String?
```

### `selectedCandidatePairChanges`

```swift
public let selectedCandidatePairChanges: Int?
```

### `selectedCandidatePairId`

```swift
public let selectedCandidatePairId: String?
```

## Methods
### `init(iceState:dtlsState:srtpCipher:tlsVersion:selectedCandidatePairChanges:selectedCandidatePairId:)`

```swift
public init(iceState: String? = nil, dtlsState: String? = nil, srtpCipher: String? = nil, tlsVersion: String? = nil, selectedCandidatePairChanges: Int? = nil, selectedCandidatePairId: String? = nil)
```
