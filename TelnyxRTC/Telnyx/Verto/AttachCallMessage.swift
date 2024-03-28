//
//  AttachCallMessage.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 07/09/2023.
//

import Foundation


class AttachCallMessage : Message {
    
    init(pushNotificationProvider: String? = nil,pushEnvironment:PushEnvironment? = nil) {
           var params = [String: Any]()

           //Setup push variables
           var userVariables = [String: Any]()
           
           if let provider = pushNotificationProvider {
               params["push_notification_provider"] = provider
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

           params["loginParams"] = [String: String]()
           params["userVariables"] = userVariables
           super.init(params, method: .ATTACH_CALL)
       }
}
