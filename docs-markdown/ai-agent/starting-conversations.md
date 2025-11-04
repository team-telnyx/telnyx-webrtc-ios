# Starting Conversations

After successful anonymous login, you can initiate voice conversations with AI assistants. The destination number is ignored after anonymous login, as all calls are automatically routed to your specified AI assistant.

## Overview

Starting a conversation with an AI assistant follows the same pattern as regular calls, but with simplified routing. The AI assistant will automatically answer the call, eliminating the need for manual call acceptance.

## Basic Call Initiation

### Simple Conversation Start

```swift
import TelnyxRTC

class AIConversationController: UIViewController {
    private let client = TxClient()
    private var activeCall: Call?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
        setupAIConnection()
    }
    
    private func setupAIConnection() {
        // Step 1: Anonymous login
        client.anonymousLogin(targetId: "your-ai-assistant-id")
    }
    
    private func startConversation() {
        // Step 2: Start conversation (destination ignored after anonymous login)
        activeCall = client.newInvite(
            callerName: "User",
            callerNumber: "user",
            destinationNumber: "ai-assistant", // This is ignored
            callId: UUID()
        )
    }
}

extension AIConversationController: TxClientDelegate {
    func onClientReady() {
        print("Client ready - starting AI conversation")
        startConversation()
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        guard activeCall?.callId == callId else { return }
        
        switch callState {
        case .CONNECTING:
            print("Connecting to AI assistant...")
        case .RINGING:
            print("AI assistant is being contacted...")
        case .ACTIVE:
            print("AI conversation is now active")
            onConversationStarted()
        case .DONE:
            print("AI conversation ended")
            onConversationEnded()
        default:
            print("Call state: \(callState)")
        }
    }
    
    private func onConversationStarted() {
        // Conversation is active - can now send messages and receive transcripts
        setupTranscriptListening()
    }
    
    private func onConversationEnded() {
        activeCall = nil
    }
}
```

## Custom Headers for AI Assistants

You can include custom headers when starting conversations with AI assistants. This is particularly useful for passing additional context or configuration:

```swift
private func startConversationWithHeaders() {
    // Custom headers for AI assistant context
    let customHeaders: [String: String] = [
        "X-User-ID": "user123",
        "X-Session-Type": "support",
        "X-Language": "en-US",
        "X-Priority": "high",
        "X-Context": "product_inquiry"
    ]
    
    activeCall = client.newInvite(
        callerName: "John Doe",
        callerNumber: "user123",
        destinationNumber: "support-ai", // Ignored after anonymous login
        callId: UUID(),
        customHeaders: customHeaders
    )
}
```

## Advanced Conversation Management

### Conversation with State Tracking

```swift
class AIConversationManager {
    private let client = TxClient()
    private var conversationState: ConversationState = .idle
    private var currentCall: Call?
    private var conversationStartTime: Date?
    
    enum ConversationState {
        case idle
        case connecting
        case active
        case ending
        case ended
    }
    
    func initiateConversation(with assistantId: String, context: [String: Any] = [:]) {
        guard conversationState == .idle else {
            print("Conversation already in progress")
            return
        }
        
        conversationState = .connecting
        client.delegate = self
        
        // Login with context
        client.anonymousLogin(
            targetId: assistantId,
            userVariables: context
        )
    }
    
    private func startCall() {
        let callId = UUID()
        conversationStartTime = Date()
        
        currentCall = client.newInvite(
            callerName: "Mobile User",
            callerNumber: "mobile_user",
            destinationNumber: "ai_assistant",
            callId: callId,
            customHeaders: [
                "X-Platform": "iOS",
                "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ]
        )
    }
    
    func endConversation() {
        guard let call = currentCall else { return }
        
        conversationState = .ending
        call.hangup()
    }
}

extension AIConversationManager: TxClientDelegate {
    func onClientReady() {
        startCall()
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        guard currentCall?.callId == callId else { return }
        
        switch callState {
        case .ACTIVE:
            conversationState = .active
            notifyConversationStarted()
        case .DONE:
            conversationState = .ended
            notifyConversationEnded()
        default:
            break
        }
    }
    
    private func notifyConversationStarted() {
        print("AI conversation started at \(conversationStartTime!)")
        // Setup transcript monitoring, UI updates, etc.
    }
    
    private func notifyConversationEnded() {
        let duration = Date().timeIntervalSince(conversationStartTime ?? Date())
        print("AI conversation ended after \(duration) seconds")
        
        currentCall = nil
        conversationStartTime = nil
    }
}
```

## Call Configuration Options

### Audio Settings

```swift
private func startConversationWithAudioConfig() {
    // Configure audio before starting call
    let audioConfig = TxConfig(
        ringtone: nil, // No ringtone needed for AI calls
        ringBackTone: nil, // No ringback needed
        logLevel: .all
    )
    
    // Start conversation
    activeCall = client.newInvite(
        callerName: "User",
        callerNumber: "user",
        destinationNumber: "ai",
        callId: UUID()
    )
}
```

### Call Quality Settings

```swift
private func startHighQualityConversation() {
    let customHeaders: [String: String] = [
        "X-Audio-Quality": "high",
        "X-Codec-Preference": "opus",
        "X-Bitrate": "64000"
    ]
    
    activeCall = client.newInvite(
        callerName: "User",
        callerNumber: "user",
        destinationNumber: "ai",
        callId: UUID(),
        customHeaders: customHeaders
    )
}
```

## Error Handling

Implement robust error handling for conversation initiation:

```swift
extension AIConversationController: TxClientDelegate {
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        guard activeCall?.callId == callId else { return }
        
        switch callState {
        case .DONE:
            handleCallEnd()
        default:
            break
        }
    }
    
    func onClientError(error: Error) {
        if let txError = error as? TxError {
            switch txError {
            case .callFailure(let reason):
                handleCallFailure(reason)
            default:
                print("Client error: \(txError)")
            }
        }
    }
    
    private func handleCallFailure(_ reason: TxError.CallFailureReason) {
        switch reason {
        case .connectionFailed:
            print("Failed to connect to AI assistant")
            retryConnection()
        case .timeout:
            print("Call timeout - AI assistant may be unavailable")
        default:
            print("Call failed: \(reason)")
        }
    }
    
    private func retryConnection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startConversation()
        }
    }
    
    private func handleCallEnd() {
        activeCall = nil
        print("Conversation with AI assistant ended")
    }
}
```

## Best Practices

### 1. Auto-Answer Handling

AI assistants automatically answer calls, so don't wait for manual acceptance:

```swift
func onCallStateUpdated(callState: CallState, callId: UUID) {
    switch callState {
    case .RINGING:
        // AI will auto-answer, no action needed
        print("AI assistant is responding...")
    case .ACTIVE:
        // Conversation is ready
        onConversationReady()
    default:
        break
    }
}
```

### 2. Context Passing

Use custom headers and user variables to provide context:

```swift
let userContext: [String: Any] = [
    "user_id": "12345",
    "session_type": "support",
    "previous_issue": "billing_question"
]

client.anonymousLogin(
    targetId: "support-ai",
    userVariables: userContext
)

// Additional context via headers
let headers = [
    "X-Urgency": "high",
    "X-Department": "billing"
]

activeCall = client.newInvite(
    callerName: "Customer",
    callerNumber: "customer",
    destinationNumber: "support",
    callId: UUID(),
    customHeaders: headers
)
```

### 3. Connection Lifecycle

Properly manage the connection lifecycle:

```swift
class AIConversationViewController: UIViewController {
    private let client = TxClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            endConversation()
        }
    }
    
    private func endConversation() {
        activeCall?.hangup()
        client.disconnect()
        client.delegate = nil
    }
}
```

## Integration with Transcripts

Start listening to transcripts immediately when conversation becomes active:

```swift
func onCallStateUpdated(callState: CallState, callId: UUID) {
    guard activeCall?.callId == callId else { return }
    
    if callState == .ACTIVE {
        // Start transcript monitoring
        let cancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { transcripts in
            DispatchQueue.main.async {
                self.handleTranscriptUpdate(transcripts)
            }
        }
        
        // Store cancellable for cleanup
        self.transcriptCancellable = cancellable
    }
}
```

## Next Steps

After starting a conversation:

1. **[Monitor Transcripts](transcript-updates.md)** - Handle real-time conversation transcripts
2. **[Send Text Messages](text-messaging.md)** - Implement mixed voice/text communication
3. **[Handle Call States](../classes/Call.md)** - Manage call lifecycle and controls

## Related Documentation

- [Anonymous Login](anonymous-login.md) - Authentication setup
- [Call](../classes/Call.md) - Call management and controls
- [TxClient](../classes/TxClient.md) - Complete client API reference
- [CallState](../enums/CallState.md) - Call state reference