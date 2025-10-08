**STRUCT**

# `ConversationContent`

```swift
public struct ConversationContent
```

Represents conversation content for AI assistant messages

## Properties
### `type`

```swift
public let type: String
```

### `text`

```swift
public let text: String
```

## Methods
### `init(type:text:)`

```swift
public init(type: String = "input_text", text: String)
```

### `toDictionary()`

```swift
public func toDictionary() -> [String: Any]
```
