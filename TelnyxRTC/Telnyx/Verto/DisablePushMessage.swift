//
//  DisablePushMessage.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 21/08/2023.
//

import Foundation

class DisablePushMessage : Message {
    
    //refactor for backend to change this to boolean
    static let SUCCESS_KEY = "success"
    
    //TODO: refactor for backend to send message
    static let DISABLE_PUSH_SUCCESS_MESSAGE = "disable push notification success"
        
    //user and password login
    init(user: String,
         pushDeviceToken: String? = nil,
         pushNotificationProvider: String? = nil,
         pushEnvironment:PushEnvironment? = nil
    ) {
        var params = [String: Any]()
        params["user"] = user

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
            // Add device environment debug/ production
            // This new field is required to allow our PN service to determine
            // if the push has to be send to APNS Sandbox (app is in debug mode) or production
            #if DEBUG
            userVariables["push_notification_environment"] = PushEnvironment.debug.rawValue
            #else
            userVariables["push_notification_environment"] = PushEnvironment.production.rawValue
            #endif
        }
        
        params["User-Agent"] = userVariables
        super.init(params, method: .DISABLE_PUSH)
    }
    
    init(loginToken: String,
         pushDeviceToken: String? = nil,
         pushNotificationProvider: String? = nil,
         pushEnvironment:PushEnvironment? = nil
    ) {
        var params = [String: Any]()
        params["login_token"] = loginToken

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
            // Add device environment debug/ production
            // This new field is required to allow our PN service to determine
            // if the push has to be send to APNS Sandbox (app is in debug mode) or production
            #if DEBUG
            userVariables["push_notification_environment"] = PushEnvironment.debug.rawValue
            #else
            userVariables["push_notification_environment"] = PushEnvironment.production.rawValue
            #endif
        }
                
        params["User-Agent"] = userVariables
        super.init(params, method: .DISABLE_PUSH)
    }
    
   
    
}

