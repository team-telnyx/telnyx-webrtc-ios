**STRUCT**

# `TranscriptionItem`

```swift
public struct TranscriptionItem
```

Represents a transcription item from AI assistant conversations (Android-compatible)

## Properties
### `id`

```swift
public let id: String
```

### `role`

```swift
public let role: String
```

### `content`

```swift
public let content: String
```

### `isPartial`

```swift
public let isPartial: Bool
```

### `timestamp`

```swift
public let timestamp: Date
```

### `itemType`

```swift
public let itemType: String?
```

### `metadata`

```swift
public let metadata: [String: Any]?
```

### `imageUrls`

```swift
public let imageUrls: [String]?
```

### `speaker`

```swift
public var speaker: String
```

### `text`

```swift
public var text: String
```

### `isFinal`

```swift
public var isFinal: Bool
```

### `hasImages`

```swift
public var hasImages: Bool
```

### `imageCount`

```swift
public var imageCount: Int
```

## Methods
### `init(id:role:content:isPartial:timestamp:itemType:metadata:imageUrls:)`

```swift
public init(id: String = UUID().uuidString, role: String, content: String, isPartial: Bool = false, timestamp: Date = Date(), itemType: String? = nil, metadata: [String: Any]? = nil, imageUrls: [String]? = nil)
```

### `init(id:timestamp:speaker:text:confidence:isFinal:itemType:metadata:)`

```swift
public init(id: String, timestamp: Date, speaker: String, text: String, confidence: Double? = nil, isFinal: Bool = true, itemType: String? = nil, metadata: [String: Any]? = nil)
```
