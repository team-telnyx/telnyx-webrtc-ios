**STRUCT**

# `CallReportSettingsSummary`

```swift
public struct CallReportSettingsSummary: Codable
```

## Properties
### `enabled`

```swift
public let enabled: Bool
```

### `intervalMs`

```swift
public let intervalMs: Int
```

### `flushIntervalMs`

```swift
public let flushIntervalMs: Int
```

### `debugLogLevel`

```swift
public let debugLogLevel: String
```

### `debugLogMaxEntries`

```swift
public let debugLogMaxEntries: Int
```

## Methods
### `init(enabled:intervalMs:flushIntervalMs:debugLogLevel:debugLogMaxEntries:)`

```swift
public init(enabled: Bool, intervalMs: Int, flushIntervalMs: Int = 180_000, debugLogLevel: String, debugLogMaxEntries: Int)
```
