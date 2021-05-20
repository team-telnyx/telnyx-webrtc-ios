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
         pushNotificationProvider: String? = nil) {
        var params = [String: Any]()
        params["login"] = user
        params["passwd"] = password
        //Setup push variables
        if let pushDeviceToken = pushDeviceToken {
            params["push_device_token"] = pushDeviceToken
        }
        if let provider = pushNotificationProvider {
            params["push_notification_provider"] = provider
        }
        params["loginParams"] = [String: String]()
        params["userVariables"] = [String: String]()
        super.init(params, method: .LOGIN)
    }
    
    //token login
    init(token: String,
         pushDeviceToken: String? = nil,
         pushNotificationProvider: String? = nil) {
        var params = [String: Any]()
        params["login_token"] = token
        if let pushDeviceToken = pushDeviceToken {
            params["push_device_token"] = pushDeviceToken
        }
        if let provider = pushNotificationProvider {
            params["push_notification_provider"] = provider
        }
        params["loginParams"] = [String: String]()
        params["userVariables"] = [String: String]()
        super.init(params, method: .LOGIN)
    }
    
}
