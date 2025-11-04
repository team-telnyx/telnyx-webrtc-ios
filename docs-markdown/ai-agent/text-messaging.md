# Sending Text Messages to AI Agents

## Overview

In addition to voice conversation, you can send text messages directly to the AI Agent during an active call. This allows for mixed-mode communication where users can both speak and type messages to the AI Assistant.

## Method Signature

```swift
func sendAIAssistantMessage(_ message: String) -> Bool
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `message` | String | The text message to send to the AI Assistant |

## Returns

`Bool` - Returns `true` if the message was sent successfully, `false` otherwise

## Basic Usage

```swift
// Send a text message to the AI Agent during an active call
let success = client.sendAIAssistantMessage("Hello, can you help me with my account?")

if success {
    print("Message sent successfully")
} else {
    print("Failed to send message")
}
```

## Complete Example

```swift
class AIConversationViewController: UIViewController {
    private let client = TxClient()
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMessageSending()
    }

    private func setupMessageSending() {
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }

    @objc private func sendButtonTapped() {
        guard let message = messageTextField.text, !message.isEmpty else {
            showAlert("Please enter a message")
            return
        }

        sendTextMessage(message)
    }

    private func sendTextMessage(_ message: String) {
        let success = client.sendAIAssistantMessage(message)

        if success {
            print("Text message sent: \(message)")
            messageTextField.text = ""
            addMessageToUI(message, isUser: true)
        } else {
            showAlert("Failed to send message. Check connection.")
        }
    }

    private func addMessageToUI(_ message: String, isUser: Bool) {
        // Add message to conversation UI
        let messageView = createMessageBubble(text: message, isUser: isUser)
        conversationStackView.addArrangedSubview(messageView)
        scrollToBottom()
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension AIConversationViewController: TxClientDelegate {
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        switch callState {
        case .ACTIVE:
            enableTextMessaging()
        case .DONE:
            disableTextMessaging()
        default:
            break
        }
    }

    private func enableTextMessaging() {
        messageTextField.isEnabled = true
        sendButton.isEnabled = true
    }

    private func disableTextMessaging() {
        messageTextField.isEnabled = false
        sendButton.isEnabled = false
    }
}
```

## Advanced Usage with Call State Checking

```swift
class AIMessageManager {
    private let client: TxClient

    init(client: TxClient) {
        self.client = client
    }

    func sendMessage(_ message: String) -> Bool {
        guard isAICallActive() else {
            print("Cannot send message: No active AI call")
            return false
        }

        return client.sendAIAssistantMessage(message)
    }

    private func isAICallActive() -> Bool {
        return client.calls.values.contains { $0.callState == .ACTIVE }
    }

    func sendMessageWithConfirmation(_ message: String, completion: @escaping (Bool) -> Void) {
        let success = sendMessage(message)
        completion(success)
    }
}
```

## Error Handling

```swift
private func sendTextMessageWithErrorHandling(_ message: String) {
    // Check if we have an active AI call
    guard hasActiveCall() else {
        showError("No active AI conversation. Please start a call first.")
        return
    }

    // Send the message
    let success = client.sendAIAssistantMessage(message)

    if success {
        showMessageSent(message)
    } else {
        showError("Failed to send message")
    }
}

private func hasActiveCall() -> Bool {
    return client.calls.values.contains { $0.callState == .ACTIVE }
}

private func showError(_ message: String) {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
}

private func showMessageSent(_ message: String) {
    print("Message sent successfully: \(message)")
}
```

## Important Notes

- **Active Call Required**: You must have an active call established before sending text messages
- **AI Assistant Only**: The `sendAIAssistantMessage` method is only available during AI Assistant conversations
- **Transcript Integration**: Text messages sent this way will appear in transcript updates alongside spoken conversation
- **Processing**: The AI Agent will process and respond to text messages just like spoken input
- **Mixed Communication**: Users can seamlessly switch between voice and text communication

## Best Practices

1. **Validate Input**: Always check that messages are not empty before sending
2. **Check Call State**: Verify an active AI call exists before sending messages
3. **User Feedback**: Provide visual feedback when messages are sent
4. **Error Handling**: Handle network errors and call state issues gracefully
5. **UI Updates**: Update the conversation UI immediately for better user experience

## Integration with Transcript Updates

Text messages will appear in the transcript updates:

```swift
cancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { [weak self] transcript in
    DispatchQueue.main.async {
        transcript.forEach { item in
            switch item.role {
            case "user":
                // This includes both spoken words and text messages
                self?.displayUserMessage(item.content, item.timestamp)
            case "assistant":
                // AI responses to both voice and text
                self?.displayAssistantMessage(item.content, item.timestamp)
            default:
                break
            }
        }
    }
}
```

This feature enables rich conversational experiences where users can seamlessly switch between voice and text communication with the AI Assistant.
