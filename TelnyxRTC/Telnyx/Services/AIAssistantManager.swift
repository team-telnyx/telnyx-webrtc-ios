//
//  AIAssistantManager.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 29/07/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

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