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

        // Independent mobile-SDK identity (VSDK-768 / VSDK-764 cross-SDK
        // telemetry spec). Added as top-level params alongside the existing
        // object-shaped `User-Agent` payload so backend telemetry can key off
        // `mobile_sdk_name` + `mobile_sdk_version` without depending on the
        // `User-Agent` shape.
        for (key, value) in Message.mobileSdkIdentity() {
            params[key] = value
        }
        
        // Add target_version_id if provided
        if let versionId = targetVersionId {
            params["target_version_id"] = versionId
        }
        
        // Add user variables if provided
        if !userVariables.isEmpty {
            params["userVariables"] = userVariables
        }
        
        super.init(params, method: .ANONYMOUS_LOGIN)
    }
}