//
//  AIConversationMessage.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 29/01/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

/// Represents image URL data for AI assistant messages
public struct ImageURL {
    public let url: String
    
    public init(url: String) {
        self.url = url
    }
    
    public func toDictionary() -> [String: Any] {
        return ["url": url]
    }
}

/// Represents conversation content for AI assistant messages
public struct ConversationContent {
    public let type: String
    public let text: String?
    public let imageURL: ImageURL?
    
    /// Initialize with text content
    public init(type: String = "input_text", text: String) {
        self.type = type
        self.text = text
        self.imageURL = nil
    }
    
    /// Initialize with image URL content
    public init(type: String = "image_url", imageURL: ImageURL) {
        self.type = type
        self.text = nil
        self.imageURL = imageURL
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["type": type]
        
        if let text = text {
            dict["text"] = text
        }
        
        if let imageURL = imageURL {
            dict["image_url"] = imageURL.toDictionary()
        }
        
        return dict
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
    
    /// Initialize AI conversation message with text and optional Base64 encoded image
    /// - Parameters:
    ///   - message: The text message to send to AI assistant
    ///   - base64Image: Optional Base64 encoded image data (without data URL prefix)
    ///   - imageFormat: Image format (jpeg, png, etc.). Defaults to "jpeg"
    @available(*, deprecated, message: "Use init(message:base64Images:imageFormat:) for better support of multiple images")
    init(message: String, base64Image: String?, imageFormat: String = "jpeg") {
        var contentArray: [ConversationContent] = []

        // Add text content
        let textContent = ConversationContent(type: "input_text", text: message)
        contentArray.append(textContent)

        // Add image content if provided
        if let base64Image = base64Image, !base64Image.isEmpty {
            let dataURL = "data:image/\(imageFormat);base64,\(base64Image)"
            let imageURL = ImageURL(url: dataURL)
            let imageContent = ConversationContent(type: "image_url", imageURL: imageURL)
            contentArray.append(imageContent)
        }

        // Create conversation item
        let item = ConversationItem(
            id: UUID().uuidString,
            type: "message",
            role: "user",
            content: contentArray
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

    /// Initialize AI conversation message with text and multiple Base64 encoded images
    /// - Parameters:
    ///   - message: The text message to send to AI assistant
    ///   - base64Images: Optional array of Base64 encoded image data (without data URL prefix)
    ///   - imageFormat: Image format (jpeg, png, etc.). Defaults to "jpeg"
    init(message: String, base64Images: [String]?, imageFormat: String = "jpeg") {
        var contentArray: [ConversationContent] = []

        // Add text content if not empty
        if !message.isEmpty {
            let textContent = ConversationContent(type: "input_text", text: message)
            contentArray.append(textContent)
        }

        // Add image content for each provided image
        if let base64Images = base64Images, !base64Images.isEmpty {
            for base64Image in base64Images where !base64Image.isEmpty {
                // Auto-detect data URL format or add it
                let dataURL: String
                if base64Image.starts(with: "data:image/") {
                    dataURL = base64Image
                } else {
                    dataURL = "data:image/\(imageFormat);base64,\(base64Image)"
                }

                let imageURL = ImageURL(url: dataURL)
                let imageContent = ConversationContent(type: "image_url", imageURL: imageURL)
                contentArray.append(imageContent)
            }
        }

        // Create conversation item
        let item = ConversationItem(
            id: UUID().uuidString,
            type: "message",
            role: "user",
            content: contentArray
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