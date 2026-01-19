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
public let text: String?
```

### `imageURL`

```swift
public let imageURL: ImageURL?
```

## Methods
### `init(type:text:)`

```swift
public init(type: String = "input_text", text: String)
```

Initialize with text content

### `init(type:imageURL:)`

```swift
public init(type: String = "image_url", imageURL: ImageURL)
```

Initialize with image URL content

### `toDictionary()`

```swift
public func toDictionary() -> [String: Any]
```
