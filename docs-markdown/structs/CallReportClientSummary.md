**STRUCT**

# `CallReportClientSummary`

```swift
public struct CallReportClientSummary: Codable
```

JS-compatible, sanitized runtime configuration included with a call report.
Keep this intentionally narrow: a call report must never contain ICE server
credentials, authentication secrets, or user-provided sensitive values.

## Properties
### `connection`

```swift
public let connection: CallReportConnectionSummary?
```

### `media`

```swift
public let media: CallReportMediaSummary?
```

### `callReports`

```swift
public let callReports: CallReportSettingsSummary?
```

## Methods
### `init(connection:media:callReports:)`

```swift
public init(
    connection: CallReportConnectionSummary? = nil,
    media: CallReportMediaSummary? = nil,
    callReports: CallReportSettingsSummary? = nil
)
```
