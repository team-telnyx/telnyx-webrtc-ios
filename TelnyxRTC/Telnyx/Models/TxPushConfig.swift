//
//  TxPushConfig.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 18/05/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation


/// This class contains all the properties related to Push Notifications
public struct TxPushConfig {
    public static let PUSH_NOTIFICATION_PROVIDER: String = "ios"

    public internal(set) var pushDeviceToken: String?
    public internal(set) var pushNotificationProvider: String = PUSH_NOTIFICATION_PROVIDER

    init(pushDeviceToken: String, pushProvider: String = PUSH_NOTIFICATION_PROVIDER) {
        self.pushDeviceToken = pushDeviceToken
        self.pushNotificationProvider = pushProvider
    }
}
