**STRUCT**

# `ICECandidatePairStats`

```swift
public struct ICECandidatePairStats: Codable
```

Selected ICE candidate-pair details. Field names mirror the JS SDK report.

## Properties
### `id`

```swift
public let id: String?
```

### `localCandidateId`

```swift
public let localCandidateId: String?
```

### `remoteCandidateId`

```swift
public let remoteCandidateId: String?
```

### `state`

```swift
public let state: String?
```

### `nominated`

```swift
public let nominated: Bool?
```

### `writable`

```swift
public let writable: Bool?
```

### `currentRoundTripTime`

```swift
public let currentRoundTripTime: Double?
```

### `requestsSent`

```swift
public let requestsSent: Int?
```

### `responsesReceived`

```swift
public let responsesReceived: Int?
```

### `local`

```swift
public let local: ICECandidateStats?
```

### `remote`

```swift
public let remote: ICECandidateStats?
```

## Methods
### `init(id:localCandidateId:remoteCandidateId:state:nominated:writable:currentRoundTripTime:requestsSent:responsesReceived:local:remote:)`

```swift
public init(id: String? = nil, localCandidateId: String? = nil, remoteCandidateId: String? = nil, state: String? = nil, nominated: Bool? = nil, writable: Bool? = nil, currentRoundTripTime: Double? = nil, requestsSent: Int? = nil, responsesReceived: Int? = nil, local: ICECandidateStats? = nil, remote: ICECandidateStats? = nil)
```
