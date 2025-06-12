//
//  TxClientDelegate.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 02/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

/// The TxClientDelegate protocol defines methods for receiving events and updates from a TxClient instance.
/// Implement this protocol to handle various states and events in your WebRTC-enabled application,
/// including connection status, call state changes, and push notifications.
///
/// ## Usage Example:
/// ```swift
/// class CallHandler: TxClientDelegate {
///     func onSocketConnected() {
///         print("Connected to Telnyx backend")
///     }
///
///     func onIncomingCall(call: Call) {
///         // Handle incoming call
///         call.answer()
///     }
///
///     // Implement other required methods...
/// }
/// ```
public protocol TxClientDelegate: AnyObject {

    /// Called when the WebSocket connection to Telnyx's backend is established.
    /// This indicates a successful network connection, but the client may not be fully ready yet.
    /// Wait for `onClientReady` before initiating calls.
    func onSocketConnected()

    /// Called when the WebSocket connection to Telnyx's backend is lost or closed.
    /// The client will automatically attempt to reconnect unless explicitly disconnected.
    func onSocketDisconnected()

    /// Called when an error occurs in the TxClient.
    /// - Parameter error: The error that occurred. Check the error type and message for details.
    /// Common errors include authentication failures and network connectivity issues.
    func onClientError(error: Error)

    /// Called when the client has successfully connected AND authenticated.
    /// The client is now ready to make and receive calls.
    /// This is the appropriate time to enable UI elements for calling functionality.
    func onClientReady()

    /// Called when push notification status changes for the current user.
    /// - Parameters:
    ///   - success: Whether the push notification operation succeeded
    ///   - message: Descriptive message about the operation result
    func onPushDisabled(success: Bool, message: String)
    
    /// Called when the client's session is updated, typically after a reconnection.
    /// - Parameter sessionId: The new session identifier for the connection.
    /// Store this ID if you need to track or debug connection issues.
    func onSessionUpdated(sessionId: String)

    /// Called whenever a call's state changes (e.g., ringing, answered, ended).
    /// - Parameters:
    ///   - callState: The new state of the call (NEW, CONNECTING, RINGING, ACTIVE, HELD, DONE)
    ///   - callId: The unique identifier of the affected call
    /// Use this to update your UI to reflect the current call state.
    func onCallStateUpdated(callState: CallState, callId: UUID)

    /// Called when a new incoming call is received.
    /// - Parameter call: The Call object representing the incoming call.
    /// You can use this object to answer or reject the call.
    func onIncomingCall(call: Call)

    /// Called when a remote party ends the call.
    /// - Parameters:
    ///   - callId: The unique identifier of the ended call.
    ///   - reason: Optional termination reason containing details about why the call ended.
    /// Use this to clean up any call-related UI elements or state and potentially display error messages.
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?)

    /// Called when a push notification triggers an incoming call.
    /// - Parameter call: The Call object created from the push notification data.
    /// This is specifically for handling calls that arrive via push notifications
    /// when the app is in the background.
    func onPushCall(call: Call)
    
    /// Called when the pre-call diagnosis state changes.
    /// - Parameter state: The current state of the pre-call diagnosis operation.
    /// Use this to track the progress of pre-call diagnosis and handle results or failures.
    func onPreCallDiagnosisStateUpdated(state: PreCallDiagnosisState)
}
