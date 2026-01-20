**STRUCT**

# `ConversationItem`

```swift
public struct ConversationItem
```

Represents a conversation item for AI assistant messages

## Properties
### `id`

```swift
public let id: String
```

### `type`

```swift
public let type: String
```

### `role`

```swift
public let role: String
```

### `content`

```swift
public let content: [ConversationContent]
```

## Methods
### `init(id:type:role:content:)`

```swift
public init(id: String = UUID().uuidString, type: String = "message", role: String = "user", content: [ConversationContent])
```

### `toDictionary()`

```swift
public func toDictionary() -> [String: Any]
```
