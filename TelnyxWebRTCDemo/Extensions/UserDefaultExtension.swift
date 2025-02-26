//
//  UserDefaultExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 18/05/2021.
//

import Foundation
import TelnyxRTC

enum UserDefaultsKey: String {
    case selectedSipCredential = "SELECTED_SIP_CREDENTIAL"
    case sipCredentials = "SIP_CREDENTIALS"
    case pushDeviceToken = "PUSH_DEVICE_TOKEN"
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
    
    func getPushToken() -> String? {
        return string(forKey: UserDefaultsKey.pushDeviceToken.rawValue)
    }
    
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

