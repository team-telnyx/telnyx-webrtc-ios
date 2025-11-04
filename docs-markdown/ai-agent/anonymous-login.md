# Anonymous Login

Anonymous login allows you to connect to AI assistants without traditional SIP credentials. This simplified authentication method is specifically designed for AI agent interactions.

## Overview

The `anonymousLogin()` method establishes a connection to the Telnyx backend and authenticates with a specific AI assistant using only a target ID. No username, password, or token is required.

## Method Signature

```swift
public func anonymousLogin(
    targetId: String, 
    targetType: String = "ai_assistant", 
    targetVersionId: String? = nil,
    userVariables: [String: Any] = [:],
    reconnection: Bool = false,
    serverConfiguration: TxServerConfiguration = TxServerConfiguration()
)
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `targetId` | `String` | Required | The unique identifier of the AI assistant |
| `targetType` | `String` | `"ai_assistant"` | The type of target (typically "ai_assistant") |
| `targetVersionId` | `String?` | `nil` | Optional version identifier for the AI assistant |
| `userVariables` | `[String: Any]` | `[:]` | Optional user variables to pass to the AI assistant |
| `reconnection` | `Bool` | `false` | Whether this is a reconnection attempt |
| `serverConfiguration` | `TxServerConfiguration` | `TxServerConfiguration()` | Server configuration settings |

## Basic Usage

### Simple Anonymous Login

```swift
import TelnyxRTC

class AIViewController: UIViewController {
    private let client = TxClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
        connectToAIAssistant()
    }
    
    private func connectToAIAssistant() {
        // Connect to AI assistant with minimal configuration
        client.anonymousLogin(targetId: "your-ai-assistant-id")
    }
}

extension AIViewController: TxClientDelegate {
    func onClientReady() {
        print("Successfully connected to AI assistant")
        // Ready to start conversations
    }
    
    func onClientError(error: Error) {
        print("Connection failed: \(error.localizedDescription)")
    }
}
```

### Advanced Configuration

```swift
private func connectWithAdvancedConfig() {
    // Custom server configuration
    let serverConfig = TxServerConfiguration(
        signalingServer: "wss://rtc.telnyx.com",
        turnServer: "turn:turn.telnyx.com:3478",
        stunServer: "stun:stun.telnyx.com:3478"
    )
    
    // User variables for context
    let userVariables: [String: Any] = [
        "user_id": "12345",
        "session_type": "support",
        "language": "en-US",
        "timezone": "America/New_York"
    ]
    
    client.anonymousLogin(
        targetId: "support-ai-assistant",
        targetType: "ai_assistant",
        targetVersionId: "v2.1",
        userVariables: userVariables,
        reconnection: false,
        serverConfiguration: serverConfig
    )
}
```

## Connection Flow

The anonymous login process follows these steps:

1. **Socket Connection**: If not already connected, establishes WebSocket connection to Telnyx backend
2. **Authentication**: Sends anonymous login message with target information
3. **Session Lock**: After successful login, all subsequent calls route to the specified AI assistant
4. **Ready State**: Client becomes ready for AI assistant interactions

```swift
class AIConnectionManager {
    private let client = TxClient()
    private var connectionState: ConnectionState = .disconnected
    
    enum ConnectionState {
        case disconnected
        case connecting
        case authenticating
        case ready
        case error(Error)
    }
    
    func connect(to assistantId: String) {
        connectionState = .connecting
        client.delegate = self
        
        client.anonymousLogin(
            targetId: assistantId,
            userVariables: [
                "connection_time": Date().timeIntervalSince1970,
                "client_version": "iOS-1.0"
            ]
        )
    }
}

extension AIConnectionManager: TxClientDelegate {
    func onSocketConnected() {
        connectionState = .authenticating
        print("Socket connected, authenticating...")
    }
    
    func onClientReady() {
        connectionState = .ready
        print("AI assistant ready for conversations")
    }
    
    func onClientError(error: Error) {
        connectionState = .error(error)
        print("Connection error: \(error)")
    }
    
    func onSocketDisconnected() {
        connectionState = .disconnected
        print("Disconnected from AI assistant")
    }
}
```

## Session Management

After anonymous login, the client session is locked to the specified AI assistant:

```swift
class AISessionManager {
    private let client = TxClient()
    private var currentAssistantId: String?
    
    func switchAssistant(to newAssistantId: String) {
        // Disconnect current session
        client.disconnect()
        
        // Connect to new assistant
        currentAssistantId = newAssistantId
        client.anonymousLogin(targetId: newAssistantId)
    }
    
    func reconnectToCurrentAssistant() {
        guard let assistantId = currentAssistantId else {
            print("No current assistant to reconnect to")
            return
        }
        
        client.anonymousLogin(
            targetId: assistantId,
            reconnection: true
        )
    }
}
```

## Error Handling

Implement comprehensive error handling for connection issues:

```swift
extension AIViewController: TxClientDelegate {
    func onClientError(error: Error) {
        if let txError = error as? TxError {
            switch txError {
            case .socketFailure(let reason):
                handleSocketError(reason)
            case .clientConfigurationFailure(let reason):
                handleConfigError(reason)
            case .serverError(let reason):
                handleServerError(reason)
            default:
                handleGenericError(txError)
            }
        } else {
            print("Unknown error: \(error.localizedDescription)")
        }
    }
    
    private func handleSocketError(_ reason: TxError.SocketFailureReason) {
        switch reason {
        case .connectionTimeout:
            print("Connection timeout - check network")
            retryConnection()
        case .authenticationFailed:
            print("Authentication failed - check target ID")
        default:
            print("Socket error: \(reason)")
        }
    }
    
    private func retryConnection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.connectToAIAssistant()
        }
    }
}
```

## Best Practices

### 1. Connection State Management

Always track connection state to prevent multiple simultaneous connections:

```swift
class AIClient {
    private let client = TxClient()
    private var isConnecting = false
    
    func connectToAssistant(_ assistantId: String) {
        guard !isConnecting && !client.isConnected else {
            print("Already connected or connecting")
            return
        }
        
        isConnecting = true
        client.anonymousLogin(targetId: assistantId)
    }
}
```

### 2. User Variables

Use user variables to provide context to the AI assistant:

```swift
let contextVariables: [String: Any] = [
    "user_name": "John Doe",
    "user_type": "premium",
    "previous_interactions": 5,
    "preferred_language": "en-US",
    "session_context": "product_support"
]

client.anonymousLogin(
    targetId: "support-assistant",
    userVariables: contextVariables
)
```

### 3. Cleanup

Properly disconnect when done:

```swift
class AIViewController: UIViewController {
    private let client = TxClient()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            client.disconnect()
            client.delegate = nil
        }
    }
}
```

## Security Considerations

- Anonymous login is designed for AI assistant interactions only
- Target IDs should be validated on your backend
- Consider implementing session timeouts for security
- User variables should not contain sensitive information

## Next Steps

After successful anonymous login:

1. **[Start Conversations](starting-conversations.md)** - Learn how to initiate calls with AI assistants
2. **[Handle Transcripts](transcript-updates.md)** - Process real-time conversation transcripts
3. **[Send Messages](text-messaging.md)** - Implement text messaging during calls

## Related Documentation

- [TxClient](../classes/TxClient.md) - Complete client API reference
- [TxServerConfiguration](../structs/TxServerConfiguration.md) - Server configuration options
- [TxError](../enums/TxError.md) - Error handling reference