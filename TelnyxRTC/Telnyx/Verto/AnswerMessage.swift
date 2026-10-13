//
//  AnswerMessage.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 04/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

class AnswerMessage : Message {

    init(sessionId: String,
         sdp: String,
         callInfo: TxCallInfo,
         callOptions: TxCallOptions,
         customHeaders:[String:String] = [:],
         trickle: Bool = false,
         pushWhenActive: Bool = false,
         pushDeviceToken: String? = nil) {

        var params = [String: Any]()
        var dialogParams = [String: Any]()
        // Merge callInfo into dialogParams
        callInfo.encode().forEach { (key, value) in dialogParams[key] = value }
        // Merge callOptions into dialogParams
        callOptions.encode().forEach { (key, value) in dialogParams[key] = value }

        params["User-Agent"] = Message.USER_AGENT

        params["sessionId"] = sessionId
        params["sdp"] = sdp
        if(!customHeaders.isEmpty){
            dialogParams["custom_headers"] = appendCustomHeaders(customHeaders: customHeaders)
        }
        params["dialogParams"] = dialogParams
        if trickle {
            params["trickle"] = true
        }

        // Independent mobile-SDK identity (VSDK-768 / VSDK-764 cross-SDK
        // telemetry spec). Kept separate from `User-Agent` so backend
        // telemetry can key off `mobile_sdk_name` + `mobile_sdk_version`
        // without depending on the legacy `User-Agent` string format.
        for (key, value) in Message.mobileSdkIdentity() {
            params[key] = value
        }

        // For push-when-active multi-device flows the backend needs to know which
        // device answered so it can exclude that device from the answered-elsewhere
        // / picked-off notification sent to the remaining devices. Only include the
        // token when both the app opted into `pushWhenActive` and a non-empty
        // PushKit VoIP token is available from `TxConfig(pushDeviceToken:)`. Empty
        // or whitespace-only tokens are dropped to keep the wire payload clean.
        if pushWhenActive,
           let pushDeviceToken = pushDeviceToken,
           !pushDeviceToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["answered_device_token"] = pushDeviceToken
        }
        super.init(params, method: .ANSWER)
    }
}


class ReAttachMessage : Message {

    init(sessionId: String,
         sdp: String,
         callInfo: TxCallInfo,
         callOptions: TxCallOptions,
         customHeaders:[String:String] = [:]) {

        var params = [String: Any]()
        var dialogParams = [String: Any]()
        // Merge callInfo into dialogParams
        callInfo.encode().forEach { (key, value) in dialogParams[key] = value }
        // Merge callOptions into dialogParams
        callOptions.encode().forEach { (key, value) in dialogParams[key] = value }

        params["User-Agent"] = Message.USER_AGENT

        params["sessionId"] = sessionId
        params["sdp"] = sdp
        if(!customHeaders.isEmpty){
            dialogParams["custom_headers"] = appendCustomHeaders(customHeaders: customHeaders)
        }
        params["dialogParams"] = dialogParams
        // Independent mobile-SDK identity (VSDK-768 / VSDK-764 cross-SDK
        // telemetry spec). Kept separate from `User-Agent` so backend
        // telemetry can key off `mobile_sdk_name` + `mobile_sdk_version`
        // without depending on the legacy `User-Agent` string format.
        for (key, value) in Message.mobileSdkIdentity() {
            params[key] = value
        }
        super.init(params, method: .ATTACH)
    }
}
