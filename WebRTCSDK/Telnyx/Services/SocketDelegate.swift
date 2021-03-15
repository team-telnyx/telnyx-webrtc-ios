//
//  SocketDelegate.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 02/03/2021.
//

import Foundation

protocol SocketDelegate {
    func onSocketConnected()
    func onSocketDisconnected()
    func onSocketError(error: Error)
    func onMessageReceived(message: String)
}
