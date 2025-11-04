# Real-time Transcript Updates

## Overview

During AI Assistant conversations, the SDK provides real-time transcript updates that include both the caller's speech and the AI Assistant's responses. This allows you to display a live conversation transcript in your application.

## Transcript Properties

The SDK provides two main ways to access transcript data:

### Custom Publisher for Real-time Updates

```swift
// Subscribe to transcript updates using custom publisher
let cancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { transcripts in
    // Handle transcript updates
}
```

### Current Transcript Access

```swift
// Get current transcripts as property (read-only)
let transcripts = client.aiAssistantManager.transcript

// Or via method
let transcripts = client.aiAssistantManager.getTranscriptions()
```

## TranscriptionItem Structure

```swift
public struct TranscriptionItem {
    public let id: String                    // Unique identifier
    public let role: String                  // "user" or "assistant"
    public let content: String               // The transcribed text
    public let timestamp: Date               // When the item was created
    public let isPartial: Bool               // Whether this is a partial response
}
```

## Setting Up Transcript Updates

### Using Custom Publisher (Recommended)

```swift
class AIConversationViewController: UIViewController {
    private let client = TxClient()
    private var transcriptCancellable: TranscriptCancellable?
    private var conversationTranscript: [TranscriptionItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTranscriptListener()
    }

    private func setupTranscriptListener() {
        transcriptCancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { [weak self] transcript in
            // Updates are already dispatched on main thread by the publisher
            self?.updateConversationUI(transcript)
        }
    }

    private func updateConversationUI(_ transcript: [TranscriptionItem]) {
        conversationTranscript = transcript

        // Update UI
        conversationTableView.reloadData()

        // Auto-scroll to bottom
        if !transcript.isEmpty {
            let indexPath = IndexPath(row: transcript.count - 1, section: 0)
            conversationTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    deinit {
        transcriptCancellable?.cancel()
    }
}
```

### Processing Individual Transcript Items

```swift
private func updateConversationUI(_ transcript: [TranscriptionItem]) {
    transcript.forEach { item in
        switch item.role {
        case "user":
            print("User said: \(item.content)")
            // Display user message in UI
            addUserMessage(item.content, item.timestamp)
        case "assistant":
            print("Assistant said: \(item.content)")
            // Display assistant message in UI
            addAssistantMessage(item.content, item.timestamp, item.isPartial)
        default:
            break
        }
    }
}
```

## Manual Transcript Access

You can also manually retrieve the current transcript at any time:

```swift
// Get current transcript via property
let currentTranscript = client.aiAssistantManager.transcript

// Or via method
let currentTranscript = client.aiAssistantManager.getTranscriptions()

// Process the transcript
currentTranscript.forEach { item in
    print("\(item.role): \(item.content) (\(item.timestamp))")
}
```

## Filtering Transcripts

The SDK provides convenient methods to filter transcripts by role or status:

```swift
// Get only user transcriptions
let userMessages = client.aiAssistantManager.getUserTranscriptions()

// Get only assistant transcriptions
let assistantMessages = client.aiAssistantManager.getAssistantTranscriptions()

// Get only partial (in-progress) transcriptions
let partialMessages = client.aiAssistantManager.getPartialTranscriptions()

// Get only final (completed) transcriptions
let finalMessages = client.aiAssistantManager.getFinalTranscriptions()

// Get transcriptions by specific role
let transcriptionsByRole = client.aiAssistantManager.getTranscriptionsByRole("user")
```

## Handling Partial Responses

AI Assistant responses may come in chunks (partial responses). Handle these appropriately:

```swift
private func addAssistantMessage(_ content: String, _ timestamp: Date, _ isPartial: Bool) {
    if isPartial {
        // Update existing message or show typing indicator
        updateLastAssistantMessage(content)
        showTypingIndicator(true)
    } else {
        // Final message - hide typing indicator
        showTypingIndicator(false)
        finalizeAssistantMessage(content, timestamp)
    }
}
```

## Complete Example with UITableView

```swift
class ConversationViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    private let client = TxClient()
    private var transcripts: [TranscriptionItem] = []
    private var cancellable: TranscriptCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        setupTranscripts()
    }

    private func setupTranscripts() {
        cancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { [weak self] transcripts in
            DispatchQueue.main.async {
                self?.transcripts = transcripts
                self?.tableView.reloadData()
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcripts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let transcript = transcripts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TranscriptCell", for: indexPath)

        cell.textLabel?.text = transcript.content

        // Style based on role
        if transcript.role == "user" {
            cell.backgroundColor = .systemBlue
            cell.textLabel?.textColor = .white
            cell.textLabel?.textAlignment = .right
        } else {
            cell.backgroundColor = .systemGray6
            cell.textLabel?.textColor = .label
            cell.textLabel?.textAlignment = .left
        }

        // Show partial indicator
        cell.textLabel?.alpha = transcript.isPartial ? 0.7 : 1.0

        return cell
    }

    deinit {
        cancellable?.cancel()
    }
}
```

## Delegate Pattern (Alternative Approach)

You can also use the delegate pattern to receive transcript updates:

```swift
class AIConversationViewController: UIViewController, AIAssistantManagerDelegate {
    private let client = TxClient()

    override func viewDidLoad() {
        super.viewDidLoad()
        client.aiAssistantManager.delegate = self
    }

    // MARK: - AIAssistantManagerDelegate

    func onTranscriptionUpdated(_ transcriptions: [TranscriptionItem]) {
        // Handle transcript updates
        updateConversationUI(transcriptions)
    }

    func onWidgetSettingsUpdated(_ settings: WidgetSettings) {
        // Handle widget settings updates
        print("Widget settings updated: \(settings)")
    }

    func onAIConversationMessage(_ message: [String: Any]) {
        // Handle raw AI conversation messages
        print("AI message received: \(message)")
    }

    func onAIAssistantConnectionStateChanged(isConnected: Bool, targetId: String?) {
        // Handle connection state changes
        print("AI Assistant connected: \(isConnected), targetId: \(targetId ?? "none")")
    }

    func onRingingAckReceived(callId: String) {
        // Handle ringing acknowledgment
        print("Ringing ack for call: \(callId)")
    }
}
```

## Widget Settings Access

Access AI conversation widget settings:

```swift
// Get current widget settings
if let widgetSettings = client.aiAssistantManager.widgetSettings {
    // Use widget settings to configure UI
    print("Widget settings: \(widgetSettings)")
}
```

## Connection State Monitoring

Monitor the AI Assistant connection state:

```swift
// Check if AI Assistant is connected
if client.aiAssistantManager.isAIAssistantConnected {
    print("AI Assistant is connected")
}

// Get the connected target ID
if let targetId = client.aiAssistantManager.connectedTargetId {
    print("Connected to target: \(targetId)")
}
```

## Clearing Transcripts

You can clear transcripts manually if needed:

```swift
// Clear all transcriptions
client.aiAssistantManager.clearTranscriptions()

// Clear transcriptions by specific role
client.aiAssistantManager.clearTranscriptionsByRole("user")
client.aiAssistantManager.clearTranscriptionsByRole("assistant")

// Clear all AI Assistant data (including transcripts and widget settings)
client.aiAssistantManager.clearAllData()
```

## Important Notes

- **AI Assistant Only**: Transcript updates are only available during AI Assistant conversations initiated through `anonymousLogin`
- **Real-time Updates**: Transcripts update in real-time as the conversation progresses
- **Partial Responses**: Assistant responses may come in chunks - handle `isPartial` flag appropriately
- **Memory Management**: Transcripts are automatically cleared when calls end or when disconnecting
- **Thread Safety**: Publisher updates are dispatched on the main thread automatically
- **Multiple Subscribers**: You can have multiple subscribers to the same transcript updates

## Error Handling

```swift
cancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { [weak self] transcripts in
    guard !transcripts.isEmpty else {
        print("Received empty transcript array")
        return
    }

    self?.updateConversationUI(transcripts)
}

// Always cancel subscriptions when done
deinit {
    cancellable?.cancel()
}
```

## Next Steps

After setting up transcript updates:
1. [Send text messages](https://developers.telnyx.com/development/webrtc/ios-sdk/ai-agent/text-messaging) to interact with the AI Assistant via text
