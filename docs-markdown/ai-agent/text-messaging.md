# Text Messaging

Text messaging enables mixed-mode communication during AI assistant calls, allowing users to send text messages while maintaining voice conversation. This creates a rich, multi-modal interaction experience.

## Overview

The text messaging feature allows you to:

- **Send text messages** during active voice calls
- **Receive AI responses** via both voice and text
- **Maintain conversation context** across voice and text
- **Handle mixed communication flows** seamlessly

## Basic Text Messaging

### Simple Message Sending

```swift
import TelnyxRTC

class MixedModeConversationController: UIViewController {
    private let client = TxClient()
    private var activeCall: Call?
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAIConnection()
    }
    
    private func setupAIConnection() {
        client.delegate = self
        client.anonymousLogin(targetId: "your-ai-assistant-id")
    }
    
    @IBAction func sendMessageTapped(_ sender: UIButton) {
        sendTextMessage()
    }
    
    private func sendTextMessage() {
        guard let message = messageTextField.text, !message.isEmpty else {
            showAlert("Please enter a message")
            return
        }
        
        let success = client.sendAIAssistantMessage(message)
        
        if success {
            print("Message sent: \(message)")
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
}

extension MixedModeConversationController: TxClientDelegate {
    func onClientReady() {
        startVoiceConversation()
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        if callState == .ACTIVE {
            enableTextMessaging()
        } else if callState == .DONE {
            disableTextMessaging()
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

## Advanced Text Messaging

### Message Queue and Retry Logic

```swift
class ReliableTextMessaging {
    private let client: TxClient
    private var messageQueue: [PendingMessage] = []
    private var isProcessingQueue = false
    
    struct PendingMessage {
        let id: UUID
        let text: String
        let timestamp: Date
        var retryCount: Int = 0
    }
    
    init(client: TxClient) {
        self.client = client
    }
    
    func sendMessage(_ text: String) {
        let message = PendingMessage(
            id: UUID(),
            text: text,
            timestamp: Date()
        )
        
        messageQueue.append(message)
        processMessageQueue()
    }
    
    private func processMessageQueue() {
        guard !isProcessingQueue, !messageQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        let message = messageQueue.first!
        let success = client.sendAIAssistantMessage(message.text)
        
        if success {
            // Message sent successfully
            messageQueue.removeFirst()
            onMessageSent(message)
        } else {
            // Retry logic
            messageQueue[0].retryCount += 1
            
            if messageQueue[0].retryCount < 3 {
                // Retry after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.isProcessingQueue = false
                    self.processMessageQueue()
                }
                return
            } else {
                // Max retries reached
                messageQueue.removeFirst()
                onMessageFailed(message)
            }
        }
        
        isProcessingQueue = false
        
        // Process next message
        if !messageQueue.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.processMessageQueue()
            }
        }
    }
    
    private func onMessageSent(_ message: PendingMessage) {
        print("Message sent successfully: \(message.text)")
        // Update UI to show message as sent
    }
    
    private func onMessageFailed(_ message: PendingMessage) {
        print("Failed to send message after \(message.retryCount) retries: \(message.text)")
        // Update UI to show message as failed
    }
}
```

### Rich Message Types

```swift
class RichTextMessaging {
    private let client: TxClient
    
    enum MessageType {
        case text(String)
        case command(String, parameters: [String: Any])
        case contextUpdate([String: Any])
    }
    
    func sendMessage(_ messageType: MessageType) {
        let messageText: String
        
        switch messageType {
        case .text(let text):
            messageText = text
            
        case .command(let command, let parameters):
            messageText = formatCommand(command, parameters: parameters)
            
        case .contextUpdate(let context):
            messageText = formatContextUpdate(context)
        }
        
        let success = client.sendAIAssistantMessage(messageText)
        handleMessageResult(success, messageType: messageType)
    }
    
    private func formatCommand(_ command: String, parameters: [String: Any]) -> String {
        // Format command with parameters
        let paramString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        return "/\(command)?\(paramString)"
    }
    
    private func formatContextUpdate(_ context: [String: Any]) -> String {
        // Format context update as JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: context),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        return "CONTEXT_UPDATE:\(jsonString)"
    }
    
    // Convenience methods
    func sendTextMessage(_ text: String) {
        sendMessage(.text(text))
    }
    
    func sendCommand(_ command: String, parameters: [String: Any] = [:]) {
        sendMessage(.command(command, parameters: parameters))
    }
    
    func updateContext(_ context: [String: Any]) {
        sendMessage(.contextUpdate(context))
    }
}
```

## Message State Management

Track message states for better user experience:

```swift
class MessageStateManager {
    private let client: TxClient
    private var messages: [ChatMessage] = []
    
    struct ChatMessage {
        let id: UUID
        let text: String
        let isUser: Bool
        let timestamp: Date
        var state: MessageState
        
        enum MessageState {
            case sending
            case sent
            case failed
            case received
        }
    }
    
    func sendMessage(_ text: String) -> UUID {
        let messageId = UUID()
        let message = ChatMessage(
            id: messageId,
            text: text,
            isUser: true,
            timestamp: Date(),
            state: .sending
        )
        
        messages.append(message)
        updateUI()
        
        // Send message
        let success = client.sendAIAssistantMessage(text)
        updateMessageState(messageId, state: success ? .sent : .failed)
        
        return messageId
    }
    
    func addReceivedMessage(_ text: String) {
        let message = ChatMessage(
            id: UUID(),
            text: text,
            isUser: false,
            timestamp: Date(),
            state: .received
        )
        
        messages.append(message)
        updateUI()
    }
    
    private func updateMessageState(_ messageId: UUID, state: ChatMessage.MessageState) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        messages[index].state = state
        updateUI()
    }
    
    private func updateUI() {
        DispatchQueue.main.async {
            // Update conversation UI with message states
            self.refreshConversationView()
        }
    }
}
```

## Integration with Voice Transcripts

Combine text messages with voice transcripts for complete conversation history:

```swift
class UnifiedConversationManager {
    private let client: TxClient
    private var conversationItems: [ConversationItem] = []
    private var transcriptCancellable: TranscriptCancellable?
    
    enum ConversationItem {
        case voiceTranscript(TranscriptionItem)
        case textMessage(String, isUser: Bool, timestamp: Date)
    }
    
    func startConversation() {
        // Subscribe to voice transcripts
        transcriptCancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { [weak self] transcripts in
            self?.handleTranscriptUpdate(transcripts)
        }
    }
    
    func sendTextMessage(_ text: String) {
        // Add to conversation
        let item = ConversationItem.textMessage(text, isUser: true, timestamp: Date())
        conversationItems.append(item)
        
        // Send message
        let success = client.sendAIAssistantMessage(text)
        
        if success {
            updateConversationUI()
        } else {
            // Handle failure
            showMessageFailure()
        }
    }
    
    private func handleTranscriptUpdate(_ transcripts: [TranscriptionItem]) {
        // Convert transcripts to conversation items
        let newTranscriptItems = transcripts.map { ConversationItem.voiceTranscript($0) }
        
        // Merge with existing conversation, maintaining chronological order
        let allItems = conversationItems + newTranscriptItems
        conversationItems = allItems.sorted { item1, item2 in
            return getTimestamp(item1) < getTimestamp(item2)
        }
        
        DispatchQueue.main.async {
            self.updateConversationUI()
        }
    }
    
    private func getTimestamp(_ item: ConversationItem) -> Date {
        switch item {
        case .voiceTranscript(let transcript):
            return transcript.timestamp
        case .textMessage(_, _, let timestamp):
            return timestamp
        }
    }
    
    private func updateConversationUI() {
        // Update UI with unified conversation
        conversationTableView.reloadData()
        scrollToBottom()
    }
}
```

## UI Components for Text Messaging

### Message Input View

```swift
class MessageInputView: UIView {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var characterCountLabel: UILabel!
    
    private let maxCharacters = 500
    var onMessageSent: ((String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        sendButton.isEnabled = false
        updateCharacterCount()
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let text = textField.text, !text.isEmpty else { return }
        
        onMessageSent?(text)
        textField.text = ""
        textFieldDidChange()
    }
    
    @objc private func textFieldDidChange() {
        let text = textField.text ?? ""
        sendButton.isEnabled = !text.isEmpty && text.count <= maxCharacters
        updateCharacterCount()
    }
    
    private func updateCharacterCount() {
        let count = textField.text?.count ?? 0
        characterCountLabel.text = "\(count)/\(maxCharacters)"
        characterCountLabel.textColor = count > maxCharacters ? .red : .gray
    }
}

extension MessageInputView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        return newLength <= maxCharacters
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if sendButton.isEnabled {
            sendButtonTapped(sendButton)
        }
        return true
    }
}
```

### Message Bubble View

```swift
class MessageBubbleView: UIView {
    private let messageLabel = UILabel()
    private let timestampLabel = UILabel()
    private let statusIndicator = UIImageView()
    
    enum MessageStatus {
        case sending
        case sent
        case failed
        case received
    }
    
    func configure(text: String, isUser: Bool, timestamp: Date, status: MessageStatus) {
        setupLayout(isUser: isUser)
        
        messageLabel.text = text
        timestampLabel.text = formatTimestamp(timestamp)
        updateStatusIndicator(status)
        
        backgroundColor = isUser ? UIColor.systemBlue : UIColor.systemGray5
        messageLabel.textColor = isUser ? .white : .label
    }
    
    private func setupLayout(isUser: Bool) {
        // Configure layout based on user/assistant
        // User messages: right-aligned, blue
        // Assistant messages: left-aligned, gray
    }
    
    private func updateStatusIndicator(_ status: MessageStatus) {
        switch status {
        case .sending:
            statusIndicator.image = UIImage(systemName: "clock")
            statusIndicator.tintColor = .gray
        case .sent:
            statusIndicator.image = UIImage(systemName: "checkmark")
            statusIndicator.tintColor = .green
        case .failed:
            statusIndicator.image = UIImage(systemName: "exclamationmark.triangle")
            statusIndicator.tintColor = .red
        case .received:
            statusIndicator.isHidden = true
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
```

## Error Handling and Edge Cases

Handle various error scenarios:

```swift
class RobustTextMessaging {
    private let client: TxClient
    
    func sendMessage(_ text: String, completion: @escaping (Result<Void, MessagingError>) -> Void) {
        // Validate message
        guard validateMessage(text) else {
            completion(.failure(.invalidMessage))
            return
        }
        
        // Check connection state
        guard client.isConnected else {
            completion(.failure(.notConnected))
            return
        }
        
        // Check if call is active
        guard hasActiveCall() else {
            completion(.failure(.noActiveCall))
            return
        }
        
        // Send message
        let success = client.sendAIAssistantMessage(text)
        
        if success {
            completion(.success(()))
        } else {
            completion(.failure(.sendFailed))
        }
    }
    
    private func validateMessage(_ text: String) -> Bool {
        // Check message length
        guard text.count > 0 && text.count <= 500 else { return false }
        
        // Check for prohibited content
        let prohibitedWords = ["spam", "abuse"] // Add your prohibited words
        let lowercaseText = text.lowercased()
        
        for word in prohibitedWords {
            if lowercaseText.contains(word) {
                return false
            }
        }
        
        return true
    }
    
    private func hasActiveCall() -> Bool {
        // Check if there's an active call for messaging
        return client.calls.contains { $0.callState == .ACTIVE }
    }
    
    enum MessagingError: Error, LocalizedError {
        case invalidMessage
        case notConnected
        case noActiveCall
        case sendFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidMessage:
                return "Message is invalid or too long"
            case .notConnected:
                return "Not connected to AI assistant"
            case .noActiveCall:
                return "No active call for messaging"
            case .sendFailed:
                return "Failed to send message"
            }
        }
    }
}
```

## Best Practices

### 1. Message Validation

Always validate messages before sending:

```swift
func validateAndSendMessage(_ text: String) -> Bool {
    // Trim whitespace
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Check length
    guard trimmedText.count > 0 && trimmedText.count <= 500 else {
        showAlert("Message must be between 1 and 500 characters")
        return false
    }
    
    // Send message
    return client.sendAIAssistantMessage(trimmedText)
}
```

### 2. User Feedback

Provide clear feedback for message states:

```swift
func sendMessageWithFeedback(_ text: String) {
    // Show sending state
    showMessageSending()
    
    let success = client.sendAIAssistantMessage(text)
    
    if success {
        showMessageSent()
    } else {
        showMessageFailed()
    }
}
```

### 3. Rate Limiting

Implement rate limiting to prevent spam:

```swift
class RateLimitedMessaging {
    private var lastMessageTime: Date?
    private let minimumInterval: TimeInterval = 1.0 // 1 second between messages
    
    func canSendMessage() -> Bool {
        guard let lastTime = lastMessageTime else { return true }
        return Date().timeIntervalSince(lastTime) >= minimumInterval
    }
    
    func sendMessage(_ text: String) -> Bool {
        guard canSendMessage() else {
            showAlert("Please wait before sending another message")
            return false
        }
        
        let success = client.sendAIAssistantMessage(text)
        
        if success {
            lastMessageTime = Date()
        }
        
        return success
    }
}
```

## Integration Examples

### Complete Mixed-Mode Chat

```swift
class MixedModeChatViewController: UIViewController {
    private let client = TxClient()
    private let messageManager = MessageStateManager()
    private var activeCall: Call?
    
    @IBOutlet weak var conversationTableView: UITableView!
    @IBOutlet weak var messageInputView: MessageInputView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChat()
    }
    
    private func setupChat() {
        client.delegate = self
        messageInputView.onMessageSent = { [weak self] text in
            self?.sendTextMessage(text)
        }
        
        // Start AI connection
        client.anonymousLogin(targetId: "chat-ai-assistant")
    }
    
    private func sendTextMessage(_ text: String) {
        let messageId = messageManager.sendMessage(text)
        updateConversationUI()
    }
    
    private func startVoiceCall() {
        activeCall = client.newInvite(
            callerName: "User",
            callerNumber: "user",
            destinationNumber: "ai",
            callId: UUID()
        )
    }
}

extension MixedModeChatViewController: TxClientDelegate {
    func onClientReady() {
        startVoiceCall()
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        switch callState {
        case .ACTIVE:
            enableMixedMode()
        case .DONE:
            disableMixedMode()
        default:
            break
        }
    }
    
    private func enableMixedMode() {
        messageInputView.isEnabled = true
        // Start transcript monitoring
        subscribeToTranscripts()
    }
    
    private func disableMixedMode() {
        messageInputView.isEnabled = false
    }
}
```

## Next Steps

After implementing text messaging:

1. **[Widget Settings](../structs/WidgetSettings.md)** - Customize the AI assistant interface
2. **[Call Management](../classes/Call.md)** - Handle call controls and states
3. **[Error Handling](../error-handling/error-handling.md)** - Implement comprehensive error handling

## Related Documentation

- [AIAssistantManager](../classes/AIAssistantManager.md) - AI assistant management
- [TxClient](../classes/TxClient.md) - Main client API reference
- [Transcript Updates](transcript-updates.md) - Voice transcript handling
- [Starting Conversations](starting-conversations.md) - Call initiation