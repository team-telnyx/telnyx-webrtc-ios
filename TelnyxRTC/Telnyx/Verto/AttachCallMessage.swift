//
//  AttachCallMessage.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 07/09/2023.
//

import Foundation


class AttachCallMessage : Message {
    
    init(
            pushNotificationProvider: String? = nil) {
           var params = [String: Any]()

           //Setup push variables
           var userVariables = [String: Any]()
           
           if let provider = pushNotificationProvider {
               params["push_notification_provider"] = provider
           }
           
           #if DEBUG
           userVariables["push_notification_environment"] = appMode.debug.rawValue
           #else
           userVariables["push_notification_environment"] = appMode.production.rawValue
           #endif


           params["loginParams"] = [String: String]()
           params["userVariables"] = userVariables
           super.init(params, method: .ATTACH_CALL)
       }
}
