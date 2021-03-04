//
//  LoginMessage.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 03/03/2021.
//

import Foundation

class LoginMessage : Message {
        
    //user and password login
    init(user: String, password: String) {
        var params = [String: Any]()
        params["login"] = user
        params["passwd"] = password
        params["loginParams"] = [String: String]()
        params["userVariables"] = [String: String]()
        super.init(params, method: .LOGIN)
    }
    
    //token login
    init(token: String) {
        var params = [String: Any]()
        params["login_token"] = token
        params["loginParams"] = [String: String]()
        params["userVariables"] = [String: String]()
        super.init(params, method: .LOGIN)
    }
    
}
