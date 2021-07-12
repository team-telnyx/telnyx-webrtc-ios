//
//  TxClient.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 01/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation
import AVFoundation
import Bugsnag

/// The `TelnyxRTC` client connects your application to the Telnyx backend,
/// enabling you to make outgoing calls and handle incoming calls.
///
/// ## Examples
/// ### Connect and login:
///
/// ```
/// // Initialize the client
/// let telnyxClient = TxClient()
///
/// // Register to get SDK events
/// telnyxClient.delegate = self
///
/// // Setup yor connection parameters.
///
/// // Set the login credentials and the ringtone/ringback configurations if required.
/// // Ringtone / ringback tone files are not mandatory.
/// // You can user your sipUser and password
/// let txConfigUserAndPassowrd = TxConfig(sipUser: sipUser,
///                                        password: password,
///                                        ringtone: "incoming_call.mp3",
///                                        ringBackTone: "ringback_tone.mp3",
///                                        //You can choose the appropriate verbosity level of the SDK.
///                                        //Logs are disabled by default
///                                        logLevel: .all)
///
/// // Use a JWT Telnyx Token to authenticate (recommended)
/// let txConfigToken = TxConfig(token: "MY_JWT_TELNYX_TOKEN",
///                              ringtone: "incoming_call.mp3",
///                              ringBackTone: "ringback_tone.mp3",
///                              //You can choose the appropriate verbosity level of the SDK. Logs are disabled by default
///                              logLevel: .all)
///
/// do {
///    // Connect and login
///    // Use `txConfigUserAndPassowrd` or `txConfigToken`
///    try telnyxClient.connect(txConfig: txConfigToken)
/// } catch let error {
///    print("ViewController:: connect Error \(error)")
/// }
///
/// // You can call client.disconnect() when you're done.
/// Note: you need to relese the delegate manually when you are done.
///
/// // Disconnecting and Removing listeners.
/// telnyxClient.disconnect();
///
/// // Release the delegate
/// telnyxClient.delegate = nil
///
/// ```
///
/// ### Listen TxClient delegate events.
///
/// ```
/// extension ViewController: TxClientDelegate {
///
///     func onRemoteCallEnded(callId: UUID) {
///         // Call has been removed internally.
///     }
///
///     func onSocketConnected() {
///        // When the client has successfully connected to the Telnyx Backend.
///     }
///
///     func onSocketDisconnected() {
///        // When the client from the Telnyx backend
///     }
///
///     func onClientError(error: Error)  {
///         // Something went wrong.
///     }
///
///     func onClientReady()  {
///        // You can start receiving incoming calls or
///        // start making calls once the client was fully initialized.
///     }
///
///     func onSessionUpdated(sessionId: String)  {
///        // This function will be executed when a sessionId is received.
///     }
///
///     func onIncomingCall(call: Call)  {
///        // Someone is calling you.
///     }
///
///     // You can update your UI from here base on the call states.
///     // Check that the callId is the same as your current call.
///     func onCallStateUpdated(callState: CallState, callId: UUID) {
///         DispatchQueue.main.async {
///             switch (callState) {
///             case .CONNECTING:
///                 break
///             case .RINGING:
///                 break
///             case .NEW:
///                 break
///             case .ACTIVE:
///                 break
///             case .DONE:
///                 break
///             case .HELD:
///                 break
///             }
///         }
///     }
/// }
/// ```
public class TxClient {

    // MARK: - Properties
    /// Keeps track of all the created calls by theirs UUIDs
    public internal(set) var calls: [UUID: Call] = [UUID: Call]()
    /// Subscribe to TxClient delegate to receive Telnyx SDK events
    public var delegate: TxClientDelegate?
    private var socket : Socket?

    private var sessionId : String?
    private var txConfig: TxConfig?

    // MARK: - Initializers
    /// TxClient has to be instantiated.
    public init() {
        self.configure()
    }

    // MARK: - Connection handling
    /// Connects to the iOS client to the Telnyx signaling server using the desired login credentials.
    /// - Parameter txConfig: The desired login credentials. See TxConfig docummentation for more information.
    /// - Throws: TxConfig parameters errors
    public func connect(txConfig: TxConfig) throws {
        Logger.log.i(message: "TxClient:: connect()")
        //Check connetion parameters
        try txConfig.validateParams()

        self.txConfig = txConfig
        self.socket = Socket()
        self.socket?.delegate = self
        self.socket?.connect()
    }

    /// Disconnects the TxClient from the Telnyx signaling server.
    public func disconnect() {
        Logger.log.i(message: "TxClient:: disconnect()")

        // Let's cancell all the current calls
        for (_ ,call) in self.calls {
            call.hangup()
        }

        self.calls.removeAll()
        socket?.disconnect()
        delegate?.onSocketDisconnected()
    }

    /// To check if TxClient is connected to Telnyx server.
    /// - Returns: `true` if TxClient socket is connected, `false` otherwise.
    public func isConnected() -> Bool {
        guard let isConnected = socket?.isConnected else { return false }
        return isConnected
    }

    /// Get the current session ID after logging into Telnyx Backend.
    /// - Returns: The current sessionId. If this value is empty, that means that the client is not connected to Telnyx server.
    public func getSessionId() -> String {
        return sessionId ?? ""
    }
}

// MARK: - SDK Initializations
extension TxClient {

    /// This function is called when the TxClient is instantiated. This funciton is intended to be used to initialize any
    /// required tool.
    private func configure() {
        self.setupBugsnag()
    }

    /// Initialize Bugsnag
    private func setupBugsnag() {
        let config = BugsnagConfiguration.loadConfig()
        config.apiKey = InternalConfig.default.bugsnagKey
        config.context = "TelnyxRTC"
        //TODO: check extra configurations.
        Bugsnag.start(with: config)
    }
} //END SDK initializations

// MARK: - Call handling
extension TxClient {

    /// This function can be used to access any active call tracked by the SDK.
    ///  A call will be accessible until has ended (transitioned to the DONE state).
    /// - Parameter callId: The unique identifier of a call.
    /// - Returns: The` Call` object that matches the  requested `callId`. Returns `nil` if no call was found.
    public func getCall(callId: UUID) -> Call? {
        return self.calls[callId]
    }

    /// Creates a new Call and starts the call sequence, negotiate the ICE Candidates and sends the invite.
    /// - Parameters:
    ///   - callerName: The caller name. This will be displayed as the caller name in the remote's client.
    ///   - callerNumber: The caller Number. The phone number of the current user.
    ///   - destinationNumber: The destination `SIP user address` (sip:YourSipUser@sip.telnyx.com) or `phone number`.
    ///   - callId: The current call UUID.
    ///   - clientState: (optional) Custom state in string format encoded in base64
    /// - Throws:
    ///   - sessionId is required if user is not logged in
    ///   - socket connection error if socket is not connected
    ///   - destination number is required to start a call.
    /// - Returns: The call that has been created
    public func newCall(callerName: String,
                 callerNumber: String,
                 destinationNumber: String,
                 callId: UUID,
                 clientState: String? = nil) throws -> Call {
        //User needs to be logged in to get a sessionId
        guard let sessionId = self.sessionId else {
            throw TxError.callFailed(reason: .sessionIdIsRequired)
        }
        //A socket connection is required
        guard let socket = self.socket,
              socket.isConnected else {
            throw TxError.socketConnectionFailed(reason: .socketNotConnected)
        }

        //A destination number or sip address is required to start a call
        if destinationNumber.isEmpty {
            throw TxError.callFailed(reason: .destinationNumberIsRequired)
        }

        let call = Call(callId: callId,
                        sessionId: sessionId,
                        socket: socket,
                        delegate: self,
                        ringtone: self.txConfig?.ringtone,
                        ringbackTone: self.txConfig?.ringBackTone)
        call.newCall(callerName: callerName, callerNumber: callerNumber, destinationNumber: destinationNumber, clientState: clientState)

        self.calls[callId] = call
        return call
    }

    /// Creates a call object when an invite is received.
    /// - Parameters:
    ///   - callerName: The name of the caller
    ///   - callerNumber: The caller phone number
    ///   - callId: The UUID of the incoming call
    ///   - remoteSdp: The SDP of the remote peer
    ///   - telnyxSessionId: The incoming call Telnyx Session ID
    ///   - telnyxLegId: The incoming call Leg ID
    private func createIncomingCall(callerName: String,
                                    callerNumber: String,
                                    callId: UUID,
                                    remoteSdp: String,
                                    telnyxSessionId: String,
                                    telnyxLegId: String) {

        guard let sessionId = self.sessionId,
              let socket = self.socket else {
            return
        }

        let call = Call(callId: callId,
                        remoteSdp: remoteSdp,
                        sessionId: sessionId,
                        socket: socket,
                        delegate: self,
                        telnyxSessionId: UUID(uuidString: telnyxSessionId),
                        telnyxLegId: UUID(uuidString: telnyxLegId),
                        ringtone: self.txConfig?.ringtone,
                        ringbackTone: self.txConfig?.ringBackTone)
        call.callInfo?.callerName = callerName
        call.callInfo?.callerNumber = callerNumber
        call.callOptions = TxCallOptions(audio: true)

        self.calls[callId] = call

        // propagate the incoming call to the App
        self.delegate?.onIncomingCall(call: call)
    }
}

// MARK: - Push Notifications handling
extension TxClient {

    /// Call this function to process a VoIP push notification of an incoming call.
    /// This function will be executed when the app was closed and the user executes an action over the VoIP push notification.
    ///  You will need to
    /// - Parameters:
    ///   - txConfig: The desired configuration to login to B2B2UA. User credentials must be the same as the
    /// - Throws: Error during the connection process
    public func processVoIPNotification(txConfig: TxConfig) throws {
        Logger.log.i(message: "TxClient:: processVoIPNotification()")
        // Check if we are already connected and logged in
        if !isConnected() &&
            getSessionId().isEmpty {
            try self.connect(txConfig: txConfig)
        }
    }
}

// MARK: - Audio
extension TxClient {

    /// Select the internal earpiece as the audio output
    public func setEarpiece() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.overrideOutputAudioPort(.none)
        } catch let error {
            Logger.log.e(message: "Error setting Earpiece \(error)")
        }
    }

    /// Select the speaker as the audio output
    public func setSpeaker() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.overrideOutputAudioPort(.speaker)
        } catch let error {
            Logger.log.e(message: "Error setting Speaker \(error)")
        }
    }
}

// MARK: - CallProtocol
extension TxClient: CallProtocol {

    func callStateUpdated(call: Call) {
        Logger.log.i(message: "TxClient:: callStateUpdated()")

        guard let callId = call.callInfo?.callId else { return }
        //Forward call state
        self.delegate?.onCallStateUpdated(callState: call.callState, callId: callId)

        //Remove call if it has ended
        if call.callState == .DONE ,
           let callId = call.callInfo?.callId {
            Logger.log.i(message: "TxClient:: Remove call")
            self.calls.removeValue(forKey: callId)
            //Forward call ended state
            self.delegate?.onRemoteCallEnded(callId: callId)
        }
    }
}

// MARK: - SocketDelegate
/**
 Listen for wss socket events
 */
extension TxClient : SocketDelegate {
    
    func onSocketConnected() {
        Logger.log.i(message: "TxClient:: SocketDelegate onSocketConnected()")
        self.delegate?.onSocketConnected()

        // Get push token and push provider if available
        let pushToken = self.txConfig?.pushNotificationConfig?.pushDeviceToken
        let pushProvider = self.txConfig?.pushNotificationConfig?.pushNotificationProvider

        //Login into the signaling server after the connection is produced.
        if let token = self.txConfig?.token  {
            Logger.log.i(message: "TxClient:: SocketDelegate onSocketConnected() login with Token")
            let vertoLogin = LoginMessage(token: token, pushDeviceToken: pushToken, pushNotificationProvider: pushProvider)
            self.socket?.sendMessage(message: vertoLogin.encode())
        } else {
            Logger.log.i(message: "TxClient:: SocketDelegate onSocketConnected() login with SIP User and Password")
            guard let sipUser = self.txConfig?.sipUser else { return }
            guard let password = self.txConfig?.password else { return }
            let pushToken = self.txConfig?.pushNotificationConfig?.pushDeviceToken
            let vertoLogin = LoginMessage(user: sipUser, password: password, pushDeviceToken: pushToken)
            self.socket?.sendMessage(message: vertoLogin.encode())
        }
    }
    
    func onSocketDisconnected() {
        Logger.log.i(message: "TxClient:: SocketDelegate onSocketDisconnected()")
        self.socket = nil
        self.delegate?.onSocketDisconnected()
    }

    func onSocketError(error: Error) {
        Logger.log.i(message: "TxClient:: SocketDelegate onSocketError()")
        self.delegate?.onClientError(error: error)
    }

    /**
     Each time we receive a message throught  the WSS this method will be called.
     Here we are checking the mesaging
     */
    func onMessageReceived(message: String) {
        Logger.log.i(message: "TxClient:: SocketDelegate onMessageReceived() message: \(message)")
        guard let vertoMessage = Message().decode(message: message) else { return }

        //Check if server is sending an error code
        if let error = vertoMessage.serverError {
            let message : String = error["message"] as? String ?? "Unknown"
            let code : String = String(error["code"] as? Int ?? 0)
            let err = TxError.serverError(reason: .signalingServerError(message: message, code: code))
            self.delegate?.onClientError(error: err)
        }

        //Check if we are getting the new sessionId in response to the "login" message.
        if let result = vertoMessage.result {
            //process result
            guard let sessionId = result["sessid"] as? String else { return }
            //keep the sessionId
            self.sessionId = sessionId
            self.delegate?.onSessionUpdated(sessionId: sessionId)
        } else {

            //Forward message to call based on it's uuid
            if let params = vertoMessage.params,
               let callUUIDString = params["callID"] as? String,
               let callUUID = UUID(uuidString: callUUIDString),
               let call = calls[callUUID] {
                call.handleVertoMessage(message: vertoMessage)
            }

            //Parse incoming Verto message
            switch vertoMessage.method {
            case .CLIENT_READY:
                self.delegate?.onClientReady()
                break

            case .INVITE:
                //invite received
                if let params = vertoMessage.params {
                    guard let sdp = params["sdp"] as? String,
                          let callId = params["callID"] as? String,
                          let uuid = UUID(uuidString: callId) else {
                        return
                    }

                    let callerName = params["caller_id_name"] as? String ?? ""
                    let callerNumber = params["caller_id_number"] as? String ?? ""
                    let telnyxSessionId = params["telnyx_session_id"] as? String ?? ""
                    let telnyxLegId = params["telnyx_leg_id"] as? String ?? ""

                    if telnyxSessionId.isEmpty {
                        Logger.log.w(message: "TxClient:: Telnyx Session ID unavailable on INVITE message")
                    }
                    if telnyxLegId.isEmpty {
                        Logger.log.w(message: "TxClient:: Telnyx Leg ID unavailable on INVITE message")
                    }
                    self.createIncomingCall(callerName: callerName,
                                            callerNumber: callerNumber,
                                            callId: uuid,
                                            remoteSdp: sdp,
                                            telnyxSessionId: telnyxSessionId,
                                            telnyxLegId: telnyxLegId)
                }
                break;

            default:
                Logger.log.i(message: "TxClient:: SocketDelegate Default method")
                break
            }
        }
    }
}
