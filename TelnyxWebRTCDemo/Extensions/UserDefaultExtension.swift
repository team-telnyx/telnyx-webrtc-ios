//
//  UserDefaultExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 18/05/2021.
//

import Foundation
import TelnyxRTC

fileprivate let PUSH_DEVICE_TOKEN = ""

fileprivate let SIP_USER = "SIP_USER"
fileprivate let SIP_USER_PASSWORD = "SIP_USER_PASSWORD"
fileprivate let CALL_DESTINATION = "CALL_DESTINATION"
fileprivate let WEBRTC_ENVIRONMENT = "WEBRTC_ENVIRONMENT"

extension UserDefaults {

    func savePushToken(pushToken: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(pushToken, forKey: PUSH_DEVICE_TOKEN)
        userDefaults.synchronize()
    }

    func deletePushToken() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: PUSH_DEVICE_TOKEN)
        userDefaults.synchronize()
    }

    func getPushToken() -> String {
        let userDefaults = UserDefaults.standard
        return userDefaults.string(forKey: PUSH_DEVICE_TOKEN) ?? ""
    }

    func saveUser(sipUser: String, password: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(sipUser, forKey: SIP_USER)
        userDefaults.set(password, forKey: SIP_USER_PASSWORD)
        userDefaults.synchronize()
    }

    func saveCallDestination(callDestination: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(callDestination, forKey: CALL_DESTINATION)
        userDefaults.synchronize()
    }

    func getSipUser() -> String {
        let userDefaults = UserDefaults.standard
        return userDefaults.string(forKey: SIP_USER) ?? ""
    }

    func getSipUserPassword() -> String {
        let userDefaults = UserDefaults.standard
        return userDefaults.string(forKey: SIP_USER_PASSWORD) ?? ""
    }

    func saveEnvironment(environment: WebRTCEnvironment) {
        let userDefaults = UserDefaults.standard
        userDefaults.set((environment == .development) ? "development" : "production", forKey: WEBRTC_ENVIRONMENT)
        userDefaults.synchronize()
    }

    func getEnvironment() -> WebRTCEnvironment {
        let userDefaults = UserDefaults.standard
        return (userDefaults.string(forKey: WEBRTC_ENVIRONMENT) == "development") ? .development : .production
    }
}
