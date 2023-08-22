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
        
    //user and password login
    init(user: String,
         pushDeviceToken: String? = nil,
         pushNotificationProvider: String? = nil) {
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
        
        userVariables["push_notification_provider"] = Message.USER_AGENT
        
        params["User-Agent"] = userVariables
        super.init(params, method: .DISABLE_PUSH)
    }
    
    init(loginToken: String,
         pushDeviceToken: String? = nil,
         pushNotificationProvider: String? = nil) {
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
        
        userVariables["push_notification_provider"] = Message.USER_AGENT
        
        params["User-Agent"] = userVariables
        super.init(params, method: .DISABLE_PUSH)
    }
    
   
    
}

