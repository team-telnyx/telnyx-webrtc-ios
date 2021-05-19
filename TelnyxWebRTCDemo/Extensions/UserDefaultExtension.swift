//
//  UserDefaultExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 18/05/2021.
//

import Foundation

fileprivate let PUSH_DEVICE_TOKEN = ""

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
}
