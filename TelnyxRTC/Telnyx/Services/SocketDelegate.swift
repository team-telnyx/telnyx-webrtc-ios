//
//  SocketDelegate.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 02/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

protocol SocketDelegate: AnyObject {
    func onSocketConnected()
    func onSocketDisconnected(reconnect:Bool,region:Region?)
    func onSocketError(error: Error)
    func onMessageReceived(message: String)
}
