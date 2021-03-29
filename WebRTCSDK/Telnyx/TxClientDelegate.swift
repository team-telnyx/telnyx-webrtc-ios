//
//  TxClientDelegate.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 02/03/2021.
//

import Foundation

public protocol TxClientDelegate {
    func onSocketConnected()
    func onSocketDisconnected()
    func onClientError(error: Error)
    func onClientReady()
    func onSessionUpdated(sessionId: String)
    func onCallStateUpdated(callState: CallState, callId: UUID)
    func onIncomingCall(call: Call)
    func onRemoteCallEnded(callId: UUID)
}
