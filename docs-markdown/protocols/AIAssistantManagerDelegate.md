**PROTOCOL**

# `AIAssistantManagerDelegate`

```swift
public protocol AIAssistantManagerDelegate: AnyObject
```

Protocol for AI Assistant Manager delegate to handle AI-related events

## Methods
### `onAIConversationMessage(_:)`

```swift
func onAIConversationMessage(_ message: [String: Any])
```

Called when an AI conversation message is received
- Parameter message: The AI conversation message content

#### Parameters

| Name | Description |
| ---- | ----------- |
| message | The AI conversation message content |

### `onRingingAckReceived(callId:)`

```swift
func onRingingAckReceived(callId: String)
```

Called when a ringing acknowledgment is received for AI assistant calls
- Parameter callId: The call ID that received the ringing acknowledgment

#### Parameters

| Name | Description |
| ---- | ----------- |
| callId | The call ID that received the ringing acknowledgment |

### `onAIAssistantConnectionStateChanged(isConnected:targetId:)`

```swift
func onAIAssistantConnectionStateChanged(isConnected: Bool, targetId: String?)
```

Called when AI assistant connection state changes
- Parameters:
  - isConnected: Whether the AI assistant is connected
  - targetId: The target ID of the AI assistant

#### Parameters

| Name | Description |
| ---- | ----------- |
| isConnected | Whether the AI assistant is connected |
| targetId | The target ID of the AI assistant |

### `onTranscriptionUpdated(_:)`

```swift
func onTranscriptionUpdated(_ transcriptions: [TranscriptionItem])
```

Called when transcription is updated
- Parameter transcriptions: The updated list of transcription items

#### Parameters

| Name | Description |
| ---- | ----------- |
| transcriptions | The updated list of transcription items |

### `onWidgetSettingsUpdated(_:)`

```swift
func onWidgetSettingsUpdated(_ settings: WidgetSettings)
```

Called when widget settings are updated
- Parameter settings: The updated widget settings

#### Parameters

| Name | Description |
| ---- | ----------- |
| settings | The updated widget settings |