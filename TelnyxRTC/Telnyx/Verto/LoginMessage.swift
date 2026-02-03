//
//  LoginMessage.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation



class LoginMessage : Message {
        
    //user and password login
    init(user: String,
         password: String,
         pushDeviceToken: String? = nil,
         pushNotificationProvider: String? = nil,
         startFromPush: Bool = false,
         pushEnvironment:PushEnvironment? = nil,
         sessionId:String,
         declinePush: Bool = false
    ) {
        
        var params = [String: Any]()
        params["login"] = user
        params["passwd"] = password
        params["User-Agent"] = Message.USER_AGENT
        params["from_push"] = startFromPush
        params["sessid"] = sessionId
        //Setup push variables
        var userVariables = [String: Any]()
        if let pushDeviceToken = pushDeviceToken {
            userVariables["push_device_token"] = pushDeviceToken
        }
        if let provider = pushNotificationProvider {
            userVariables["push_notification_provider"] = provider
        }
        
        // Add device environment debug/ production
        // This new field is required to allow our PN service to determine
        // if the push has to be send to APNS Sandbox (app is in debug mode) or production
        
        if let pushEnv = pushEnvironment {
            userVariables["push_notification_environment"] = pushEnv.rawValue
        } else {
            #if DEBUG
            userVariables["push_notification_environment"] = PushEnvironment.debug.rawValue
            #else
            userVariables["push_notification_environment"] = PushEnvironment.production.rawValue
            #endif
        }
      
        
        var loginParams = [String: Any]()
        loginParams["attach_call"] = true.description
        if declinePush {
            loginParams["decline_push"] = true.description
        }
        
        params["loginParams"] = loginParams

        
        params["userVariables"] = userVariables
        super.init(params, method: .LOGIN)
    }
    
    //token login
    init(token: String,
         pushDeviceToken: String? = nil,
         pushNotificationProvider: String? = nil,
         startFromPush: Bool = false,
         pushEnvironment:PushEnvironment? = nil,
         sessionId:String,
         declinePush: Bool = false
    ) {
        var params = [String: Any]()
        params["login_token"] = token
        params["User-Agent"] = Message.USER_AGENT
        params["from_push"] = startFromPush
        params["sessid"] = sessionId
        var loginParams = [String: Any]()
        loginParams["attach_call"] = true.description
        if declinePush {
            loginParams["decline_push"] = true
        }
        params["loginParams"] = loginParams

        //Setup push variables
        var userVariables = [String: Any]()
        
        if let pushDeviceToken = pushDeviceToken {
            userVariables["push_device_token"] = pushDeviceToken
        }
        if let provider = pushNotificationProvider {
            userVariables["push_notification_provider"] = provider
        }
        
        if let pushEnv = pushEnvironment {
            userVariables["push_notification_environment"] = pushEnv.rawValue
        } else {
            // if the push has to be send to APNS Sandbox (app is in debug mode) or production
            #if DEBUG
            userVariables["push_notification_environment"] = PushEnvironment.debug.rawValue
            #else
            userVariables["push_notification_environment"] = PushEnvironment.production.rawValue
            #endif
        }
        


        params["userVariables"] = userVariables
        super.init(params, method: .LOGIN)
    }
    
}
