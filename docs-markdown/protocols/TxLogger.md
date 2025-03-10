**PROTOCOL**

# `TxLogger`

```swift
public protocol TxLogger
```

Protocol defining the interface for custom logging in the Telnyx SDK.
Implement this protocol to create a custom logger that can receive and handle logs from the SDK.

## Methods
### `log(level:message:)`

```swift
func log(level: LogLevel, message: String)
```

Called when a log message needs to be processed.
- Parameters:
  - level: The severity level of the log message
  - message: The actual log message

#### Parameters

| Name | Description |
| ---- | ----------- |
| level | The severity level of the log message |
| message | The actual log message |