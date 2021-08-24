//
//  LoginMessage.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

enum appMode: String {
    case production = "production"
    case debug = "debug"
}

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
        #if DEBUG
        userVariables["environment"] = appMode.debug.rawValue
        #else
        userVariables["environment"] = appMode.production.rawValue
        #endif

        params["loginParams"] = [String: String]()
        params["userVariables"] = userVariables
        super.init(params, method: .LOGIN)
    }
    
    //token login
    init(token: String,
         pushDeviceToken: String? = nil,
         pushNotificationProvider: String? = nil) {
        var params = [String: Any]()
        params["login_token"] = token

        //Setup push variables
        var userVariables = [String: Any]()
        if let pushDeviceToken = pushDeviceToken {
            userVariables["push_device_token"] = pushDeviceToken
        }
        if let provider = pushNotificationProvider {
            userVariables["push_notification_provider"] = provider
        }

		params["loginParams"] = [String: String]()
        params["userVariables"] = userVariables
        super.init(params, method: .LOGIN)
    }
    
}
