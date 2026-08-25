**STRUCT**

# `ICECandidateStats`

```swift
public struct ICECandidateStats: Codable
```

A local or remote ICE candidate resolved from the selected candidate pair.

## Properties
### `id`

```swift
public let id: String?
```

### `address`

```swift
public let address: String?
```

### `port`

```swift
public let port: Int?
```

### `candidateType`

```swift
public let candidateType: String?
```

### `protocolType`

```swift
public let protocolType: String?
```

### `networkType`

```swift
public let networkType: String?
```

### `url`

```swift
public let url: String?
```

### `relayProtocol`

```swift
public let relayProtocol: String?
```

## Methods
### `init(id:address:port:candidateType:protocolType:networkType:url:relayProtocol:)`

```swift
public init(id: String? = nil, address: String? = nil, port: Int? = nil, candidateType: String? = nil, protocolType: String? = nil, networkType: String? = nil, url: String? = nil, relayProtocol: String? = nil)
```
