**ENUM**

# `LogLevel`

```swift
public enum LogLevel: Int
```

Available Log levels:
- `none`: Print no messages
- `error`: Message of level `error`
- `warning`: Message of level `warning`
- `success`: Message of level `success`
- `info`: Message of level `info`
- `verto`: Message of level `verto` messages.
- `all`:  Will print all level of messages

## Cases
### `none`

```swift
case none = 0
```

Disable logs. SDK logs will not printed. This is the default configuration.

### `error`

```swift
case error
```

Print `error` logs only

### `warning`

```swift
case warning
```

Print `warning` logs only

### `success`

```swift
case success
```

Print `success` logs only

### `info`

```swift
case info
```

Print `info` logs only

### `verto`

```swift
case verto
```

Print `verto` messages. Incoming and outgoing verto messages are printed.

### `all`

```swift
case all
```

All the SDK logs are printed.
