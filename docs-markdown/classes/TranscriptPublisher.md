**CLASS**

# `TranscriptPublisher`

```swift
public class TranscriptPublisher<T>
```

Custom publisher for iOS 12.0 compatibility (replaces Combine's Publisher)

## Methods
### `send(_:)`

```swift
public func send(_ value: T)
```

Send a new value to all subscribers
- Parameter value: The value to send

#### Parameters

| Name | Description |
| ---- | ----------- |
| value | The value to send |

### `subscribe(_:)`

```swift
public func subscribe(_ handler: @escaping (T) -> Void) -> TranscriptCancellable
```

Subscribe to publisher updates
- Parameter handler: Closure to handle updates
- Returns: Cancellable token

#### Parameters

| Name | Description |
| ---- | ----------- |
| handler | Closure to handle updates |

### `removeAllSubscribers()`

```swift
public func removeAllSubscribers()
```

Remove all subscribers
