# Anonymous Connection for AI Agents

## Overview

The `anonymousLogin` method allows you to connect to AI assistants without traditional authentication credentials. This is the first step in establishing communication with a Telnyx AI Agent.

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

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `targetId` | String | Yes | - | The ID of your AI assistant |
| `targetType` | String | No | "ai_assistant" | The type of target |
| `targetVersionId` | String? | No | nil | Optional version ID of the target. If not provided, uses latest version |
| `userVariables` | [String: Any] | No | [:] | Optional user variables to include |
| `reconnection` | Bool | No | false | Whether this is a reconnection attempt |
| `serverConfiguration` | TxServerConfiguration | No | TxServerConfiguration() | Server configuration (signaling server URL and STUN/TURN servers) |

### TxServerConfiguration Properties

| Property | Type | Description |
|----------|------|-------------|
| `signalingServer` | URL? | Custom signaling server URL (e.g., `wss://your-server.com`) |
| `webRTCIceServers` | [RTCIceServer]? | Custom STUN/TURN servers for WebRTC connections |

## Usage Example

```swift
do {
    client.anonymousLogin(
        targetId: "your_assistant_id",
        // targetType: "ai_assistant", // This is the default value
        // targetVersionId: "your_assistant_version_id", // Optional
        // userVariables: ["user_id": "12345"], // Optional user variables
    )
    // You are now connected and can make a call to the AI Assistant.
} catch {
    // Handle connection error
    print("Connection failed: \(error.localizedDescription)")
}
```

## Advanced Usage

### With User Variables

```swift
client.anonymousLogin(
    targetId: "your_assistant_id",
    userVariables: [
        "user_id": "12345",
        "session_context": "support_chat",
        "language": "en-US"
    ]
)
```

### With Version Control

```swift
client.anonymousLogin(
    targetId: "your_assistant_id",
    targetVersionId: "v1.2.0" // Use specific version
)
```

### With Custom Server Configuration

```swift
import WebRTC

// Example 1: Custom signaling server only
let customSignalingServer = URL(string: "wss://your-custom-signaling-server.com")!
let config1 = TxServerConfiguration(signalingServer: customSignalingServer)

client.anonymousLogin(
    targetId: "your_assistant_id",
    serverConfiguration: config1
)

// Example 2: Custom STUN/TURN servers only
let stunServer = RTCIceServer(urlStrings: ["stun:stun.example.com:3478"])
let turnServer = RTCIceServer(
    urlStrings: ["turn:turn.example.com:3478?transport=tcp"],
    username: "your-username",
    credential: "your-password"
)
let config2 = TxServerConfiguration(webRTCIceServers: [stunServer, turnServer])

client.anonymousLogin(
    targetId: "your_assistant_id",
    serverConfiguration: config2
)

// Example 3: Full custom configuration (signaling server + STUN/TURN)
let customConfig = TxServerConfiguration(
    signalingServer: customSignalingServer,
    webRTCIceServers: [stunServer, turnServer]
)

client.anonymousLogin(
    targetId: "your_assistant_id",
    serverConfiguration: customConfig
)
```

## Important Notes

- **Call Routing**: After a successful anonymous connection, any subsequent call, regardless of the destination, will be directed to the specified AI Assistant
- **Session Lock**: The session becomes locked to the AI assistant until disconnection
- **Version Control**: If `targetVersionId` is not provided, the SDK will use the latest available version
- **Error Handling**: Monitor delegate callbacks for authentication errors
- **Server Configuration**: You can customize:
  - **Signaling Server**: Custom WebSocket server URL for SIP signaling (e.g., `wss://your-server.com`)
  - **ICE Servers**: Custom STUN/TURN servers for NAT traversal and media relay
- **Default Configuration**: If no custom configuration is provided, the SDK uses Telnyx's default servers

## Delegate Response Handling

Listen for connection responses using the delegate methods:

```swift
extension YourViewController: TxClientDelegate {
    func onClientReady() {
        // Handle successful anonymous connection
        print("Anonymous connection successful")
    }

    func onClientError(error: Error) {
        // Handle connection errors
        print("Connection error: \(error.localizedDescription)")
    }

    func onSocketDisconnected() {
        print("Disconnected from AI assistant")
    }
}
```

## Error Handling

Common errors you might encounter:

```swift
func onClientError(error: Error) {
    if let txError = error as? TxError {
        switch txError {
        case .socketFailure:
            print("Invalid assistant ID or authentication failed")
        case .clientConfigurationFailure:
            print("Network connection failed")
        default:
            print("Unexpected error: \(txError)")
        }
    }
}
```

## Next Steps

After successful anonymous connection:
1. [Start a conversation](https://developers.telnyx.com/development/webrtc/ios-sdk/ai-agent/starting-conversations) using `newInvite()`
2. [Set up transcript updates](https://developers.telnyx.com/development/webrtc/ios-sdk/ai-agent/transcript-updates) to receive real-time conversation data
3. [Send text messages](https://developers.telnyx.com/development/webrtc/ios-sdk/ai-agent/text-messaging) during active calls
