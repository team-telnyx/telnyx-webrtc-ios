# Starting Conversations with AI Assistants

## Overview

After a successful `anonymousLogin`, you can initiate calls to your AI Assistant using the standard `newCall` method. The session is locked to the AI Assistant, so the destination parameter is ignored.

## Method Usage

```swift
try client.newCall(
    callerName: String, // Display name (passed to AI assistant)
    callerNumber: String, // Caller number (passed to AI assistant)
    destinationNumber: String, // Ignored after anonymous login. All calls will be routed to the AI assistant
    callId: UUID, // Unique identifier for the call
    clientState: String? = nil, // Optional custom state information for your application
    customHeaders: [String: String] = [:] // Optional SIP headers to pass context to the AI assistant in the form of dynamic variables
)
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `callerName` | String | Your display name (passed to AI assistant) |
| `callerNumber` | String | Your phone number (passed to AI assistant) |
| `destinationNumber` | String | Ignored after anonymous login - can be empty string |
| `callId` | UUID | Unique identifier for the call |
| `clientState` | String? | Optional custom state information for your application |
| `customHeaders` | [String: String] | Optional SIP headers to pass context to the AI assistant (mapped to [dynamic variables](https://developers.telnyx.com/docs/inference/ai-assistants/dynamic-variables)) |

Note that you can also provide `customHeaders` in the `newCall` method. These headers need to start with the `X-` prefix and will be mapped to [dynamic variables](https://developers.telnyx.com/docs/inference/ai-assistants/dynamic-variables) in the AI assistant (e.g., `X-Account-Number` becomes `{{account_number}}`). Hyphens in header names are converted to underscores in variable names.

## Usage Example

```swift
// After a successful anonymousLogin...

do {
    let call = try client.newCall(
        callerName: "John Doe",
        callerNumber: "+1234567890",
        destinationNumber: "", // Destination is ignored, can be empty
        callId: UUID(),
        clientState: "ai_conversation_session",
        customHeaders: [
            "X-Session-Context": "support_request",
            "X-User-Tier": "premium"
        ]
    )
} catch {
    print("Failed to start call: \(error)")
}
```

## Complete Flow Example

```swift
class AIAssistantManager {
    private let client = TxClient()
    private var currentCall: Call?

    init() {
        client.delegate = self
    }

    func startAIConversation(assistantId: String) {
        // Step 1: Anonymous login
        client.anonymousLogin(targetId: assistantId)
    }

    private func startCall() {
        do {
            currentCall = try client.newCall(
                callerName: "Customer",
                callerNumber: "+1234567890",
                destinationNumber: "", // Ignored
                callId: UUID(),
                clientState: "ai_session",
                customHeaders: [
                    "X-Session-Context": "customer_support",
                    "X-User-Tier": "premium"
                ]
            )
        } catch {
            print("Failed to start call: \(error)")
        }
    }
}

extension AIAssistantManager: TxClientDelegate {
    func onClientReady() {
        // Login successful, start the call
        startCall()
    }

    func onCallStateUpdated(callState: CallState, callId: UUID) {
        guard currentCall?.callId == callId else { return }

        switch callState {
        case .NEW:
            print("Call invitation sent")
        case .RINGING:
            print("AI Assistant ringing...")
        case .ACTIVE:
            print("Connected to AI Assistant")
            // Start listening for transcripts
        case .DONE:
            print("AI conversation ended")
        default:
            break
        }
    }
}
```

## Important Notes

- **Automatic Answer**: AI assistants automatically answer calls - no manual answer required
- **Destination Ignored**: The `destinationNumber` parameter is ignored after anonymous login
- **Call Routing**: All calls are routed to the AI assistant specified during login
- **Standard Controls**: Use existing call management methods (mute, hold, end call)
- **Custom Headers**: You can pass custom SIP headers to provide context to the AI assistant. They will be mapped to [dynamic variables](https://developers.telnyx.com/docs/inference/ai-assistants/dynamic-variables) in the portal. Hyphens in header names are converted to underscores in variable names, e.g. `X-Session-Context` header maps to `{{session_context}}` variable.

## Call State Management

Monitor call states as you would with regular calls:

```swift
func onCallStateUpdated(callState: CallState, callId: UUID) {
    guard currentCall?.callId == callId else { return }

    switch callState {
    case .NEW:
        print("Calling AI Assistant...")
    case .RINGING:
        print("AI Assistant ringing...")
    case .ACTIVE:
        print("Connected to AI Assistant")
        // Start listening for transcripts
        setupTranscriptListener()
    case .DONE:
        print("AI conversation ended")
    default:
        break
    }
}
```

## Error Handling

Handle call-related errors:

```swift
func onClientError(error: Error) {
    if let txError = error as? TxError {
        switch txError {
        case .callFailure:
            print("Failed to start conversation with AI Assistant")
        default:
            print("Call error: \(txError)")
        }
    }
}
```

## Call Management

Once connected, use standard call management methods:

```swift
// Get the active call
guard let activeCall = currentCall else { return }

// Mute/unmute
activeCall.muteUnmute()

// Hold/unhold
activeCall.holdUnhold()

// End call
activeCall.hangup()
```

## Next Steps

After starting a conversation:
1. [Set up transcript updates](https://developers.telnyx.com/development/webrtc/ios-sdk/ai-agent/transcript-updates) to receive real-time conversation data
2. [Send text messages](https://developers.telnyx.com/development/webrtc/ios-sdk/ai-agent/text-messaging) during the active call
3. Use standard call controls for mute, hold, and end call operations
