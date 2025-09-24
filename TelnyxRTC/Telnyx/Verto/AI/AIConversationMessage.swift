//
//  AIConversationMessage.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 29/01/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

/// Represents conversation content for AI assistant messages
public struct ConversationContent {
    public let type: String
    public let text: String
    
    public init(type: String = "input_text", text: String) {
        self.type = type
        self.text = text
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "type": type,
            "text": text
        ]
    }
}

/// Represents a conversation item for AI assistant messages
public struct ConversationItem {
    public let id: String
    public let type: String
    public let role: String
    public let content: [ConversationContent]
    
    public init(id: String = UUID().uuidString, type: String = "message", role: String = "user", content: [ConversationContent]) {
        self.id = id
        self.type = type
        self.role = role
        self.content = content
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "type": type,
            "role": role,
            "content": content.map { $0.toDictionary() }
        ]
    }
}

/// Represents AI conversation parameters
public struct AiConversationParams {
    public let type: String
    public let item: ConversationItem
    
    public init(type: String = "conversation.item.create", item: ConversationItem) {
        self.type = type
        self.item = item
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "type": type,
            "item": item.toDictionary()
        ]
    }
}

/// Message class for AI conversation communication
class AIConversationMessage: Message {
    
    /// Initialize AI conversation message with text content
    /// - Parameter message: The text message to send to AI assistant
    init(message: String) {
        // Create conversation content
        let content = ConversationContent(type: "input_text", text: message)
        
        // Create conversation item
        let item = ConversationItem(
            id: UUID().uuidString,
            type: "message", 
            role: "user",
            content: [content]
        )
        
        // Create AI conversation parameters
        let aiParams = AiConversationParams(
            type: "conversation.item.create",
            item: item
        )
        
        // Convert to dictionary for message params
        let params = aiParams.toDictionary()
        
        super.init(params, method: .AI_CONVERSATION)
    }
    
    /// Initialize AI conversation message with custom parameters
    /// - Parameter aiParams: Custom AI conversation parameters
    init(aiParams: AiConversationParams) {
        let params = aiParams.toDictionary()
        super.init(params, method: .AI_CONVERSATION)
    }
}