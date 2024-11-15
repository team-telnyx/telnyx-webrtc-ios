//
//  UserDefaultExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 18/05/2021.
//

import Foundation
import TelnyxRTC

enum UserDefaultsKey: String {
    case pushDeviceToken = "PUSH_DEVICE_TOKEN"
    case sipUser = "SIP_USER"
    case sipUserPassword = "SIP_USER_PASSWORD"
    case callDestination = "CALL_DESTINATION"
    case webrtcEnvironment = "WEBRTC_ENVIRONMENT"
}

extension UserDefaults {
    
    // MARK: - Push Token
    func savePushToken(_ pushToken: String) {
        set(pushToken, forKey: UserDefaultsKey.pushDeviceToken.rawValue)
    }
    
    func deletePushToken() {
        removeObject(forKey: UserDefaultsKey.pushDeviceToken.rawValue)
    }
    
    func getPushToken() -> String {
        return string(forKey: UserDefaultsKey.pushDeviceToken.rawValue) ?? ""
    }
    
    // MARK: - SIP User
    func saveUser(sipUser: String, password: String) {
        set(sipUser, forKey: UserDefaultsKey.sipUser.rawValue)
        set(password, forKey: UserDefaultsKey.sipUserPassword.rawValue)
    }
    
    func getSipUser() -> String {
        return string(forKey: UserDefaultsKey.sipUser.rawValue) ?? ""
    }
    
    func getSipUserPassword() -> String {
        return string(forKey: UserDefaultsKey.sipUserPassword.rawValue) ?? ""
    }
    
    // MARK: - Call Destination
    func saveCallDestination(_ callDestination: String) {
        set(callDestination, forKey: UserDefaultsKey.callDestination.rawValue)
    }
    
    func getCallDestination() -> String {
        return string(forKey: UserDefaultsKey.callDestination.rawValue) ?? ""
    }
    
    func getEnvironment() -> WebRTCEnvironment {
        let value = string(forKey: UserDefaultsKey.webrtcEnvironment.rawValue) ?? ""
        return WebRTCEnvironment.fromString(value)
    }
    
    func saveEnvironment(_ environment: WebRTCEnvironment) {
        let value = environment.toString()
        set(value, forKey: UserDefaultsKey.webrtcEnvironment.rawValue)
    }
}

