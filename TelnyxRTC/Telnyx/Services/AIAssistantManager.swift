//
//  AIAssistantManager.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 29/07/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

/// Represents a transcription item from AI assistant conversations
public struct TranscriptionItem {
    public let id: String
    public let timestamp: Date
    public let speaker: String
    public let text: String
    public let confidence: Double?
    
    public init(id: String, timestamp: Date, speaker: String, text: String, confidence: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.speaker = speaker
        self.text = text
        self.confidence = confidence
    }
}

/// Represents widget settings for AI assistant interface
public struct WidgetSettings {
    public let theme: String?
    public let language: String?
    public let autoStart: Bool
    public let showTranscript: Bool
    public let customStyles: [String: Any]?
    
    public init(theme: String? = nil, language: String? = nil, autoStart: Bool = false, showTranscript: Bool = true, customStyles: [String: Any]? = nil) {
        self.theme = theme
        self.language = language
        self.autoStart = autoStart
        self.showTranscript = showTranscript
        self.customStyles = customStyles
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
        delegate?.onTranscriptionUpdated(transcriptions)
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
    }
    
    /// Clear only transcriptions (called when call ends)
    public func clearTranscriptions() {
        logger.i(message: "AIAssistantManager:: Clearing transcriptions")
        transcriptions.removeAll()
        delegate?.onTranscriptionUpdated(transcriptions)
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
        guard let text = data["text"] as? String,
              !text.isEmpty else {
            return nil
        }
        
        let id = data["id"] as? String ?? UUID().uuidString
        let speaker = data["speaker"] as? String ?? data["role"] as? String ?? "unknown"
        let confidence = data["confidence"] as? Double
        
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
        
        return TranscriptionItem(
            id: id,
            timestamp: timestamp,
            speaker: speaker,
            text: text,
            confidence: confidence
        )
    }
    
    /// Parse widget settings data into WidgetSettings
    /// - Parameter data: The widget settings data dictionary
    /// - Returns: WidgetSettings if parsing successful, nil otherwise
    private func parseWidgetSettingsData(_ data: [String: Any]) -> WidgetSettings? {
        let theme = data["theme"] as? String
        let language = data["language"] as? String ?? data["lang"] as? String
        let autoStart = data["auto_start"] as? Bool ?? data["autoStart"] as? Bool ?? false
        let showTranscript = data["show_transcript"] as? Bool ?? data["showTranscript"] as? Bool ?? true
        let customStyles = data["custom_styles"] as? [String: Any] ?? data["styles"] as? [String: Any]
        
        return WidgetSettings(
            theme: theme,
            language: language,
            autoStart: autoStart,
            showTranscript: showTranscript,
            customStyles: customStyles
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