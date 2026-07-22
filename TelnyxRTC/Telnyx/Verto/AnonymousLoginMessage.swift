//
//  AnonymousLoginMessage.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 29/07/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

class AnonymousLoginMessage : Message {
    
    init(targetType: String = "ai_assistant",
         targetId: String,
         targetVersionId: String? = nil,
         conversationId: String? = nil,
         sessionId: String,
         userVariables: [String: Any] = [:],
         reconnection: Bool = false
    ) {
        
        var params = [String: Any]()
        params["target_type"] = targetType
        params["target_id"] = targetId
        params["reconnection"] = reconnection
        params["sessid"] = sessionId
        
        // Add User-Agent information similar to the TypeScript implementation
        var userAgent = [String: Any]()
        userAgent["sdkVersion"] = Bundle(for: Message.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        userAgent["data"] = Message.USER_AGENT
        params["User-Agent"] = userAgent
        
        // Add target_version_id if provided
        if let versionId = targetVersionId {
            params["target_version_id"] = versionId
        }
        
        // Add target_params with conversation_id if provided
        if let convId = conversationId, !convId.isEmpty {
            var targetParams = [String: Any]()
            targetParams["conversation_id"] = convId
            params["target_params"] = targetParams
        }
        
        // Add user variables if provided
        if !userVariables.isEmpty {
            params["userVariables"] = userVariables
        }
        
        super.init(params, method: .ANONYMOUS_LOGIN)
    }
}