//
//  TxClientDelegate.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 02/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

/// Delegate protocol asociated with the TxClient
/// Methods for receiving TxClient events.
public protocol TxClientDelegate: AnyObject {

    /// Tells the delegate when the Telnyx Client has successfully connected to the Telnyx Backend
    func onSocketConnected()

    /// Tells the delegate when the Telnyx Client has disconnected from the Telnyx Backend
    func onSocketDisconnected()

    /// Tells the delegate when there's an error in the Telnyx Client
    /// - Parameter error: error occurred inside the Telnyx Client
    func onClientError(error: Error)

    /// Tells the delegate that the The Telnyx Client is ready to be used.
    /// Has successfully connected and logged in
    func onClientReady()

    /// Tells the delegate that the Telnyx Client session has been updated.
    /// - Parameter sessionId: The new sessionId assigned to the client connection.
    func onSessionUpdated(sessionId: String)

    /// Tells the delegate that a call has been updated.
    /// - Parameters:
    ///   - callState: The new call state
    ///   - callId: The UUID of the affected call
    func onCallStateUpdated(callState: CallState, callId: UUID)

    /// Tells the delegate that someone is calling
    /// - Parameter call: The call object of the incoming call.
    func onIncomingCall(call: Call)

    /// Tells the delegate that a call has ended
    /// - Parameter callId: the UUID of the call that has ended.
    func onRemoteCallEnded(callId: UUID)

    func onRemoteCallAnswered(call: Call)
}
