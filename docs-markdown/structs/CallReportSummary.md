**STRUCT**

# `CallReportSummary`

```swift
public struct CallReportSummary: Codable
```

Summary information about the call

## Properties
### `callId`

```swift
public let callId: String
```

### `destinationNumber`

```swift
public let destinationNumber: String?
```

### `callerNumber`

```swift
public let callerNumber: String?
```

### `direction`

```swift
public let direction: String?
```

### `state`

```swift
public let state: String?
```

### `durationSeconds`

```swift
public let durationSeconds: Double?
```

### `telnyxSessionId`

```swift
public let telnyxSessionId: String?
```

### `telnyxLegId`

```swift
public let telnyxLegId: String?
```

### `voiceSdkSessionId`

```swift
public let voiceSdkSessionId: String?
```

### `sdkVersion`

```swift
public let sdkVersion: String?
```

### `startTimestamp`

```swift
public let startTimestamp: String?
```

### `endTimestamp`

```swift
public let endTimestamp: String?
```

### `clientSummary`

```swift
public let clientSummary: CallReportClientSummary?
```

Sanitized client and call options that were in effect for this call.
Credentials and ICE usernames are represented only as presence flags.

## Methods
### `init(callId:destinationNumber:callerNumber:direction:state:durationSeconds:telnyxSessionId:telnyxLegId:voiceSdkSessionId:sdkVersion:startTimestamp:endTimestamp:clientSummary:)`

```swift
public init(
    callId: String,
    destinationNumber: String? = nil,
    callerNumber: String? = nil,
    direction: String? = nil,
    state: String? = nil,
    durationSeconds: Double? = nil,
    telnyxSessionId: String? = nil,
    telnyxLegId: String? = nil,
    voiceSdkSessionId: String? = nil,
    sdkVersion: String? = nil,
    startTimestamp: String? = nil,
    endTimestamp: String? = nil,
    clientSummary: CallReportClientSummary? = nil
)
```
