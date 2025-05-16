//
//  TxClient.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 01/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation
import AVFoundation
import WebRTC
import CallKit

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
    //re_connect buffer in secondds
    private static let RECONNECT_BUFFER = 1.0
    /// Keeps track of all the created calls by theirs UUIDs
    public internal(set) var calls: [UUID: Call] = [UUID: Call]()
    /// Subscribe to TxClient delegate to receive Telnyx SDK events
    public weak var delegate: TxClientDelegate?
    private var socket : Socket?

    private var answerCallAction:CXAnswerCallAction? = nil
    private var endCallAction:CXEndCallAction? = nil
    private var sessionId : String?
    private var txConfig: TxConfig?
    private var serverConfiguration: TxServerConfiguration
    private var voiceSdkId:String? = nil

    private var registerRetryCount: Int = MAX_REGISTER_RETRY
    private var registerTimer: Timer = Timer()
    private var gatewayState: GatewayStates = .NOREG
    private var isCallFromPush: Bool = false
    private var currentCallId:UUID = UUID()
    private var pendingAnswerHeaders = [String:String]()
    internal var sendFileLogs:Bool = false
    private var attachCallId:String?
    private var pushMetaData:[String:Any]?
    private let AUTH_ERROR_CODE = "-32001"
    private var reconnectTimeoutTimer: DispatchSourceTimer?
    private let reconnectQueue = DispatchQueue(label: "TelnyxClient.ReconnectQueue")
    private var _isSpeakerEnabled: Bool = false
    private var enableQualityMetrics: Bool = false
    
    public private(set) var isSpeakerEnabled: Bool {
        get {
            return _isSpeakerEnabled
        }
        set {
            _isSpeakerEnabled = newValue
        }
    }

    /// Controls the audio device state when using CallKit integration.
    /// This property manages the WebRTC audio session activation and deactivation.
    ///
    /// When implementing CallKit, you must manually handle the audio session state:
    /// - Set to `true` in `provider(_:didActivate:)` to enable audio
    /// - Set to `false` in `provider(_:didDeactivate:)` to disable audio
    ///
    /// Example usage with CallKit:
    /// ```swift
    /// extension CallKitProvider: CXProviderDelegate {
    ///     func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    ///         telnyxClient.isAudioDeviceEnabled = true
    ///     }
    ///
    ///     func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    ///         telnyxClient.isAudioDeviceEnabled = false
    ///     }
    /// }
    /// ```
    public var isAudioDeviceEnabled : Bool {
        get {
            return RTCAudioSession.sharedInstance().isAudioEnabled
        }
        set {
            if newValue {
                RTCAudioSession.sharedInstance().audioSessionDidActivate(AVAudioSession.sharedInstance())
            } else {
                RTCAudioSession.sharedInstance().audioSessionDidDeactivate(AVAudioSession.sharedInstance())
            }
            RTCAudioSession.sharedInstance().isAudioEnabled = newValue
        }
    }
    
    /// Enables and configures the audio session for a call.
    /// This method sets up the appropriate audio configuration and activates the session.
    ///
    /// - Parameter audioSession: The AVAudioSession instance to configure
    /// - Important: This method MUST be called from the CXProviderDelegate's `provider(_:didActivate:)` callback
    ///             to properly handle audio routing when using CallKit integration.
    ///
    /// Example usage:
    /// ```swift
    /// func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    ///     print("provider:didActivateAudioSession:")
    ///     self.telnyxClient.enableAudioSession(audioSession: audioSession)
    /// }
    /// ```
    public func enableAudioSession(audioSession: AVAudioSession) {
        setupCorrectAudioConfiguration()
        setAudioSessionActive(true)
    }
    
    /// Disables and resets the audio session.
    /// This method cleans up the audio configuration and deactivates the session.
    ///
    /// - Parameter audioSession: The AVAudioSession instance to reset
    /// - Important: This method MUST be called from the CXProviderDelegate's `provider(_:didDeactivate:)` callback
    ///             to properly clean up audio resources when using CallKit integration.
    ///
    /// Example usage:
    /// ```swift
    /// func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    ///     print("provider:didDeactivateAudioSession:")
    ///     self.telnyxClient.disableAudioSession(audioSession: audioSession)
    /// }
    /// ```
    public func disableAudioSession(audioSession: AVAudioSession) {
        resetAudioConfiguration()
        setAudioSessionActive(false)
    }
    
    /// The current audio route configuration.
    /// This provides information about the active input and output ports.
    let currentRoute = AVAudioSession.sharedInstance().currentRoute
    
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
        sessionId = UUID().uuidString.lowercased()
        // Start monitoring audio route changes
        setupAudioRouteChangeMonitoring()

        NetworkMonitor.shared.startMonitoring()
        
        // Set up a closure to handle network state changes
        NetworkMonitor.shared.onNetworkStateChange = { [weak self] state in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch state {
                case .wifi:
                    Logger.log.i(message: "Connected to Wi-Fi")
                    self.reconnectClient()
                case .cellular, .vpn:
                    Logger.log.i(message: "Connected to Cellular")
                    self.reconnectClient()
                case .noConnection:
                    if(!self.isCallsActive){
                        self.delegate?.onSocketDisconnected()
                    }
                    Logger.log.e(message: "No network connection")
                    self.socket?.isConnected = false
                    self.updateActiveCallsState(callState: CallState.DROPPED(reason: .networkLost))
                    self.startReconnectTimeout()
                }
            }
        }
    }
    
    /// Sets up monitoring for audio route changes (e.g., headphones connected/disconnected, 
    /// Bluetooth device connected/disconnected).
    ///
    /// This method registers for AVAudioSession route change notifications to:
    /// - Track when audio devices are connected or disconnected
    /// - Monitor changes in the active audio output
    /// - Update the speaker state accordingly
    private func setupAudioRouteChangeMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil)
    }
    
    /// Handles audio route change notifications from the system.
    ///
    /// This method processes audio route changes and:
    /// - Updates the internal speaker state
    /// - Notifies observers about audio route changes
    /// - Manages audio routing between available outputs
    ///
    /// The method posts an "AudioRouteChanged" notification with:
    /// - isSpeakerEnabled: Whether the built-in speaker is active
    /// - outputPortType: The type of the current audio output port
    ///
    /// Common route change reasons handled:
    /// - .categoryChange: Audio session category was changed
    /// - .override: Route was overridden by the system or user
    /// - .routeConfigurationChange: Available routes were changed
    ///
    /// @objc attribute is required for NotificationCenter selector
    @objc private func handleAudioRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        let session = AVAudioSession.sharedInstance()
        let currentRoute = session.currentRoute
        
        // Ensure we have at least one output port
        guard let output = currentRoute.outputs.first else {
            return
        }
        
        Logger.log.i(message: "Audio route changed: \(output.portType), reason: \(reason)")
        
        switch reason {
            case .categoryChange, .override, .routeConfigurationChange:
                // Update internal speaker state based on current output
                let isSpeaker = output.portType == .builtInSpeaker
                _isSpeakerEnabled = isSpeaker
                
                // Notify observers about the route change
                NotificationCenter.default.post(
                    name: NSNotification.Name("AudioRouteChanged"),
                    object: nil,
                    userInfo: [
                        "isSpeakerEnabled": isSpeaker,
                        "outputPortType": output.portType
                    ]
                )
            default:
                break
        }
    }

    // MARK: - Connection handling
    /// Connects to the iOS cloglient to the Telnyx signaling server using the desired login credentials.
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

        if(self.voiceSdkId != nil){
            Logger.log.i(message: "with_id")
            self.serverConfiguration = TxServerConfiguration(signalingServer: serverConfiguration.signalingServer,webRTCIceServers: serverConfiguration.webRTCIceServers,environment: serverConfiguration.environment,pushMetaData: ["voice_sdk_id":self.voiceSdkId!])
        } else {
            Logger.log.i(message: "without_id")
            self.serverConfiguration = serverConfiguration
        }
        Logger.log.i(message: "TxClient:: serverConfiguration server: [\(self.serverConfiguration.signalingServer)] ICE Servers [\(self.serverConfiguration.webRTCIceServers)]")
        self.socket = Socket()
        self.socket?.delegate = self
        self.socket?.connect(signalingServer: self.serverConfiguration.signalingServer)
    }
    
    
    private func connectFromPush(txConfig: TxConfig, serverConfiguration: TxServerConfiguration = TxServerConfiguration()) throws {
        Logger.log.i(message: "TxClient:: connect from_push")
        //Check connetion parameters
        try txConfig.validateParams()
        self.registerRetryCount = TxClient.MAX_REGISTER_RETRY
        self.gatewayState = .NOREG
        self.txConfig = txConfig


        self.serverConfiguration = TxServerConfiguration(signalingServer: serverConfiguration.signalingServer,webRTCIceServers: serverConfiguration.webRTCIceServers,environment: serverConfiguration.environment,pushMetaData: self.pushMetaData)

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
        self.stopReconnectTimeout()
        // Remove audio route change observer
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.routeChangeNotification,
                                                  object: nil)
        socket?.disconnect(reconnect: false)
        delegate?.onSocketDisconnected()
    }

    private var isCallsActive: Bool {
        !self.calls.filter { 
            if case .DONE = $0.value.callState {
                return false
            }
            return $0.value.callState != .NEW
        }.isEmpty
    }

    /// To check if TxClient is connected to Telnyx server.
    /// - Returns: `true` if TxClient socket is connected, `false` otherwise.
    public func isConnected() -> Bool {
        guard let isConnected = socket?.isConnected else { return false }
        return isConnected
    }
    
    /// To answer and control callKit active flow
    /// - Parameters:
    ///     - answerAction : `CXAnswerCallAction` from callKit
    ///     - customHeaders: (Optional)
    ///     - debug:  (Optional) to enable quality metrics for call
    public func answerFromCallkit(answerAction:CXAnswerCallAction,customHeaders:[String:String] = [:],debug:Bool = false) {
        self.answerCallAction = answerAction
        ///answer call if currentPushCall is not nil
        ///This means the client has connected and we can safelyanswer
        if(self.calls[currentCallId] != nil){
            self.calls[currentCallId]?.answer(customHeaders: customHeaders,debug: debug)
            answerCallAction?.fulfill()
            resetPushVariables()
            Logger.log.i(message: "answered from callkit")
        }else{
            /// Let's Keep track od the `customHeaders` passed
            pendingAnswerHeaders = customHeaders
            /// Set call quality metrics
            self.enableQualityMetrics = debug
        }
    }
    
    private func resetPushVariables() {
        answerCallAction = nil
        endCallAction = nil
    }
    
    /// To end and control callKit active and conn
    public func endCallFromCallkit(endAction:CXEndCallAction,callId:UUID? = nil) {
        self.endCallAction = endAction
        // Place the code you want to delay here
        if let call = self.calls[endAction.callUUID] {
            Logger.log.i(message: "EndClient:: Ended Call with Id \(endAction.callUUID)")
            call.hangup()
            self.resetPushVariables()
            self.stopReconnectTimeout()
            endAction.fulfill()
        } else if(self.calls[self.currentCallId] != nil) {
            Logger.log.i(message: "EndClient:: Ended Call")
            self.calls[self.currentCallId]?.hangup()
            self.resetPushVariables()
            self.stopReconnectTimeout()
            endAction.fulfill()
        }
    }
    
    
    /// To disable push notifications for the current user
    public func disablePushNotifications() {
        Logger.log.i(message: "TxClient:: disablePush()")
        let pushProvider = self.txConfig?.pushNotificationConfig?.pushNotificationProvider

        if let sipUser = self.txConfig?.sipUser {
            let pushToken = self.txConfig?.pushNotificationConfig?.pushDeviceToken
            let disablePushMessage = DisablePushMessage(user: sipUser,pushDeviceToken: pushToken,pushNotificationProvider: pushProvider,pushEnvironment: self.txConfig?.pushEnvironment)
            let message = disablePushMessage.encode() ?? ""
            self.socket?.sendMessage(message: message)
            return
        }
        
        if let token = self.txConfig?.token {
            let pushToken = self.txConfig?.pushNotificationConfig?.pushDeviceToken
            let disablePushMessage = DisablePushMessage(loginToken:token,pushDeviceToken: pushToken,pushNotificationProvider: pushProvider,pushEnvironment: self.txConfig?.pushEnvironment)
            let message = disablePushMessage.encode() ?? ""
            self.socket?.sendMessage(message: message)
        }
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
                //Check if isCallFromPush and sendAttachCall Message
                if (self.isCallFromPush == true){
                    self.sendAttachCall()
                }
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
    private func configure() {}
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
    ///   - customHeaders: (optional) Custom Headers to be passed over webRTC Messages, should be in the
    ///     format `X-key:Value` `X` is required for headers to be passed.
    /// - Throws:
    ///   - sessionId is required if user is not logged in
    ///   - socket connection error if socket is not connected
    ///   - destination number is required to start a call.
    /// - Returns: The call that has been created
    public func newCall(callerName: String,
                        callerNumber: String,
                        destinationNumber: String,
                        callId: UUID,
                        clientState: String? = nil,
                        customHeaders:[String:String] = [:],
                        debug:Bool = false) throws -> Call {
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
                        iceServers: self.serverConfiguration.webRTCIceServers,
                        debug: self.txConfig?.debug ?? false,
                        forceRelayCandidate: self.txConfig?.forceRelayCandidate ?? false)
        call.newCall(callerName: callerName, callerNumber: callerNumber, destinationNumber: destinationNumber, clientState: clientState, customHeaders: customHeaders,debug: debug)

        currentCallId = callId
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
                                    telnyxLegId: String,
                                    customHeaders:[String:String] = [:],
                                    isAttach:Bool = false
    ) {

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
                        iceServers: self.serverConfiguration.webRTCIceServers,
                        isAttach: isAttach,
                        debug: self.txConfig?.debug ?? false,
                        forceRelayCandidate: self.txConfig?.forceRelayCandidate ?? false)
        call.callInfo?.callerName = callerName
        call.callInfo?.callerNumber = callerNumber
        call.callOptions = TxCallOptions(audio: true)
        call.inviteCustomHeaders = customHeaders
        self.calls[callId] = call
        // propagate the incoming call to the App
        Logger.log.i(message: "TxClient:: push flow createIncomingCall \(call)")
        
        currentCallId = callId
        
        if isAttach {
            Logger.log.i(message: "TxClient :: Attaching Call....")
            call.acceptReAttach(peer: nil,debug: enableQualityMetrics)
            return
        }

        if isCallFromPush {
            self.delegate?.onPushCall(call: call)
            //Answer is pending from push - Answer Call
            if(answerCallAction != nil){
                call.answer(customHeaders: pendingAnswerHeaders,debug: enableQualityMetrics)
                answerCallAction?.fulfill()
                resetPushVariables()
            }
            
            //End is pending from callkit
            if endCallAction != nil {
                call.hangup()
                stopReconnectTimeout()
                currentCallId = UUID()
                resetPushVariables()
            }
        } else {
            self.delegate?.onIncomingCall(call: call)
        }
        self.isCallFromPush = false
    }
}

// MARK: - Push Notifications handling
extension TxClient {

    /// Call this function to process a VoIP push notification of an incoming call.
    /// This function will be executed when the app was closed and the user executes an action over the VoIP push notification.
    ///  You will need to
    /// - Parameters:
    ///   - txConfig: The desired configuration to login to B2B2UA. User credentials must be the same as the
    ///   - serverConfiguration : required to setup from  VoIP push notification metadata.
    ///   - pushMetaData : meta data payload from VOIP Push notification
    ///                    (this should be gotten from payload.dictionaryPayload["metadata"] as? [String: Any])
    /// - Throws: Error during the connection process
    public func processVoIPNotification(txConfig: TxConfig,
                                        serverConfiguration: TxServerConfiguration,pushMetaData:[String: Any]) throws {
        
        
        let rtc_id = (pushMetaData["voice_sdk_id"] as? String)
        
        // Check if we are already connected and logged in
        FileLogger.isCallFromPush = true

        if(rtc_id == nil){
            Logger.log.e(message: "TxClient:: processVoIPNotification - pushMetaData is empty")
            throw TxError.clientConfigurationFailed(reason: .voiceSdkIsRequired)
        }
        
        self.pushMetaData = pushMetaData
                
        let pnServerConfig = TxServerConfiguration(
            signalingServer:nil,
            webRTCIceServers: serverConfiguration.webRTCIceServers,
            environment: serverConfiguration.environment,
            pushMetaData: pushMetaData)
        
        let noActiveCalls = self.calls.filter { 
            if case .ACTIVE = $0.value.callState { return true }
            if case .HELD = $0.value.callState { return true }
            return false
        }.isEmpty

        if (noActiveCalls && isConnected()) {
            Logger.log.i(message: "TxClient:: processVoIPNotification - No Active Calls disconnect")
            self.disconnect()
        }
        
        if(noActiveCalls){
            do {
                Logger.log.i(message: "TxClient:: No Active Calls Connecting Again")
                try self.connectFromPush(txConfig: txConfig, serverConfiguration: pnServerConfig)
                
                // Create an initial call_object to handle early bye message
                if let newCallId = (pushMetaData["call_id"] as? String) {
                    self.calls[UUID(uuidString: newCallId)!] = Call(callId: UUID(uuidString: newCallId)! , sessionId: newCallId, socket: self.socket!, delegate: self, iceServers: self.serverConfiguration.webRTCIceServers, debug: self.txConfig?.debug ?? false, forceRelayCandidate: self.txConfig?.forceRelayCandidate ?? false)
                }
            } catch let error {
                Logger.log.e(message: "TxClient:: push flow connect error \(error.localizedDescription)")
            }
        }
       
    
        self.isCallFromPush = true
    }

    /// To receive INVITE message after Push Noficiation is Received. Send attachCall Command
    fileprivate func sendAttachCall() {
        Logger.log.e(message: "TxClient:: PN Recieved.. Sending reattach call ")
        let pushProvider = self.txConfig?.pushNotificationConfig?.pushNotificationProvider
        let attachMessage = AttachCallMessage(pushNotificationProvider: pushProvider,pushEnvironment:self.txConfig?.pushEnvironment)
        let message = attachMessage.encode() ?? ""
        attachCallId = attachMessage.id
        self.socket?.sendMessage(message: message)
    }
}

// MARK: - Audio
extension TxClient {

    /// Select the internal earpiece as the audio output
    public func setEarpiece() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.overrideOutputAudioPort(.none)
            _isSpeakerEnabled = false
        } catch let error {
            Logger.log.e(message: "Error setting Earpiece \(error)")
        }
    }

    /// Select the speaker as the audio output
    public func setSpeaker() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.overrideOutputAudioPort(.speaker)
            _isSpeakerEnabled = true
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
        if case .DONE = call.callState,
           let callId = call.callInfo?.callId {
            Logger.log.i(message: "TxClient:: Remove call")
            self.calls.removeValue(forKey: callId)
            //Forward call ended state with termination reason if available
            if case let .DONE(reason) = call.callState {
                self.delegate?.onRemoteCallEnded(callId: callId, reason: reason)
            } else {
                self.delegate?.onRemoteCallEnded(callId: callId)
            }
            self._isSpeakerEnabled = false
        }
    }
}

// MARK: - SocketDelegate
/**
 Listen for wss socket events
 */
extension TxClient : SocketDelegate {
    
    /// Stops the reconnection timeout timer.
    /// 
    /// This function cancels the timer that would terminate a call if reconnection takes too long.
    /// It should be called when a call has successfully reconnected or when the call is intentionally ended.
    func stopReconnectTimeout() {
        Logger.log.i(message: "Reconnect TimeOut stopped")
        self.reconnectTimeoutTimer?.cancel()
    }

    /// Starts the reconnection timeout timer.
    /// 
    /// This function initializes and starts a timer that will terminate a call if reconnection
    /// takes longer than the configured timeout period (default: 60 seconds).
    /// 
    /// When the timer expires, the following actions occur:
    /// 1. The call state is updated to DONE
    /// 2. The client disconnects from the signaling server
    /// 3. A reconnectFailed error is triggered via the delegate
    /// 
    /// This prevents calls from being stuck in a "reconnecting" state indefinitely when
    /// network conditions prevent successful reconnection.
    func startReconnectTimeout() {
        Logger.log.i(message: "Reconnect TimeOut Started")
        self.reconnectTimeoutTimer = DispatchSource.makeTimerSource(queue: reconnectQueue)
        self.reconnectTimeoutTimer?.schedule(deadline: .now() + (txConfig?.reconnectTimeout ?? TxConfig.DEFAULT_TIMEOUT))
        self.reconnectTimeoutTimer?.setEventHandler { [weak self] in
            Logger.log.i(message: "Reconnect TimeOut : after \(self?.txConfig?.reconnectTimeout ?? TxConfig.DEFAULT_TIMEOUT) secs")
            self?.updateActiveCallsState(callState: CallState.DONE)
            self?.disconnect()
            self?.delegate?.onClientError(error: TxError.callFailed(reason: .reconnectFailed))
        }
        self.reconnectTimeoutTimer?.resume()
    }
   
    func reconnectClient() {
        if self.isCallsActive {
            updateActiveCallsState(callState: CallState.RECONNECTING(reason: .networkSwitch))
            startReconnectTimeout()
            Logger.log.i(message: "Reconnect Called : Calls are active")
        }else {
            return
        }
        if let txConfig = self.txConfig {
            if(txConfig.reconnectClient){
                guard let currentCall = self.calls[self.currentCallId] else {

                    Logger.log.e(message: "Current Call not available for ATTACH")
                    return
                }
                currentCall.endForAttachCall()
                self.socket?.disconnect(reconnect: true)
            }else {
                Logger.log.i(message: "TxClient:: Reconnect Disabled")
            }
        }else {
            Logger.log.e(message:"TxClient:: Not Reconnecting")
        }
    }
    
    func updateActiveCallsState(callState: CallState) {
        if self.isCallsActive {
            for call in self.calls.values {
                call.updateCallState(callState: callState)
            }
        }
    }
    
  
    func onSocketConnected() {
        Logger.log.i(message: "TxClient:: SocketDelegate onSocketConnected()")
        self.delegate?.onSocketConnected()

        // Get push token and push provider if available
        let pushToken = self.txConfig?.pushNotificationConfig?.pushDeviceToken
        let pushProvider = self.txConfig?.pushNotificationConfig?.pushNotificationProvider

        //Login into the signaling server after the connection is produced.
        if let token = self.txConfig?.token  {
            Logger.log.i(message: "TxClient:: SocketDelegate onSocketConnected() login with Token")
            let vertoLogin = LoginMessage(token: token, pushDeviceToken: pushToken, pushNotificationProvider: pushProvider,startFromPush: self.isCallFromPush,pushEnvironment: self.txConfig?.pushEnvironment,sessionId: self.sessionId!)
            self.socket?.sendMessage(message: vertoLogin.encode())
        } else {
            Logger.log.i(message: "TxClient:: SocketDelegate onSocketConnected() login with SIP User and Password")
            guard let sipUser = self.txConfig?.sipUser else { return }
            guard let password = self.txConfig?.password else { return }
            let pushToken = self.txConfig?.pushNotificationConfig?.pushDeviceToken
            let vertoLogin = LoginMessage(user: sipUser, password: password, pushDeviceToken: pushToken, pushNotificationProvider: pushProvider,startFromPush: self.isCallFromPush,pushEnvironment: self.txConfig?.pushEnvironment,sessionId: self.sessionId!)
            self.socket?.sendMessage(message: vertoLogin.encode())
        }
    }
    
    func onSocketDisconnected(reconnect: Bool) {
        
        if(reconnect) {
            Logger.log.i(message: "TxClient:: SocketDelegate  Reconnecting")
            DispatchQueue.main.asyncAfter(deadline: .now() + TxClient.RECONNECT_BUFFER) {
                do {
                    try self.connect(txConfig: self.txConfig!,serverConfiguration: self.serverConfiguration)
                }catch let error {
                    Logger.log.e(message:"TxClient:: SocketDelegate reconnect error" +  error.localizedDescription)
                }
            }
            return
        }

        
        Logger.log.i(message: "TxClient:: SocketDelegate onSocketDisconnected()")
        self.socket = nil
        self.sessionId = nil
        self.sessionId = UUID().uuidString.lowercased()
        self.delegate?.onSocketDisconnected()
    }

    func onSocketError(error: Error) {
        Logger.log.i(message: "TxClient:: SocketDelegate onSocketError()")
        self.delegate?.onSocketDisconnected()
        Logger.log.e(message:"TxClient:: Socket Error" +  error.localizedDescription)
    }

    /**
     Each time we receive a message throught  the WSS this method will be called.
     Here we are checking the mesaging
     */
    func onMessageReceived(message: String) {
        Logger.log.i(message: "TxClient:: SocketDelegate onMessageReceived() message: \(message)")
        guard let vertoMessage = Message().decode(message: message) else { return }
        
       // FileLogger().log(message)

        //Check if server is sending an error code
        if let error = vertoMessage.serverError {
            if(attachCallId == vertoMessage.id){
                // Call failed from remote end
              if let callId = pushMetaData?["call_id"] as? String {
                  Logger.log.i(message: "TxClient:: Attach Call ID \(String(describing: callId))")
                  FileLogger.shared.log("Error Recieved, Remote Call Ended Line 764")
                  // Create a termination reason for the error
                  let terminationReason = CallTerminationReason(cause: "REMOTE_ERROR")
                  self.delegate?.onRemoteCallEnded(callId: UUID(uuidString: callId)!, reason: terminationReason)
                  
                }
                return
            }
            let message : String = error["message"] as? String ?? "Unknown"
            let code : String = String(error["code"] as? Int ?? 0)
            let noActiveCalls = self.calls.filter { 
                if case .ACTIVE = $0.value.callState { return true }
                if case .HELD = $0.value.callState { return true }
                return false
            }.isEmpty

            let err = TxError.serverError(reason: .signalingServerError(message: message, code: code))
            self.delegate?.onClientError(error: err)
        }

        //Check if we are getting the new sessionId in response to the "login" message.
        if let result = vertoMessage.result {
            // Process gateway state result.
            if let params = result["params"] as? [String: Any],
               let state = params["state"] as? String,
               let gatewayState = GatewayStates(rawValue: state) {
                Logger.log.i(message: "GATEWAY_STATE RESULT HERE: \(state)")
                self.voiceSdkId = vertoMessage.voiceSdkId
                Logger.log.i(message: "VDK \(String(describing: vertoMessage.voiceSdkId))")
                self.updateGatewayState(newState: gatewayState)
              
            }
            
            //process disable push notification
            if let disablePushResult = vertoMessage.result {
                if let message = disablePushResult["message"] as? String {
                    if(vertoMessage.method == .DISABLE_PUSH){
                        Logger.log.i(message: "DisablePushMessage.DISABLE_PUSH_SUCCESS_MESSAGE")
                        self.delegate?.onPushDisabled(success: true, message: message)
                    }
                }
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
                call.handleVertoMessage(message: vertoMessage, dataMessage: message, txClient: self)
            }
            

            Logger.log.i(message: "VDK \(String(describing: vertoMessage.voiceSdkId))")

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
                        
                        self.voiceSdkId = vertoMessage.voiceSdkId

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
                        
                        var customHeaders = [String:String]()
                        if params["dialogParams"] is [String:Any] {
                            do {
                                let dataDecoded = try JSONDecoder().decode(CustomHeaderData.self, from: message.data(using: .utf8)!)
                                dataDecoded.params.dialogParams.custom_headers.forEach { xHeader in
                                    customHeaders[xHeader.name] = xHeader.value
                                }
                                print("Data Decode : \(dataDecoded)")
                            } catch {
                                print("decoding error: \(error)")
                            }
                        }
                        self.createIncomingCall(callerName: callerName,
                                                callerNumber: callerNumber,
                                                callId: uuid,
                                                remoteSdp: sdp,
                                                telnyxSessionId: telnyxSessionId,
                                                telnyxLegId: telnyxLegId,
                                                customHeaders: customHeaders)
                        if(isCallFromPush){
                            /*FileLogger.shared.log("INVITE : \(message) \n")
                            FileLogger.shared.log("INVITE telnyxLegId: \(telnyxLegId) \n") */
                            self.sendFileLogs = true
                        }
                        
                    }
                   
                    break;
            case .ATTACH:
                Logger.log.i(message: "Attach Received")
                // Stop the timeout
                stopReconnectTimeout()
                if let params = vertoMessage.params {
                    guard let sdp = params["sdp"] as? String,
                          let callId = params["callID"] as? String,
                          let uuid = UUID(uuidString: callId) else {
                        return
                    }
                    
                    self.voiceSdkId = vertoMessage.voiceSdkId

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
                    
                    var customHeaders = [String:String]()
                    if params["dialogParams"] is [String:Any] {
                        do {
                            let dataDecoded = try JSONDecoder().decode(CustomHeaderData.self, from: message.data(using: .utf8)!)
                            dataDecoded.params.dialogParams.custom_headers.forEach { xHeader in
                                customHeaders[xHeader.name] = xHeader.value
                            }
                            print("Data Decode : \(dataDecoded)")
                        } catch {
                            print("decoding error: \(error)")
                        }
                    }
        
                    
                    
                    Logger.log.i(message: "isAudioEnabled : \(self.isAudioDeviceEnabled)")
                    self.createIncomingCall(callerName: callerName,
                                            callerNumber: callerNumber,
                                            callId: uuid,
                                            remoteSdp: sdp,
                                            telnyxSessionId: telnyxSessionId,
                                            telnyxLegId: telnyxLegId,
                                            customHeaders: customHeaders,
                                            isAttach: true
                    )
                    
                }
                 break;
                //Mark: to send meassage to pong
            case .PING:
                self.socket?.sendMessage(message: message)
                break;
                default:
                    Logger.log.i(message: "TxClient:: SocketDelegate Default method")
                    break
            }
        }
    }
}

// MARK: - Audio session configurations
extension TxClient {
    internal func resetAudioConfiguration() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
        } catch {
            print(error)
        }
    }

    internal func setupCorrectAudioConfiguration() {
        let rtcAudioSession = RTCAudioSession.sharedInstance()
        rtcAudioSession.lockForConfiguration()
        
        let configuration = RTCAudioSessionConfiguration.webRTC()
        configuration.categoryOptions = [
            .allowBluetoothA2DP,
            .duckOthers,
            .allowBluetooth,
            .mixWithOthers
        ]
        
        do {
            try rtcAudioSession.setConfiguration(configuration)
        } catch {
            print(error)
        }
        
        rtcAudioSession.unlockForConfiguration()
    }

    internal func setAudioSessionActive(_ active: Bool) {
        let rtcAudioSession = RTCAudioSession.sharedInstance()
        
        rtcAudioSession.lockForConfiguration()
        do {
            try rtcAudioSession.setActive(active)
            rtcAudioSession.isAudioEnabled = active
        } catch {
            print(error)
        }
        rtcAudioSession.unlockForConfiguration()
    }
}
