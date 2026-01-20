**CLASS**

# `AIAssistantManager`

```swift
public class AIAssistantManager
```

Manager class for handling AI Assistant functionality
This class manages AI assistant connections, message handling, and state management

## Properties
### `delegate`

```swift
public weak var delegate: AIAssistantManagerDelegate?
```

Delegate to receive AI assistant events

### `transcriptUpdatePublisher`

```swift
public private(set) var transcriptUpdatePublisher = TranscriptPublisher<[TranscriptionItem]>()
```

Custom publisher for real-time transcript updates (iOS 12.0 compatible)

### `transcriptItemPublisher`

```swift
public private(set) var transcriptItemPublisher = TranscriptPublisher<TranscriptionItem>()
```

Custom publisher for individual transcript item updates

### `transcript`

```swift
public var transcript: [TranscriptionItem]
```

Get current transcriptions (Android compatibility method)
- Returns: Array of transcription items

## Methods
### `init()`

```swift
public init()
```

Initialize the AI Assistant Manager

### `updateConnectionState(connected:targetId:targetType:targetVersionId:)`

```swift
public func updateConnectionState(
    connected: Bool,
    targetId: String?,
    targetType: String? = nil,
    targetVersionId: String? = nil
)
```

Update the AI assistant connection state
- Parameters:
  - connected: Whether the AI assistant is connected
  - targetId: The target ID of the AI assistant
  - targetType: The target type (optional)
  - targetVersionId: The target version ID (optional)

#### Parameters

| Name | Description |
| ---- | ----------- |
| connected | Whether the AI assistant is connected |
| targetId | The target ID of the AI assistant |
| targetType | The target type (optional) |
| targetVersionId | The target version ID (optional) |

### `processIncomingMessage(_:)`

```swift
public func processIncomingMessage(_ message: [String: Any]) -> Bool
```

Process incoming message to detect AI conversation content
- Parameter message: The incoming message to process
- Returns: True if the message was an AI conversation message, false otherwise

#### Parameters

| Name | Description |
| ---- | ----------- |
| message | The incoming message to process |

### `getConnectionInfo()`

```swift
public func getConnectionInfo() -> [String: Any]
```

Get current AI assistant connection information
- Returns: Dictionary containing connection information

### `reset()`

```swift
public func reset()
```

Reset the AI assistant manager state

### `getTranscriptions()`

```swift
public func getTranscriptions() -> [TranscriptionItem]
```

Get current transcriptions
- Returns: Array of transcription items

### `getWidgetSettings()`

```swift
public func getWidgetSettings() -> WidgetSettings?
```

Get current widget settings
- Returns: Current widget settings or nil if not set

### `addTranscription(_:)`

```swift
public func addTranscription(_ transcription: TranscriptionItem)
```

Add a transcription item
- Parameter transcription: The transcription item to add

#### Parameters

| Name | Description |
| ---- | ----------- |
| transcription | The transcription item to add |

### `updateWidgetSettings(_:)`

```swift
public func updateWidgetSettings(_ settings: WidgetSettings)
```

Update widget settings
- Parameter settings: The new widget settings

#### Parameters

| Name | Description |
| ---- | ----------- |
| settings | The new widget settings |

### `clearAllData()`

```swift
public func clearAllData()
```

Clear all transcriptions and widget settings

### `clearTranscriptions()`

```swift
public func clearTranscriptions()
```

Clear only transcriptions (called when call ends)

### `sendAIAssistantMessage(_:)`

```swift
public func sendAIAssistantMessage(_ message: String) -> Bool
```

Send a text message to AI Assistant during active call (mixed-mode communication)
- Parameter message: The text message to send
- Returns: True if message was sent successfully, false otherwise

#### Parameters

| Name | Description |
| ---- | ----------- |
| message | The text message to send |

### `sendAIAssistantMessage(_:base64Images:imageFormat:)`

```swift
public func sendAIAssistantMessage(_ message: String, base64Images: [String]?, imageFormat: String = "jpeg") -> Bool
```

Send a text message with multiple Base64 encoded images to AI Assistant during active call
- Parameters:
  - message: The text message to send
  - base64Images: Optional array of Base64 encoded image data (without data URL prefix)
  - imageFormat: Image format (jpeg, png, etc.). Defaults to "jpeg"
- Returns: True if message was sent successfully, false otherwise

#### Parameters

| Name | Description |
| ---- | ----------- |
| message | The text message to send |
| base64Images | Optional array of Base64 encoded image data (without data URL prefix) |
| imageFormat | Image format (jpeg, png, etc.). Defaults to “jpeg” |

### `sendVoiceTranscription(_:)`

```swift
public func sendVoiceTranscription(_ transcription: TranscriptionItem) -> Bool
```

Send a voice message transcription to AI Assistant
- Parameter transcription: The voice transcription to send
- Returns: True if message was sent successfully, false otherwise

#### Parameters

| Name | Description |
| ---- | ----------- |
| transcription | The voice transcription to send |

### `subscribeToTranscriptUpdates(_:)`

```swift
public func subscribeToTranscriptUpdates(_ handler: @escaping ([TranscriptionItem]) -> Void) -> TranscriptCancellable
```

Subscribe to real-time transcript updates (Android compatibility)
- Parameter handler: Closure to handle transcript updates
- Returns: Cancellable token for the subscription

#### Parameters

| Name | Description |
| ---- | ----------- |
| handler | Closure to handle transcript updates |

### `subscribeToTranscriptItemUpdates(_:)`

```swift
public func subscribeToTranscriptItemUpdates(_ handler: @escaping (TranscriptionItem) -> Void) -> TranscriptCancellable
```

Subscribe to individual transcript item updates (Android compatibility)
- Parameter handler: Closure to handle individual transcript item updates
- Returns: Cancellable token for the subscription

#### Parameters

| Name | Description |
| ---- | ----------- |
| handler | Closure to handle individual transcript item updates |

### `getTranscriptionsByRole(_:)`

```swift
public func getTranscriptionsByRole(_ role: String) -> [TranscriptionItem]
```

Get transcriptions by role
- Parameter role: The role to filter by ("user" or "assistant")
- Returns: Array of transcription items for the specified role

#### Parameters

| Name | Description |
| ---- | ----------- |
| role | The role to filter by (“user” or “assistant”) |

### `getUserTranscriptions()`

```swift
public func getUserTranscriptions() -> [TranscriptionItem]
```

Get user transcriptions only
- Returns: Array of user transcription items

### `getAssistantTranscriptions()`

```swift
public func getAssistantTranscriptions() -> [TranscriptionItem]
```

Get assistant transcriptions only
- Returns: Array of assistant transcription items

### `getPartialTranscriptions()`

```swift
public func getPartialTranscriptions() -> [TranscriptionItem]
```

Get partial transcriptions (in-progress recordings)
- Returns: Array of partial transcription items

### `getFinalTranscriptions()`

```swift
public func getFinalTranscriptions() -> [TranscriptionItem]
```

Get final transcriptions (completed recordings)
- Returns: Array of final transcription items

### `clearTranscriptionsByRole(_:)`

```swift
public func clearTranscriptionsByRole(_ role: String)
```

Clear transcriptions by role
- Parameter role: The role to clear transcriptions for

#### Parameters

| Name | Description |
| ---- | ----------- |
| role | The role to clear transcriptions for |