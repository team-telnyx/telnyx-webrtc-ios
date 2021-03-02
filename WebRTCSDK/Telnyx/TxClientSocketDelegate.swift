//
//  TxClientSocketDelegate.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 02/03/2021.
//

import Foundation

protocol TxClientSocketDelegate {
    func onSocketConnected()
    func onSocketDisconnected()
    func onClientReady()
    func onSessionUpdated(sessionId: String)
    func onClientError(error: String)
}
