# AI Agent Integration

The Telnyx iOS WebRTC SDK provides comprehensive support for AI Agent functionality, enabling developers to create intelligent voice applications with real-time conversation capabilities.

## Overview

AI Agents are intelligent assistants that can engage in natural voice conversations with users. The iOS SDK provides seamless integration with Telnyx AI Agents through a simplified authentication flow and real-time communication features.

## Key Features

### 🔐 Anonymous Authentication
- Connect to AI assistants without traditional SIP credentials
- Simplified login process using target ID and type
- Automatic session management

### 🗣️ Voice Conversations
- Real-time voice communication with AI assistants
- Automatic call answering by AI agents
- High-quality audio processing

### 📝 Live Transcriptions
- Real-time conversation transcripts
- Role-based message identification (user/assistant)
- Partial and final transcript updates
- Custom publisher for iOS 12.0+ compatibility

### 💬 Mixed Communication
- Send text messages during voice calls
- Seamless voice and text interaction
- Rich conversation context

### ⚙️ Widget Settings
- Customizable AI assistant interface
- Theme and language configuration
- Audio visualizer settings
- Custom styling options

## Quick Start

Here's a minimal example to get started with AI Agent integration:

```swift
import TelnyxRTC

class AIAgentViewController: UIViewController {
    private let client = TxClient()
    private var currentCall: Call?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
        setupAIAgent()
    }
    
    private func setupAIAgent() {
        // Step 1: Anonymous login to AI assistant
        client.anonymousLogin(
            targetId: "your-ai-assistant-id",
            targetType: "ai_assistant"
        )
    }
    
    private func startConversation() {
        // Step 2: Start conversation (destination ignored after anonymous login)
        currentCall = client.newInvite(
            callerName: "User",
            callerNumber: "user",
            destinationNumber: "ai-assistant", // Ignored after anonymous login
            callId: UUID()
        )
    }
    
    private func sendTextMessage() {
        // Step 3: Send text message during call
        let success = client.sendAIAssistantMessage("Hello, can you help me?")
        print("Message sent: \(success)")
    }
    
    private func subscribeToTranscripts() {
        // Step 4: Listen to real-time transcripts
        let cancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { transcripts in
            DispatchQueue.main.async {
                self.updateTranscriptUI(transcripts)
            }
        }
        // Store cancellable to manage subscription lifecycle
    }
    
    private func updateTranscriptUI(_ transcripts: [TranscriptionItem]) {
        for transcript in transcripts {
            print("\(transcript.role): \(transcript.content)")
        }
    }
}

extension AIAgentViewController: TxClientDelegate {
    func onClientReady() {
        print("Client ready - can start AI conversation")
        startConversation()
    }
    
    func onIncomingCall(call: Call) {
        // AI assistants typically auto-answer
        currentCall = call
        call.answer()
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        switch callState {
        case .ACTIVE:
            print("AI conversation active")
            subscribeToTranscripts()
        case .DONE:
            print("AI conversation ended")
        default:
            break
        }
    }
}
```

## Implementation Steps

1. **[Anonymous Login](anonymous-login.md)** - Authenticate with AI assistants without SIP credentials
2. **[Starting Conversations](starting-conversations.md)** - Initiate calls with AI agents
3. **[Transcript Updates](transcript-updates.md)** - Handle real-time conversation transcripts
4. **[Text Messaging](text-messaging.md)** - Send text messages during voice calls

## Architecture

The AI Agent functionality is built around several key components:

- **`TxClient`** - Main client with `anonymousLogin()` and `sendAIAssistantMessage()` methods
- **`AIAssistantManager`** - Manages AI assistant state, transcripts, and widget settings
- **`TranscriptionItem`** - Represents individual transcript entries with role identification
- **`WidgetSettings`** - Configuration for AI assistant interface customization

## Best Practices

### Error Handling
Always implement proper error handling for AI agent operations:

```swift
// Check connection state before operations
if client.isConnected {
    let success = client.sendAIAssistantMessage("Hello")
    if !success {
        print("Failed to send message - check connection")
    }
}
```

### Memory Management
Properly manage subscription lifecycles:

```swift
class AIAgentManager {
    private var transcriptCancellable: TranscriptCancellable?
    
    func startListening() {
        transcriptCancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { _ in
            // Handle updates
        }
    }
    
    deinit {
        transcriptCancellable?.cancel()
    }
}
```

### UI Updates
Always update UI on the main thread:

```swift
client.aiAssistantManager.subscribeToTranscriptUpdates { transcripts in
    DispatchQueue.main.async {
        self.updateTranscriptView(transcripts)
    }
}
```

## Next Steps

- Explore [Anonymous Login](anonymous-login.md) for authentication details
- Learn about [Starting Conversations](starting-conversations.md) for call initiation
- Understand [Transcript Updates](transcript-updates.md) for real-time messaging
- Implement [Text Messaging](text-messaging.md) for mixed communication

For complete API reference, see the [AIAssistantManager](../classes/AIAssistantManager.md) and [TxClient](../classes/TxClient.md) documentation.