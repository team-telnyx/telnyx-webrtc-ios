//
//  TxPushNotification.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 19/05/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation


/// Determines the action associated if there's an incoming VoIP Push
public enum PushNotificationAction {
    case REJECT_CALL
    case ANSWER_CALL
    case NONE
}

/// Object that contains information of the incoming push notification and the action requested by the user.
public struct TxPushNotification {

    /// If the action was already executed or not
    public var isActionPending: Bool = false
    /// The action requested by the user from the Push Notification.
    public var action: PushNotificationAction = .ANSWER_CALL
    /// The UUID of the call that has the desired action pending.
    public internal(set) var callUUID: UUID? = nil

    init(action: PushNotificationAction, callUUID: UUID? = nil) {
        self.action = action
        self.callUUID = callUUID
        self.isActionPending = true
    }
}
