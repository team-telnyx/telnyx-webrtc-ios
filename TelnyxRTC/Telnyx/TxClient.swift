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
    private static let DEFAULT_REGISTER_INTERVAL = 3.0 // In seconds
    private static let MAX_REGISTER_RETRY = 3 // Number of retry

    /// Keeps track of all the created calls by theirs UUIDs
    public internal(set) var calls: [UUID: Call] = [UUID: Call]()
    /// Subscribe to TxClient delegate to receive Telnyx SDK events
    public weak var delegate: TxClientDelegate?
    private var socket : Socket?

    private var sessionId : String?
    private var txConfig: TxConfig?
    private var serverConfiguration: TxServerConfiguration

    private var registerRetryCount: Int = MAX_REGISTER_RETRY
    private var registerTimer: Timer = Timer()
    private var gatewayState: GatewayStates = .NOREG

    private var pushCallUUIID: UUID?

    /// Client must be registered in order to receive or place calls.
    public var isRegistered: Bool {
        get {
            return gatewayState == .REGED
        }
    }

    // MARK: - Initializers
    /// TxClient has to be instantiated.
    public init() {
        self.serverConfiguration = TxServerConfiguration()
        self.configure()
    }

    // MARK: - Connection handling
    /// Connects to the iOS client to the Telnyx signaling server using the desired login credentials.
    /// - Parameters:
    ///   - txConfig: The desired login credentials. See TxConfig docummentation for more information.
    ///   - serverConfiguration: (Optional) To define a custom `signaling server` and `TURN/ STUN servers`. As default we use the internal Telnyx Production servers.
    /// - Throws: TxConfig parameters errors
    public func connect(txConfig: TxConfig, serverConfiguration: TxServerConfiguration = TxServerConfiguration()) throws {
        Logger.log.i(message: "TxClient:: connect()")
        //Check connetion parameters
        try txConfig.validateParams()

        self.registerRetryCount = TxClient.MAX_REGISTER_RETRY
        self.gatewayState = .NOREG
        self.txConfig = txConfig

        self.serverConfiguration = serverConfiguration

        Logger.log.i(message: "TxClient:: serverConfiguration server: [\(self.serverConfiguration.signalingServer)] ICE Servers [\(self.serverConfiguration.webRTCIceServers)]")

        self.socket = Socket()
        self.socket?.delegate = self
        self.socket?.connect(signalingServer: self.serverConfiguration.signalingServer)
    }

    /// Disconnects the TxClient from the Telnyx signaling server.
    public func disconnect() {
        Logger.log.i(message: "TxClient:: disconnect()")
        self.registerRetryCount = TxClient.MAX_REGISTER_RETRY
        self.gatewayState = .NOREG

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

    /// This function check the gateway status updates to determine if the current user has been successfully
    /// registered and can start receiving and/or making calls.
    /// - Parameter newState: The new gateway state received from B2BUA
    private func updateGatewayState(newState: GatewayStates) {
        Logger.log.i(message: "TxClient:: updateGatewayState() newState [\(newState)] gatewayState [\(self.gatewayState)]")

        if self.gatewayState == .REGED {
            // If the client is already registered, we don't need to do anything else.
            Logger.log.i(message: "TxClient:: updateGatewayState() already registered")
            return
        }
        // Keep the new state.
        self.gatewayState = newState
        switch newState {
            case .REGED:
                // If the client is now registered:
                // - Stop the timer
                // - Propagate the client state to the app.
                self.registerTimer.invalidate()
                self.delegate?.onClientReady()
                Logger.log.i(message: "TxClient:: updateGatewayState() clientReady")
                break
            default:
                // The gateway state can transition through multiple states before changing to REGED (Registered).
                Logger.log.i(message: "TxClient:: updateGatewayState() no registered")
                self.registerTimer.invalidate()
                DispatchQueue.main.async {
                    self.registerTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(TxClient.DEFAULT_REGISTER_INTERVAL), repeats: false) { [weak self] _ in
                        Logger.log.i(message: "TxClient:: updateGatewayState() registerTimer elapsed: gatewayState [\(String(describing: self?.gatewayState))] registerRetryCount [\(String(describing: self?.registerRetryCount))]")

                        if self?.gatewayState == .REGED {
                            self?.delegate?.onClientReady()
                        } else {
                            self?.registerRetryCount -= 1
                            if self?.registerRetryCount ?? 0 > 0 {
                                self?.requestGatewayState()
                            } else {
                                let notRegisteredError = TxError.serverError(reason: .gatewayNotRegistered)
                                self?.delegate?.onClientError(error: notRegisteredError)
                                Logger.log.e(message: "TxClient:: updateGatewayState() client not registered")
                            }
                        }
                    }
                }
                break
        }
    }

    private func requestGatewayState() {
        let gatewayMessage = GatewayMessage()
        let message = gatewayMessage.encode() ?? ""
        // Request gateway state
        self.socket?.sendMessage(message: message)
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
                        ringbackTone: self.txConfig?.ringBackTone,
                        iceServers: self.serverConfiguration.webRTCIceServers)
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
                        ringbackTone: self.txConfig?.ringBackTone,
                        iceServers: self.serverConfiguration.webRTCIceServers)
        call.callInfo?.callerName = callerName
        call.callInfo?.callerNumber = callerNumber
        call.callOptions = TxCallOptions(audio: true)

        self.calls[callId] = call

        if self.pushCallUUIID == nil {
            // propagate the incoming call to the App
            Logger.log.i(message: "TxClient:: push flow createIncomingCall \(call)")
            self.delegate?.onIncomingCall(call: call)
        } else {
            Logger.log.i(message: "TxClient:: push flow do nothing")
            self.pushCallUUIID = nil
        }
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
    public func processVoIPNotification(voipActionUUID: UUID,
                                        txConfig: TxConfig,
                                        serverConfiguration: TxServerConfiguration = TxServerConfiguration()) throws {
        Logger.log.i(message: "TxClient:: push flow voIPUUID \(voipActionUUID)")
        self.pushCallUUIID = voipActionUUID
        // Check if we are already connected and logged in
        if !isConnected() {
            Logger.log.i(message: "TxClient:: push flow connect")
            try? self.connect(txConfig: txConfig, serverConfiguration: serverConfiguration)
        } else {
            // TODO: Check if we need to do something else when we are already connected
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
            let vertoLogin = LoginMessage(user: sipUser, password: password, pushDeviceToken: pushToken, pushNotificationProvider: pushProvider)
            self.socket?.sendMessage(message: vertoLogin.encode())
        }
    }
    
    func onSocketDisconnected() {
        Logger.log.i(message: "TxClient:: SocketDelegate onSocketDisconnected()")
        self.socket = nil
        self.sessionId = nil
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
            // Process gateway state result.
            if let params = result["params"] as? [String: Any],
               let state = params["state"] as? String,
               let gatewayState = GatewayStates(rawValue: state) {
                Logger.log.i(message: "GATEWAY_STATE RESULT: \(state)")
                self.updateGatewayState(newState: gatewayState)
            }

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
                    // Once the client logs into the backend, a registration process starts.
                    // Clients can receive or place calls when they are fully registered into the backend.
                    // If a client try to call beforw been registered, a GATEWAY_DOWN error is received.
                    // Therefore, we need to check the gateway state once we have successfully loged in:
                    self.requestGatewayState()
                    // If we are going to receive an incoming call
                    if let params = vertoMessage.params,
                       let _ = params["reattached_sessions"] {
                        self.registerTimer.invalidate()
                        self.delegate?.onClientReady()
                    }
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
