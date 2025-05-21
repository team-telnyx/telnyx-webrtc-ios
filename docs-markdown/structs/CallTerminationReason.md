**STRUCT**

# `CallTerminationReason`

```swift
public struct CallTerminationReason
```

Data class to hold detailed reasons for call termination.

## Properties
### `cause`

```swift
public let cause: String?
```

General cause description (e.g., "CALL_REJECTED").

### `causeCode`

```swift
public let causeCode: Int?
```

Numerical code for the cause (e.g., 21).

### `sipCode`

```swift
public let sipCode: Int?
```

SIP response code (e.g., 403).

### `sipReason`

```swift
public let sipReason: String?
```

SIP reason phrase (e.g., "Dialed number is not included in whitelisted countries").

## Methods
### `init(cause:causeCode:sipCode:sipReason:)`

```swift
public init(cause: String? = nil, causeCode: Int? = nil, sipCode: Int? = nil, sipReason: String? = nil)
```
