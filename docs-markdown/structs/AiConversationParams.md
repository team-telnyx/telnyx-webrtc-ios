**STRUCT**

# `AiConversationParams`

```swift
public struct AiConversationParams
```

Represents AI conversation parameters

## Properties
### `type`

```swift
public let type: String
```

### `item`

```swift
public let item: ConversationItem
```

## Methods
### `init(type:item:)`

```swift
public init(type: String = "conversation.item.create", item: ConversationItem)
```

### `toDictionary()`

```swift
public func toDictionary() -> [String: Any]
```
