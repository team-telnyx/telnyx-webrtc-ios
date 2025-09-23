//
//  AIAssistantManager.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 29/07/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

/// Represents a transcription item from AI assistant conversations (Android-compatible)
public struct TranscriptionItem {
    // Core Android properties
    public let id: String
    public let role: String // "user" or "assistant"
    public let content: String // The transcribed text content
    public let isPartial: Bool // true if still recording, false if final
    public let timestamp: Date // When the transcription was created
    
    // Optional Android properties
    public let confidence: Double? // Confidence score (0.0 to 1.0)
    public let itemType: String? // Type of item (e.g., "message", "transcription", "text_message")
    public let metadata: [String: Any]? // Additional metadata for extensibility
    
    // Legacy iOS properties (computed for backward compatibility)
    public var speaker: String {
        return role
    }
    
    public var text: String {
        return content
    }
    
    public var isFinal: Bool {
        return !isPartial
    }
    
    // Android-style initializer (primary)
    public init(id: String = UUID().uuidString, role: String, content: String, isPartial: Bool = false, timestamp: Date = Date(), confidence: Double? = nil, itemType: String? = nil, metadata: [String: Any]? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.isPartial = isPartial
        self.timestamp = timestamp
        self.confidence = confidence
        self.itemType = itemType
        self.metadata = metadata
    }
    
    // Legacy iOS initializer (for backward compatibility)
    @available(*, deprecated, message: "Use Android-style initializer with role and content parameters")
    public init(id: String, timestamp: Date, speaker: String, text: String, confidence: Double? = nil, isFinal: Bool = true, itemType: String? = nil, metadata: [String: Any]? = nil) {
        self.id = id
        self.role = speaker
        self.content = text
        self.isPartial = !isFinal
        self.timestamp = timestamp
        self.confidence = confidence
        self.itemType = itemType
        self.metadata = metadata
    }
}

/// Represents widget settings for AI assistant interface
public struct WidgetSettings {
    public let theme: String?
    public let language: String?
    public let autoStart: Bool
    public let showTranscript: Bool
    public let customStyles: [String: Any]?
    
    // New fields based on the JSON message
    public let agentThinkingText: String
    public let audioVisualizerConfig: AudioVisualizerConfig?
    public let defaultState: String
    public let giveFeedbackUrl: String?
    public let logoIconUrl: String?
    public let position: String
    public let reportIssueUrl: String?
    public let speakToInterruptText: String
    public let startCallText: String
    public let viewHistoryUrl: String?
    
    public init(
        theme: String? = "dark",
        language: String? = nil,
        autoStart: Bool = false,
        showTranscript: Bool = true,
        customStyles: [String: Any]? = nil,
        agentThinkingText: String = "",
        audioVisualizerConfig: AudioVisualizerConfig? = nil,
        defaultState: String = "collapsed",
        giveFeedbackUrl: String? = nil,
        logoIconUrl: String? = nil,
        position: String = "fixed",
        reportIssueUrl: String? = nil,
        speakToInterruptText: String = "",
        startCallText: String = "",
        viewHistoryUrl: String? = nil
    ) {
        self.theme = theme
        self.language = language
        self.autoStart = autoStart
        self.showTranscript = showTranscript
        self.customStyles = customStyles
        self.agentThinkingText = agentThinkingText
        self.audioVisualizerConfig = audioVisualizerConfig
        self.defaultState = defaultState
        self.giveFeedbackUrl = giveFeedbackUrl
        self.logoIconUrl = logoIconUrl
        self.position = position
        self.reportIssueUrl = reportIssueUrl
        self.speakToInterruptText = speakToInterruptText
        self.startCallText = startCallText
        self.viewHistoryUrl = viewHistoryUrl
    }
}

/// Represents audio visualizer configuration
public struct AudioVisualizerConfig {
    public let color: String
    public let preset: String
    
    public init(color: String = "verdant", preset: String = "roundBars") {
        self.color = color
        self.preset = preset
    }
}

/// Protocol for AI Assistant Manager delegate to handle AI-related events
public protocol AIAssistantManagerDelegate: AnyObject {
    /// Called when an AI conversation message is received
    /// - Parameter message: The AI conversation message content
    func onAIConversationMessage(_ message: [String: Any])
    
    /// Called when a ringing acknowledgment is received for AI assistant calls
    /// - Parameter callId: The call ID that received the ringing acknowledgment
    func onRingingAckReceived(callId: String)
    
    /// Called when AI assistant connection state changes
    /// - Parameters:
    ///   - isConnected: Whether the AI assistant is connected
    ///   - targetId: The target ID of the AI assistant
    func onAIAssistantConnectionStateChanged(isConnected: Bool, targetId: String?)
    
    /// Called when transcription is updated
    /// - Parameter transcriptions: The updated list of transcription items
    func onTranscriptionUpdated(_ transcriptions: [TranscriptionItem])
    
    /// Called when widget settings are updated
    /// - Parameter settings: The updated widget settings
    func onWidgetSettingsUpdated(_ settings: WidgetSettings)
}

/// Manager class for handling AI Assistant functionality
/// This class manages AI assistant connections, message handling, and state management
public class AIAssistantManager {
    
    // MARK: - Properties
    
    /// Delegate to receive AI assistant events
    public weak var delegate: AIAssistantManagerDelegate?
    
    /// Current AI assistant connection state
    private var isConnected: Bool = false
    
    /// Current target ID for the connected AI assistant
    private var currentTargetId: String?
    
    /// Current target type (usually "ai_assistant")
    private var currentTargetType: String?
    
    /// Current target version ID
    private var currentTargetVersionId: String?
    
    /// List of transcription items from AI conversations
    private var transcriptions: [TranscriptionItem] = []
    
    /// Current widget settings for AI assistant interface
    private var widgetSettings: WidgetSettings?
    
    /// Logger instance for debugging
    private let logger = Logger.log
    
    // MARK: - Real-time Transcript Updates (Android compatibility)
    
    /// Custom publisher for real-time transcript updates (iOS 12.0 compatible)
    public private(set) var transcriptUpdatePublisher = TranscriptPublisher<[TranscriptionItem]>()
    
    /// Custom publisher for individual transcript item updates
    public private(set) var transcriptItemPublisher = TranscriptPublisher<TranscriptionItem>()
    
    /// Cancellable tokens for active subscriptions
    private var transcriptUpdateCancellables: [TranscriptCancellable] = []
    private var transcriptItemCancellables: [TranscriptCancellable] = []
    
    // MARK: - Initializers
    
    /// Initialize the AI Assistant Manager
    public init() {
        logger.i(message: "AIAssistantManager:: Initialized")
    }
    
    // MARK: - Public Methods
    
    /// Update the AI assistant connection state
    /// - Parameters:
    ///   - connected: Whether the AI assistant is connected
    ///   - targetId: The target ID of the AI assistant
    ///   - targetType: The target type (optional)
    ///   - targetVersionId: The target version ID (optional)
    public func updateConnectionState(
        connected: Bool,
        targetId: String?,
        targetType: String? = nil,
        targetVersionId: String? = nil
    ) {
        let wasConnected = self.isConnected
        self.isConnected = connected
        self.currentTargetId = targetId
        self.currentTargetType = targetType
        self.currentTargetVersionId = targetVersionId
        
        logger.i(message: "AIAssistantManager:: Connection state changed - connected: \(connected), targetId: \(targetId ?? "nil")")
        
        // Notify delegate if state changed
        if wasConnected != connected {
            delegate?.onAIAssistantConnectionStateChanged(isConnected: connected, targetId: targetId)
        }
    }
    
    /// Process incoming message to detect AI conversation content
    /// - Parameter message: The incoming message to process
    /// - Returns: True if the message was an AI conversation message, false otherwise
    public func processIncomingMessage(_ message: [String: Any]) -> Bool {
        // Check if this is an AI conversation message
        if isAIConversationMessage(message) {
            logger.i(message: "AIAssistantManager:: Processing AI conversation message")
            
            // Process the content within the ai_conversation message
            processAIConversationContent(message)
            
            delegate?.onAIConversationMessage(message)
            return true
        }
        
        // Check if this is a ringing acknowledgment message
        if let callId = extractRingingAckCallId(from: message) {
            logger.i(message: "AIAssistantManager:: Processing ringing acknowledgment for callId: \(callId)")
            delegate?.onRingingAckReceived(callId: callId)
            return true
        }
        
        // Check if this is a transcription message
        if let transcription = extractTranscription(from: message) {
            logger.i(message: "AIAssistantManager:: Processing transcription message")
            addTranscription(transcription)
            return true
        }
        
        // Check if this is a widget settings message
        if let settings = extractWidgetSettings(from: message) {
            logger.i(message: "AIAssistantManager:: Processing widget settings message")
            updateWidgetSettings(settings)
            return true
        }
        
        return false
    }
    
    /// Process AI conversation content to extract transcriptions and widget settings
    /// - Parameter message: The AI conversation message
    private func processAIConversationContent(_ message: [String: Any]) {
        guard let params = message["params"] as? [String: Any] else {
            return
        }
        
        // Check for widget settings within the ai_conversation message
        if let widgetData = params["widget_settings"] as? [String: Any] {
            logger.i(message: "AIAssistantManager:: Found widget settings in ai_conversation message")
            if let settings = parseWidgetSettingsData(widgetData) {
                updateWidgetSettings(settings)
            }
        }
        
        // Check for transcription data within the ai_conversation message
        if let transcriptionData = params["transcription"] as? [String: Any] {
            logger.i(message: "AIAssistantManager:: Found transcription in ai_conversation message")
            if let transcription = parseTranscriptionData(transcriptionData) {
                addTranscription(transcription)
            }
        }
        
        // Check for transcriptions array within the ai_conversation message
        if let transcriptionsArray = params["transcriptions"] as? [[String: Any]] {
            logger.i(message: "AIAssistantManager:: Found transcriptions array in ai_conversation message")
            for transcriptionData in transcriptionsArray {
                if let transcription = parseTranscriptionData(transcriptionData) {
                    addTranscription(transcription)
                }
            }
        }
        
        // Check for transcript data (alternative naming)
        if let transcriptData = params["transcript"] as? [String: Any] {
            logger.i(message: "AIAssistantManager:: Found transcript in ai_conversation message")
            if let transcription = parseTranscriptionData(transcriptData) {
                addTranscription(transcription)
            }
        }
        
        // Check for conversation messages/events
        if let conversationData = params["conversation"] as? [String: Any] {
            processConversationData(conversationData)
        }
        
        // Check for type-specific processing
        if let type = params["type"] as? String {
            switch type {
            case "widget_settings":
                if let settings = extractWidgetSettings(from: message) {
                    logger.i(message: "AIAssistantManager:: Processing widget_settings type message")
                    updateWidgetSettings(settings)
                }
            case "transcription", "transcript":
                if let transcription = extractTranscription(from: message) {
                    logger.i(message: "AIAssistantManager:: Processing transcription type message")
                    addTranscription(transcription)
                }
            case "response.text.delta":
                logger.i(message: "AIAssistantManager:: Processing response.text.delta type message")
                processResponseTextDelta(params)
            case "conversation.item.created":
                logger.i(message: "AIAssistantManager:: Processing conversation.item.created type message")
                processConversationItemCreated(params)
            default:
                logger.i(message: "AIAssistantManager:: Unknown ai_conversation type: \(type)")
            }
        }
    }
    
    /// Process conversation data for additional content
    /// - Parameter conversationData: The conversation data dictionary
    private func processConversationData(_ conversationData: [String: Any]) {
        // Process any nested conversation content
        if let events = conversationData["events"] as? [[String: Any]] {
            for event in events {
                if let transcription = parseTranscriptionData(event) {
                    addTranscription(transcription)
                }
            }
        }
        
        if let messages = conversationData["messages"] as? [[String: Any]] {
            for messageData in messages {
                if let transcription = parseTranscriptionData(messageData) {
                    addTranscription(transcription)
                }
            }
        }
    }
    
    /// Process response text delta messages from AI assistant
    /// - Parameter params: The params dictionary from the ai_conversation message
    private func processResponseTextDelta(_ params: [String: Any]) {
        guard let delta = params["delta"] as? String else {
            logger.w(message: "AIAssistantManager:: No delta found in response.text.delta message")
            return
        }
        
        // Extract optional fields
        let itemId = params["item_id"] as? String
        let responseId = params["response_id"] as? String
        let contentIndex = params["content_index"] as? Int ?? 0
        let outputIndex = params["output_index"] as? Int ?? 0
        
        logger.i(message: "AIAssistantManager:: Processing delta text: '\(delta)' for item_id: \(itemId ?? "unknown")")
        
        // Create a transcription item from the delta using Android-style properties
        let transcription = TranscriptionItem(
            id: itemId ?? UUID().uuidString,
            role: "assistant", // This is from the AI assistant
            content: delta,
            isPartial: true, // Delta messages are incremental, not final
            timestamp: Date(),
            confidence: 1.0, // High confidence for AI responses
            itemType: "response_delta",
            metadata: [
                "response_id": responseId as Any,
                "content_index": contentIndex,
                "output_index": outputIndex
            ]
        )
        
        // Check if we already have a transcription with this ID to append to
        if let itemId = itemId,
           let existingIndex = transcriptions.firstIndex(where: { $0.id == itemId }) {
            // Append delta to existing transcription
            let existing = transcriptions[existingIndex]
            // Create new transcription with appended content
            let updatedTranscription = TranscriptionItem(
                id: existing.id,
                role: existing.role,
                content: existing.content + delta,
                isPartial: existing.isPartial,
                timestamp: Date(),
                confidence: existing.confidence,
                itemType: existing.itemType,
                metadata: existing.metadata
            )
            transcriptions[existingIndex] = updatedTranscription
            logger.i(message: "AIAssistantManager:: Appended delta to existing transcription: \(itemId)")
            // Notify delegate of the update
            delegate?.onTranscriptionUpdated(transcriptions)
        } else {
            // Add as new transcription
            addTranscription(transcription)
        }
    }
    
    /// Process conversation item created messages (user transcriptions)
    /// - Parameter params: The params dictionary from the ai_conversation message
    private func processConversationItemCreated(_ params: [String: Any]) {
        guard let item = params["item"] as? [String: Any] else {
            logger.w(message: "AIAssistantManager:: No item found in conversation.item.created message")
            return
        }
        
        // Extract item properties
        let itemId = item["id"] as? String ?? UUID().uuidString
        let role = item["role"] as? String ?? "unknown"
        let status = item["status"] as? String
        
        // Only process user messages
        guard role == "user" else {
            logger.i(message: "AIAssistantManager:: Skipping non-user item: role=\(role)")
            return
        }
        
        // Check if this is a completed or in-progress transcription
        let isCompleted = status == "completed"
        let isInProgress = status == "in_progress"
        
        guard isCompleted || isInProgress else {
            logger.i(message: "AIAssistantManager:: Skipping item with status: \(status ?? "nil")")
            return
        }
        
        // Handle content - it can be either a string (direct content) or an array of content items
        var transcriptText = ""
        var contentType = "text"
        
        if let contentString = item["content"] as? String {
            // Handle direct string content (like in the example message)
            transcriptText = contentString
            contentType = "text"
            logger.i(message: "AIAssistantManager:: Found direct string content: '\(transcriptText)'")
        } else if let contentArray = item["content"] as? [[String: Any]] {
            // Handle array of content items (existing format)
            for content in contentArray {
                if let type = content["type"] as? String,
                   let transcript = content["transcript"] as? String {
                    transcriptText = transcript
                    contentType = type
                    logger.i(message: "AIAssistantManager:: Found content array item: '\(transcriptText)'")
                    break // Use the first valid content item
                }
            }
        }
        
        // Ensure we have transcript content
        guard !transcriptText.isEmpty else {
            logger.w(message: "AIAssistantManager:: No valid transcript content found in conversation item")
            return
        }
        
        logger.i(message: "AIAssistantManager:: Processing user transcript: '\(transcriptText)' for item_id: \(itemId)")
        
        // Create a transcription item for the user's speech using Android-style properties
        let transcription = TranscriptionItem(
            id: itemId,
            role: "user", // This is from the user
            content: transcriptText,
            isPartial: !isCompleted, // Partial if in progress, final if completed
            timestamp: Date(),
            confidence: nil, // No confidence provided for user transcripts
            itemType: contentType,
            metadata: [
                "status": status as Any,
                "content_type": contentType as Any
            ]
        )
        
        // Check if we already have a transcription with this ID to update
        if let existingIndex = transcriptions.firstIndex(where: { $0.id == itemId }) {
            // Update existing transcription
            transcriptions[existingIndex] = transcription
            logger.i(message: "AIAssistantManager:: Updated existing user transcription: \(itemId)")
            // Notify delegate of the update
            delegate?.onTranscriptionUpdated(transcriptions)
        } else {
            // Add as new transcription
            addTranscription(transcription)
        }
    }
    
    /// Get current AI assistant connection information
    /// - Returns: Dictionary containing connection information
    public func getConnectionInfo() -> [String: Any] {
        return [
            "isConnected": isConnected,
            "targetId": currentTargetId ?? NSNull(),
            "targetType": currentTargetType ?? NSNull(),
            "targetVersionId": currentTargetVersionId ?? NSNull()
        ]
    }
    
    /// Reset the AI assistant manager state
    public func reset() {
        logger.i(message: "AIAssistantManager:: Resetting state")
        updateConnectionState(connected: false, targetId: nil, targetType: nil, targetVersionId: nil)
        clearAllData()
    }
    
    /// Get current transcriptions
    /// - Returns: Array of transcription items
    public func getTranscriptions() -> [TranscriptionItem] {
        return transcriptions
    }
    
    /// Get current transcriptions (Android compatibility method)
    /// - Returns: Array of transcription items
    public var transcript: [TranscriptionItem] {
        return transcriptions
    }
    
    /// Get current widget settings
    /// - Returns: Current widget settings or nil if not set
    public func getWidgetSettings() -> WidgetSettings? {
        return widgetSettings
    }
    
    /// Add a transcription item
    /// - Parameter transcription: The transcription item to add
    public func addTranscription(_ transcription: TranscriptionItem) {
        transcriptions.append(transcription)
        logger.i(message: "AIAssistantManager:: Added transcription item: \(transcription.id)")
        
        // Notify delegate
        delegate?.onTranscriptionUpdated(transcriptions)
        
        // Publish real-time updates (Android compatibility)
        transcriptUpdatePublisher.send(transcriptions)
        transcriptItemPublisher.send(transcription)
    }
    
    /// Update widget settings
    /// - Parameter settings: The new widget settings
    public func updateWidgetSettings(_ settings: WidgetSettings) {
        widgetSettings = settings
        logger.i(message: "AIAssistantManager:: Updated widget settings")
        delegate?.onWidgetSettingsUpdated(settings)
    }
    
    /// Clear all transcriptions and widget settings
    public func clearAllData() {
        logger.i(message: "AIAssistantManager:: Clearing all transcriptions and widget settings")
        transcriptions.removeAll()
        widgetSettings = nil
        delegate?.onTranscriptionUpdated(transcriptions)
        if let settings = widgetSettings {
            delegate?.onWidgetSettingsUpdated(settings)
        }
        
        // Clear all subscriptions
        transcriptUpdateCancellables.removeAll()
        transcriptItemCancellables.removeAll()
        transcriptUpdatePublisher.removeAllSubscribers()
        transcriptItemPublisher.removeAllSubscribers()
    }
    
    /// Clear only transcriptions (called when call ends)
    public func clearTranscriptions() {
        logger.i(message: "AIAssistantManager:: Clearing transcriptions")
        transcriptions.removeAll()
        delegate?.onTranscriptionUpdated(transcriptions)
    }
    
    // MARK: - Mixed-mode Communication (Android compatibility)
    
    /// Send a text message to AI Assistant during active call (mixed-mode communication)
    /// - Parameter message: The text message to send
    /// - Returns: True if message was sent successfully, false otherwise
    @discardableResult
    public func sendAIAssistantMessage(_ message: String) -> Bool {
        guard isConnected else {
            logger.w(message: "AIAssistantManager:: Cannot send message - not connected to AI Assistant")
            return false
        }
        
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.w(message: "AIAssistantManager:: Cannot send empty message")
            return false
        }
        
        logger.i(message: "AIAssistantManager:: Sending text message to AI Assistant: '\(message)'")
        
        // Create a transcription item for the user's text message
        let textTranscription = TranscriptionItem(
            id: UUID().uuidString,
            role: "user",
            content: message,
            isPartial: false,
            itemType: "text_message",
            metadata: ["message_type": "text_input"]
        )
        
        // Add to transcriptions
        addTranscription(textTranscription)
        
        // TODO: Implement actual message sending to AI Assistant via socket
        // This would require integration with the socket manager to send the message
        
        return true
    }
    
    /// Send a voice message transcription to AI Assistant
    /// - Parameter transcription: The voice transcription to send
    /// - Returns: True if message was sent successfully, false otherwise
    @discardableResult
    public func sendVoiceTranscription(_ transcription: TranscriptionItem) -> Bool {
        guard isConnected else {
            logger.w(message: "AIAssistantManager:: Cannot send voice transcription - not connected to AI Assistant")
            return false
        }
        
        logger.i(message: "AIAssistantManager:: Sending voice transcription to AI Assistant: '\(transcription.content)'")
        
        // Add to transcriptions if not already there
        if !transcriptions.contains(where: { $0.id == transcription.id }) {
            addTranscription(transcription)
        }
        
        // TODO: Implement actual voice transcription sending to AI Assistant via socket
        // This would require integration with the socket manager to send the transcription
        
        return true
    }
    
    /// Subscribe to real-time transcript updates (Android compatibility)
    /// - Parameter handler: Closure to handle transcript updates
    /// - Returns: Cancellable token for the subscription
    public func subscribeToTranscriptUpdates(_ handler: @escaping ([TranscriptionItem]) -> Void) -> TranscriptCancellable {
        let cancellable = transcriptUpdatePublisher.subscribe(handler)
        transcriptUpdateCancellables.append(cancellable)
        return cancellable
    }
    
    /// Subscribe to individual transcript item updates (Android compatibility)
    /// - Parameter handler: Closure to handle individual transcript item updates
    /// - Returns: Cancellable token for the subscription
    public func subscribeToTranscriptItemUpdates(_ handler: @escaping (TranscriptionItem) -> Void) -> TranscriptCancellable {
        let cancellable = transcriptItemPublisher.subscribe(handler)
        transcriptItemCancellables.append(cancellable)
        return cancellable
    }
    
    // MARK: - Transcript Filtering (Android compatibility)
    
    /// Get transcriptions by role
    /// - Parameter role: The role to filter by ("user" or "assistant")
    /// - Returns: Array of transcription items for the specified role
    public func getTranscriptionsByRole(_ role: String) -> [TranscriptionItem] {
        return transcriptions.filter { $0.role.lowercased() == role.lowercased() }
    }
    
    /// Get user transcriptions only
    /// - Returns: Array of user transcription items
    public func getUserTranscriptions() -> [TranscriptionItem] {
        return getTranscriptionsByRole("user")
    }
    
    /// Get assistant transcriptions only
    /// - Returns: Array of assistant transcription items
    public func getAssistantTranscriptions() -> [TranscriptionItem] {
        return getTranscriptionsByRole("assistant")
    }
    
    /// Get partial transcriptions (in-progress recordings)
    /// - Returns: Array of partial transcription items
    public func getPartialTranscriptions() -> [TranscriptionItem] {
        return transcriptions.filter { $0.isPartial }
    }
    
    /// Get final transcriptions (completed recordings)
    /// - Returns: Array of final transcription items
    public func getFinalTranscriptions() -> [TranscriptionItem] {
        return transcriptions.filter { !$0.isPartial }
    }
    
    /// Clear transcriptions by role
    /// - Parameter role: The role to clear transcriptions for
    public func clearTranscriptionsByRole(_ role: String) {
        transcriptions.removeAll { $0.role.lowercased() == role.lowercased() }
        delegate?.onTranscriptionUpdated(transcriptions)
        transcriptUpdatePublisher.send(transcriptions)
    }
    
    // MARK: - Private Methods
    
    /// Check if a message is an AI conversation message
    /// - Parameter message: The message to check
    /// - Returns: True if it's an AI conversation message
    private func isAIConversationMessage(_ message: [String: Any]) -> Bool {
        // Check for AI conversation indicators in the message
        // This could be based on method, params, or other message properties
        
        if let method = message["method"] as? String {
            // Check for AI-specific methods
            if method.contains("ai_conversation") || method.contains("assistant") {
                return true
            }
        }
        
        if let params = message["params"] as? [String: Any] {
            // Check for AI conversation parameters
            if params["ai_conversation"] != nil || 
               params["assistant_message"] != nil ||
               params["conversation_id"] != nil {
                return true
            }
            
            // Check if target_type indicates AI assistant
            if let targetType = params["target_type"] as? String,
               targetType == "ai_assistant" {
                return true
            }
        }
        
        return false
    }
    
    /// Extract call ID from ringing acknowledgment message
    /// - Parameter message: The message to extract from
    /// - Returns: Call ID if found, nil otherwise
    private func extractRingingAckCallId(from message: [String: Any]) -> String? {
        // Check if this is a ringing acknowledgment message
        if let method = message["method"] as? String,
           method == "telnyx_rtc.ringing" {
            
            if let params = message["params"] as? [String: Any],
               let callId = params["callID"] as? String {
                return callId
            }
        }
        
        return nil
    }
    
    /// Extract transcription from message
    /// - Parameter message: The message to extract from
    /// - Returns: TranscriptionItem if found, nil otherwise
    private func extractTranscription(from message: [String: Any]) -> TranscriptionItem? {
        // Check for transcription in various message formats
        if let params = message["params"] as? [String: Any] {
            // Check for direct transcription data
            if let transcriptData = params["transcript"] as? [String: Any] {
                return parseTranscriptionData(transcriptData)
            }
            
            // Check for AI conversation with transcription
            if let conversationData = params["conversation"] as? [String: Any],
               let transcriptData = conversationData["transcript"] as? [String: Any] {
                return parseTranscriptionData(transcriptData)
            }
            
            // Check for real-time transcription updates
            if let method = message["method"] as? String,
               (method.contains("transcription") || method.contains("speech")) {
                return parseTranscriptionData(params)
            }
        }
        
        return nil
    }
    
    /// Extract widget settings from message
    /// - Parameter message: The message to extract from
    /// - Returns: WidgetSettings if found, nil otherwise
    private func extractWidgetSettings(from message: [String: Any]) -> WidgetSettings? {
        if let params = message["params"] as? [String: Any] {
            // Check for widget settings data
            if let widgetData = params["widget_settings"] as? [String: Any] {
                return parseWidgetSettingsData(widgetData)
            }
            
            // Check for UI configuration
            if let uiConfig = params["ui_config"] as? [String: Any] {
                return parseWidgetSettingsData(uiConfig)
            }
            
            // Check for assistant configuration
            if let assistantConfig = params["assistant_config"] as? [String: Any],
               let widgetData = assistantConfig["widget"] as? [String: Any] {
                return parseWidgetSettingsData(widgetData)
            }
        }
        
        return nil
    }
    
    /// Parse transcription data into TranscriptionItem
    /// - Parameter data: The transcription data dictionary
    /// - Returns: TranscriptionItem if parsing successful, nil otherwise
    private func parseTranscriptionData(_ data: [String: Any]) -> TranscriptionItem? {
        // Android-style parsing: prioritize 'content' over 'text'
        guard let content = data["content"] as? String ?? data["text"] as? String,
              !content.isEmpty else {
            return nil
        }
        
        let id = data["id"] as? String ?? UUID().uuidString
        let role = data["role"] as? String ?? data["speaker"] as? String ?? "unknown"
        let confidence = data["confidence"] as? Double
        let itemType = data["itemType"] as? String ?? data["type"] as? String
        
        // Parse isPartial (Android-style) or derive from isFinal (legacy)
        let isPartial: Bool
        if let partial = data["isPartial"] as? Bool {
            isPartial = partial
        } else if let isFinal = data["isFinal"] as? Bool {
            isPartial = !isFinal
        } else {
            isPartial = false // Default to final transcription
        }
        
        // Parse timestamp
        let timestamp: Date
        if let timestampString = data["timestamp"] as? String {
            let formatter = ISO8601DateFormatter()
            timestamp = formatter.date(from: timestampString) ?? Date()
        } else if let timestampDouble = data["timestamp"] as? Double {
            timestamp = Date(timeIntervalSince1970: timestampDouble)
        } else {
            timestamp = Date()
        }
        
        // Extract metadata if present
        let metadata = data["metadata"] as? [String: Any]
        
        return TranscriptionItem(
            id: id,
            role: role,
            content: content,
            isPartial: isPartial,
            timestamp: timestamp,
            confidence: confidence,
            itemType: itemType,
            metadata: metadata
        )
    }
    
    /// Parse widget settings data into WidgetSettings
    /// - Parameter data: The widget settings data dictionary  
    /// - Returns: WidgetSettings if parsing successful, nil otherwise
    private func parseWidgetSettingsData(_ data: [String: Any]) -> WidgetSettings? {
        // Basic fields with fallbacks
        let theme = data["theme"] as? String ?? "dark"
        let language = data["language"] as? String ?? data["lang"] as? String
        let autoStart = data["auto_start"] as? Bool ?? data["autoStart"] as? Bool ?? false
        let showTranscript = data["show_transcript"] as? Bool ?? data["showTranscript"] as? Bool ?? true
        let customStyles = data["custom_styles"] as? [String: Any] ?? data["styles"] as? [String: Any]
        
        // New fields with default values
        let agentThinkingText = data["agent_thinking_text"] as? String ?? ""
        let defaultState = data["default_state"] as? String ?? "collapsed"
        let giveFeedbackUrl = data["give_feedback_url"] as? String
        let logoIconUrl = data["logo_icon_url"] as? String
        let position = data["position"] as? String ?? "fixed"
        let reportIssueUrl = data["report_issue_url"] as? String
        let speakToInterruptText = data["speak_to_interrupt_text"] as? String ?? ""
        let startCallText = data["start_call_text"] as? String ?? ""
        let viewHistoryUrl = data["view_history_url"] as? String
        
        // Parse audio visualizer config
        var audioVisualizerConfig: AudioVisualizerConfig? = nil
        if let visualizerData = data["audio_visualizer_config"] as? [String: Any] {
            let color = visualizerData["color"] as? String ?? "verdant"
            let preset = visualizerData["preset"] as? String ?? "roundBars"
            audioVisualizerConfig = AudioVisualizerConfig(color: color, preset: preset)
        }
        
        return WidgetSettings(
            theme: theme,
            language: language,
            autoStart: autoStart,
            showTranscript: showTranscript,
            customStyles: customStyles,
            agentThinkingText: agentThinkingText,
            audioVisualizerConfig: audioVisualizerConfig,
            defaultState: defaultState,
            giveFeedbackUrl: giveFeedbackUrl,
            logoIconUrl: logoIconUrl,
            position: position,
            reportIssueUrl: reportIssueUrl,
            speakToInterruptText: speakToInterruptText,
            startCallText: startCallText,
            viewHistoryUrl: viewHistoryUrl
        )
    }
}

// MARK: - Extensions

extension AIAssistantManager {
    
    /// Convenience method to check if currently connected to an AI assistant
    public var isAIAssistantConnected: Bool {
        return isConnected && currentTargetId != nil
    }
    
    /// Get the current AI assistant target ID
    public var connectedTargetId: String? {
        return isConnected ? currentTargetId : nil
    }
}

// MARK: - Custom Publisher Classes (iOS 12.0 Compatibility)

/// Custom publisher for iOS 12.0 compatibility (replaces Combine's Publisher)
public class TranscriptPublisher<T> {
    private var subscribers: [(id: String, handler: (T) -> Void)] = []
    private let queue = DispatchQueue(label: "com.telnyx.transcript-publisher", qos: .userInitiated)
    
    /// Send a new value to all subscribers
    /// - Parameter value: The value to send
    public func send(_ value: T) {
        queue.async {
            for subscriber in self.subscribers {
                DispatchQueue.main.async {
                    subscriber.handler(value)
                }
            }
        }
    }
    
    /// Subscribe to publisher updates
    /// - Parameter handler: Closure to handle updates
    /// - Returns: Cancellable token
    public func subscribe(_ handler: @escaping (T) -> Void) -> TranscriptCancellable {
        let handlerId = UUID().uuidString
        queue.async {
            self.subscribers.append((id: handlerId, handler: handler))
        }
        return TranscriptCancellable { [weak self] in
            self?.queue.async {
                if let index = self?.subscribers.firstIndex(where: { $0.id == handlerId }) {
                    self?.subscribers.remove(at: index)
                }
            }
        }
    }
    
    /// Remove all subscribers
    public func removeAllSubscribers() {
        queue.async {
            self.subscribers.removeAll()
        }
    }
}

/// Custom cancellable for iOS 12.0 compatibility (replaces Combine's AnyCancellable)
public class TranscriptCancellable {
    private let cancelClosure: () -> Void
    
    init(cancelClosure: @escaping () -> Void) {
        self.cancelClosure = cancelClosure
    }
    
    deinit {
        cancelClosure()
    }
    
    /// Cancel the subscription
    public func cancel() {
        cancelClosure()
    }
}