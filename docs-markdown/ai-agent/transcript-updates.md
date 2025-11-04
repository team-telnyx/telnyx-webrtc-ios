# Transcript Updates

Real-time transcript updates provide live conversation transcripts during AI assistant calls. The iOS SDK offers multiple ways to receive and process these updates with role identification and partial response handling.

## Overview

The transcript system captures both user speech and AI assistant responses in real-time, providing:

- **Role-based identification** (user/assistant)
- **Partial and final transcripts** for responsive UI updates
- **Custom publisher system** compatible with iOS 12.0+
- **Multiple subscription methods** for different use cases

## Core Components

### TranscriptionItem Structure

```swift
public struct TranscriptionItem {
    public let id: String
    public let role: String          // "user" or "assistant"
    public let content: String       // Transcript text
    public let isPartial: Bool       // true for in-progress, false for final
    public let timestamp: Date       // When the transcript was created
    public let confidence: Double?   // Speech recognition confidence (0.0-1.0)
    public let itemType: String?     // Type of transcript item
    public let metadata: [String: Any]? // Additional metadata
}
```

## Subscription Methods

### 1. Full Transcript Updates

Subscribe to receive the complete transcript array on each update:

```swift
import TelnyxRTC

class TranscriptViewController: UIViewController {
    private let client = TxClient()
    private var transcriptCancellable: TranscriptCancellable?
    private var transcripts: [TranscriptionItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTranscriptMonitoring()
    }
    
    private func setupTranscriptMonitoring() {
        transcriptCancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { [weak self] transcripts in
            DispatchQueue.main.async {
                self?.handleTranscriptUpdate(transcripts)
            }
        }
    }
    
    private func handleTranscriptUpdate(_ transcripts: [TranscriptionItem]) {
        self.transcripts = transcripts
        updateTranscriptUI()
        
        // Process latest transcript
        if let latest = transcripts.last {
            print("Latest: [\(latest.role)] \(latest.content)")
            
            if latest.isPartial {
                showPartialIndicator()
            } else {
                hidePartialIndicator()
            }
        }
    }
    
    private func updateTranscriptUI() {
        // Update your UI with the complete transcript
        transcriptTableView.reloadData()
        scrollToBottom()
    }
    
    deinit {
        transcriptCancellable?.cancel()
    }
}
```

### 2. Individual Item Updates

Subscribe to receive individual transcript items as they arrive:

```swift
class StreamingTranscriptView: UIView {
    private var itemCancellable: TranscriptCancellable?
    
    func startListening(to client: TxClient) {
        itemCancellable = client.aiAssistantManager.subscribeToTranscriptItemUpdates { [weak self] item in
            DispatchQueue.main.async {
                self?.handleNewTranscriptItem(item)
            }
        }
    }
    
    private func handleNewTranscriptItem(_ item: TranscriptionItem) {
        print("New item: [\(item.role)] \(item.content) (partial: \(item.isPartial))")
        
        if item.isPartial {
            updatePartialTranscript(item)
        } else {
            addFinalTranscript(item)
        }
    }
    
    private func updatePartialTranscript(_ item: TranscriptionItem) {
        // Update the current partial transcript in UI
        // This provides real-time feedback as the user speaks
    }
    
    private func addFinalTranscript(_ item: TranscriptionItem) {
        // Add the final transcript to the conversation
        // This is the completed, processed version
    }
    
    deinit {
        itemCancellable?.cancel()
    }
}
```

## Role-Based Processing

Handle different roles (user vs assistant) appropriately:

```swift
class ConversationManager {
    private let client = TxClient()
    private var userTranscripts: [TranscriptionItem] = []
    private var assistantTranscripts: [TranscriptionItem] = []
    
    func startMonitoring() {
        client.aiAssistantManager.subscribeToTranscriptUpdates { [weak self] transcripts in
            self?.processTranscriptsByRole(transcripts)
        }
    }
    
    private func processTranscriptsByRole(_ transcripts: [TranscriptionItem]) {
        userTranscripts = transcripts.filter { $0.role == "user" }
        assistantTranscripts = transcripts.filter { $0.role == "assistant" }
        
        DispatchQueue.main.async {
            self.updateConversationUI()
        }
    }
    
    private func updateConversationUI() {
        // Update UI with role-specific styling
        for transcript in userTranscripts {
            addUserMessage(transcript)
        }
        
        for transcript in assistantTranscripts {
            addAssistantMessage(transcript)
        }
    }
    
    private func addUserMessage(_ transcript: TranscriptionItem) {
        // Style user messages (e.g., right-aligned, blue background)
        let messageView = createMessageView(
            text: transcript.content,
            isUser: true,
            isPartial: transcript.isPartial
        )
        conversationView.addArrangedSubview(messageView)
    }
    
    private func addAssistantMessage(_ transcript: TranscriptionItem) {
        // Style assistant messages (e.g., left-aligned, gray background)
        let messageView = createMessageView(
            text: transcript.content,
            isUser: false,
            isPartial: transcript.isPartial
        )
        conversationView.addArrangedSubview(messageView)
    }
}
```

## Partial Transcript Handling

Handle partial transcripts for responsive user experience:

```swift
class PartialTranscriptHandler {
    private var currentPartialTranscript: TranscriptionItem?
    private var partialTranscriptTimer: Timer?
    
    func handleTranscriptItem(_ item: TranscriptionItem) {
        if item.isPartial {
            handlePartialTranscript(item)
        } else {
            handleFinalTranscript(item)
        }
    }
    
    private func handlePartialTranscript(_ item: TranscriptionItem) {
        currentPartialTranscript = item
        
        // Show typing indicator or partial text
        showPartialTranscript(item.content, role: item.role)
        
        // Reset timer for partial transcript timeout
        partialTranscriptTimer?.invalidate()
        partialTranscriptTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            self.hidePartialTranscript()
        }
    }
    
    private func handleFinalTranscript(_ item: TranscriptionItem) {
        // Clear any partial transcript
        currentPartialTranscript = nil
        partialTranscriptTimer?.invalidate()
        hidePartialTranscript()
        
        // Add final transcript to conversation
        addFinalTranscript(item)
    }
    
    private func showPartialTranscript(_ text: String, role: String) {
        // Show partial transcript with visual indicator
        let indicator = role == "user" ? "🎤" : "🤖"
        partialLabel.text = "\(indicator) \(text)..."
        partialLabel.isHidden = false
    }
    
    private func hidePartialTranscript() {
        partialLabel.isHidden = true
    }
}
```

## Advanced Filtering and Processing

### Filter by Role

```swift
extension AIAssistantManager {
    func getUserTranscripts() -> [TranscriptionItem] {
        return client.aiAssistantManager.getTranscriptionsByRole("user")
    }
    
    func getAssistantTranscripts() -> [TranscriptionItem] {
        return client.aiAssistantManager.getTranscriptionsByRole("assistant")
    }
    
    func getPartialTranscripts() -> [TranscriptionItem] {
        return client.aiAssistantManager.getPartialTranscripts()
    }
    
    func getFinalTranscripts() -> [TranscriptionItem] {
        return client.aiAssistantManager.getFinalTranscripts()
    }
}
```

### Confidence-Based Filtering

```swift
class ConfidenceBasedTranscriptProcessor {
    private let minimumConfidence: Double = 0.7
    
    func processTranscripts(_ transcripts: [TranscriptionItem]) {
        let highConfidenceTranscripts = transcripts.filter { transcript in
            guard let confidence = transcript.confidence else { return true }
            return confidence >= minimumConfidence
        }
        
        let lowConfidenceTranscripts = transcripts.filter { transcript in
            guard let confidence = transcript.confidence else { return false }
            return confidence < minimumConfidence
        }
        
        // Display high confidence transcripts normally
        displayTranscripts(highConfidenceTranscripts, style: .normal)
        
        // Display low confidence transcripts with warning
        displayTranscripts(lowConfidenceTranscripts, style: .lowConfidence)
    }
    
    private func displayTranscripts(_ transcripts: [TranscriptionItem], style: DisplayStyle) {
        for transcript in transcripts {
            let messageView = createMessageView(transcript, style: style)
            conversationView.addArrangedSubview(messageView)
        }
    }
}
```

## Real-Time UI Updates

Create responsive UI that updates in real-time:

```swift
class LiveTranscriptView: UIView {
    @IBOutlet weak var conversationTableView: UITableView!
    @IBOutlet weak var partialTranscriptLabel: UILabel!
    @IBOutlet weak var typingIndicator: UIActivityIndicatorView!
    
    private var transcripts: [TranscriptionItem] = []
    private var currentPartial: TranscriptionItem?
    
    func subscribeToTranscripts(client: TxClient) {
        client.aiAssistantManager.subscribeToTranscriptItemUpdates { [weak self] item in
            DispatchQueue.main.async {
                self?.handleTranscriptItem(item)
            }
        }
    }
    
    private func handleTranscriptItem(_ item: TranscriptionItem) {
        if item.isPartial {
            updatePartialTranscript(item)
        } else {
            addFinalTranscript(item)
        }
    }
    
    private func updatePartialTranscript(_ item: TranscriptionItem) {
        currentPartial = item
        partialTranscriptLabel.text = item.content
        partialTranscriptLabel.isHidden = false
        
        if item.role == "assistant" {
            typingIndicator.startAnimating()
        }
    }
    
    private func addFinalTranscript(_ item: TranscriptionItem) {
        // Clear partial state
        currentPartial = nil
        partialTranscriptLabel.isHidden = true
        typingIndicator.stopAnimating()
        
        // Add to transcripts and update table
        transcripts.append(item)
        
        let indexPath = IndexPath(row: transcripts.count - 1, section: 0)
        conversationTableView.insertRows(at: [indexPath], with: .fade)
        conversationTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension LiveTranscriptView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcripts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let transcript = transcripts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TranscriptCell", for: indexPath) as! TranscriptCell
        
        cell.configure(with: transcript)
        return cell
    }
}
```

## Error Handling and Edge Cases

Handle various edge cases and errors:

```swift
class RobustTranscriptHandler {
    private let client: TxClient
    private var transcriptCancellable: TranscriptCancellable?
    private var lastTranscriptTime: Date?
    
    init(client: TxClient) {
        self.client = client
    }
    
    func startMonitoring() {
        transcriptCancellable = client.aiAssistantManager.subscribeToTranscriptUpdates { [weak self] transcripts in
            self?.handleTranscriptsWithErrorHandling(transcripts)
        }
    }
    
    private func handleTranscriptsWithErrorHandling(_ transcripts: [TranscriptionItem]) {
        guard !transcripts.isEmpty else {
            print("Received empty transcript array")
            return
        }
        
        // Check for transcript gaps
        if let lastTime = lastTranscriptTime {
            let timeSinceLastTranscript = Date().timeIntervalSince(lastTime)
            if timeSinceLastTranscript > 30.0 {
                print("Warning: Large gap in transcripts (\(timeSinceLastTranscript)s)")
            }
        }
        
        // Validate transcript items
        let validTranscripts = transcripts.filter { transcript in
            return validateTranscript(transcript)
        }
        
        if validTranscripts.count != transcripts.count {
            print("Warning: Filtered out \(transcripts.count - validTranscripts.count) invalid transcripts")
        }
        
        // Process valid transcripts
        DispatchQueue.main.async {
            self.processValidTranscripts(validTranscripts)
        }
        
        lastTranscriptTime = Date()
    }
    
    private func validateTranscript(_ transcript: TranscriptionItem) -> Bool {
        // Validate required fields
        guard !transcript.id.isEmpty,
              !transcript.role.isEmpty,
              !transcript.content.isEmpty else {
            print("Invalid transcript: missing required fields")
            return false
        }
        
        // Validate role
        guard ["user", "assistant"].contains(transcript.role) else {
            print("Invalid transcript: unknown role '\(transcript.role)'")
            return false
        }
        
        return true
    }
    
    private func processValidTranscripts(_ transcripts: [TranscriptionItem]) {
        // Process transcripts safely
        for transcript in transcripts {
            processTranscript(transcript)
        }
    }
}
```

## Performance Optimization

Optimize for large conversations:

```swift
class OptimizedTranscriptManager {
    private var transcripts: [TranscriptionItem] = []
    private let maxTranscripts = 1000
    private var transcriptCache: [String: TranscriptionItem] = [:]
    
    func handleTranscriptUpdate(_ newTranscripts: [TranscriptionItem]) {
        // Implement efficient diffing
        let newItems = newTranscripts.filter { transcript in
            return transcriptCache[transcript.id] == nil
        }
        
        // Add new items to cache
        for item in newItems {
            transcriptCache[item.id] = item
        }
        
        // Maintain transcript limit
        if transcripts.count > maxTranscripts {
            let itemsToRemove = transcripts.count - maxTranscripts
            let removedItems = Array(transcripts.prefix(itemsToRemove))
            
            // Remove from cache
            for item in removedItems {
                transcriptCache.removeValue(forKey: item.id)
            }
            
            // Remove from array
            transcripts.removeFirst(itemsToRemove)
        }
        
        // Update UI efficiently
        updateUIWithNewItems(newItems)
    }
    
    private func updateUIWithNewItems(_ newItems: [TranscriptionItem]) {
        guard !newItems.isEmpty else { return }
        
        // Batch UI updates
        conversationTableView.performBatchUpdates {
            let startIndex = transcripts.count
            transcripts.append(contentsOf: newItems)
            
            let indexPaths = newItems.enumerated().map { index, _ in
                IndexPath(row: startIndex + index, section: 0)
            }
            
            conversationTableView.insertRows(at: indexPaths, with: .fade)
        }
    }
}
```

## Best Practices

### 1. Memory Management

Always cancel subscriptions to prevent memory leaks:

```swift
class TranscriptViewController: UIViewController {
    private var cancellables: [TranscriptCancellable] = []
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            cancellables.forEach { $0.cancel() }
            cancellables.removeAll()
        }
    }
}
```

### 2. Thread Safety

Always update UI on the main thread:

```swift
client.aiAssistantManager.subscribeToTranscriptUpdates { transcripts in
    DispatchQueue.main.async {
        self.updateUI(with: transcripts)
    }
}
```

### 3. Efficient Updates

Use efficient UI update patterns:

```swift
// Good: Batch updates
conversationTableView.performBatchUpdates {
    // Multiple insertions
}

// Avoid: Individual updates in loop
for transcript in transcripts {
    conversationTableView.insertRows(at: [indexPath], with: .none) // Don't do this
}
```

## Next Steps

After implementing transcript monitoring:

1. **[Text Messaging](text-messaging.md)** - Add text message capabilities
2. **[Widget Settings](../structs/WidgetSettings.md)** - Customize AI assistant interface
3. **[Call Management](../classes/Call.md)** - Handle call controls and states

## Related Documentation

- [AIAssistantManager](../classes/AIAssistantManager.md) - Complete transcript API reference
- [TranscriptionItem](../structs/TranscriptionItem.md) - Transcript data structure
- [TranscriptPublisher](../classes/TranscriptPublisher.md) - Custom publisher implementation