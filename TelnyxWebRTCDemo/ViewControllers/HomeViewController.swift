import Reachability
import SwiftUI
import TelnyxRTC
import UIKit

class HomeViewController: UIViewController {
    private var hostingController: UIHostingController<HomeView>?
    let sipCredentialsVC = SipCredentialsViewController()

    var viewModel = HomeViewModel()
    var profileViewModel = ProfileViewModel()
    var callViewModel = CallViewModel()

    var telnyxClient: TxClient?
    var userDefaults: UserDefaults = UserDefaults()
    var serverConfig: TxServerConfiguration?

    var incomingCall: Bool = false
    var isSpeakerActive: Bool = false
    let reachability = try! Reachability()

    // Timer for connection timeout
    private var connectionTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 254 / 255, green: 253 / 255, blue: 245 / 255, alpha: 1.0)

        appDelegate.voipDelegate = self
        telnyxClient = self.appDelegate.telnyxClient

        // Set the TxClient in the HomeViewModel for PreCall Diagnosis
        if let client = self.telnyxClient {
            self.viewModel.setTxClient(client)
        }

        let profileView = ProfileView(
            viewModel: profileViewModel,
            onAddProfile: { [weak self] in
                self?.handleAddProfile()
            },
            onSwitchProfile: { [weak self] in
                self?.handleSwitchProfile()
            })

        let callView = CallView(
            viewModel: callViewModel, isPhoneNumber: false,
            onStartCall: { [weak self] in
                self?.onCallButton()
            },
            onEndCall: { [weak self] in
                self?.onEndCallButton()
            },
            onRejectCall: { [weak self] in
                self?.onRejectButton()
            },
            onAnswerCall: { [weak self] in
                self?.onAnswerButton()
            },
            onMuteUnmuteSwitch: { [weak self] mute in
                self?.onMuteUnmuteSwitch(mute: mute)
            },
            onToggleSpeaker: { [weak self] in
                self?.onToggleSpeaker()
            },
            onHold: { [weak self] hold in
                self?.onHoldUnholdSwitch(isOnHold: hold)
            },
            onDTMF: { [weak self] key in
                self?.appDelegate.currentCall?.dtmf(dtmf: key)
            },
            onRedial: { [weak self] phoneNumber in
                self?.callViewModel.sipAddress = phoneNumber
                self?.onCallButton()
            },
            onIceRestart: { [weak self] in
                self?.onIceRestart()
            }
        )

        let homeView = HomeView(
            viewModel: viewModel,
            profileViewModel: profileViewModel,
            onConnect: { [weak self] in
                self?.handleConnect()
            },
            onDisconnect: { [weak self] in
                self?.handleDisconnect()
            },
            onLongPressLogo: { [weak self] in
                self?.showHiddenOptions()
            },
            profileView: AnyView(profileView),
            callView: AnyView(callView))

        let hostingController = UIHostingController(rootView: homeView)
        self.hostingController = hostingController

        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        hostingController.didMove(toParent: self)

        initViews()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func appWillEnterForeground() {
        print("HomeViewController:: App is about to enter the foreground")
        DispatchQueue.main.async {
            self.callViewModel.currentCall = self.appDelegate.currentCall
            self.callViewModel.isMuted = self.appDelegate.currentCall?.isMuted ?? false
            self.callViewModel.isSpeakerOn = self.telnyxClient?.isSpeakerEnabled ?? false
            self.profileViewModel.updateSelectedProfile(SipCredentialsManager.shared.getSelectedCredential())
        }
    }

    private func handleAddProfile() {
        print("Add Profile tapped")
        present(sipCredentialsVC, animated: true, completion: nil)
    }

    private func handleSwitchProfile() {
        print("Switch Profile tapped")
        present(sipCredentialsVC, animated: true, completion: nil)
    }

    func handleConnect() {
        print("Connect tapped")
        let deviceToken = userDefaults.getPushToken()
        if let selectedProfile = profileViewModel.selectedProfile {
            connectToTelnyx(sipCredential: selectedProfile, deviceToken: deviceToken)
            CallHistoryManager.shared.setCurrentProfile(selectedProfile.username)
            CallHistoryManager.shared.getCallHistory()
        }
    }

    func handleDisconnect() {
        print("Disconnect tapped")
        // Stop the connection timer if it's running
        stopConnectionTimer()

        if telnyxClient?.isConnected() ?? false {
            telnyxClient?.disconnect()
        } else {
            // If we are not connected, take the user to the connect screen
            onSocketDisconnected()
        }
    }
}

// MARK: - VIEWS

extension HomeViewController {
    func initViews() {
        sipCredentialsVC.delegate = self
        hideKeyboardWhenTappedAround()
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
        }

        DispatchQueue.main.async {
            let sessionId = self.telnyxClient?.getSessionId() ?? ""
            let isConnected = self.telnyxClient?.isConnected() ?? false
            self.viewModel.socketState = !sessionId.isEmpty && isConnected ? .clientReady : isConnected ? .connected : .disconnected
            self.viewModel.isLoading = false
            self.viewModel.sessionId = sessionId.isEmpty ? "-" : sessionId
            self.viewModel.callState = self.appDelegate.currentCall?.callState ?? .DONE(reason: nil)
            self.callViewModel.callState = self.appDelegate.currentCall?.callState ?? .DONE(reason: nil)
            self.callViewModel.currentCall = self.appDelegate.currentCall
            self.callViewModel.isMuted = self.appDelegate.currentCall?.isMuted ?? false
            self.callViewModel.isSpeakerOn = self.telnyxClient?.isSpeakerEnabled ?? false
        }

        initEnvironment()
    }
}

// MARK: - SipCredentialsViewControllerDelegate

extension HomeViewController: SipCredentialsViewControllerDelegate {
    func onNewSipCredential(credential: SipCredential?) {
        let deviceToken = userDefaults.getPushToken()
        if let newProfile = credential {
            connectToTelnyx(sipCredential: newProfile, deviceToken: deviceToken)
        }
    }

    func onSipCredentialSelected(credential: SipCredential?) {
        DispatchQueue.main.async {
            self.profileViewModel.updateSelectedProfile(credential)
        }
    }
}

// MARK: - Environment selector

extension HomeViewController {
    private func showHiddenOptions() {
        let alert = UIAlertController(title: "Options", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Development Environment", style: .default, handler: { _ in
            self.serverConfig = TxServerConfiguration(environment: .development)
            self.userDefaults.saveEnvironment(.development)
            self.updateEnvironment()
        }))

        alert.addAction(UIAlertAction(title: "Production Environment", style: .default, handler: { _ in
            self.serverConfig = nil
            self.userDefaults.saveEnvironment(.production)
            self.updateEnvironment()
        }))

        // Force Relay Candidate toggle
        let currentForceRelay = userDefaults.getForceRelayCandidate()
        let forceRelayTitle = currentForceRelay ? "Disable Force Relay Candidate" : "Enable Force Relay Candidate"
        alert.addAction(UIAlertAction(title: forceRelayTitle, style: .default, handler: { _ in
            self.userDefaults.saveForceRelayCandidate(!currentForceRelay)
        }))

        // WebRTC Stats toggle
        let currentWebRTCStats = userDefaults.getWebRTCStats()
        let webRTCStatsTitle = currentWebRTCStats ? "Disable WebRTC Stats" : "Enable WebRTC Stats"
        alert.addAction(UIAlertAction(title: webRTCStatsTitle, style: .default, handler: { _ in
            self.userDefaults.saveWebRTCStats(!currentWebRTCStats)
        }))

        alert.addAction(UIAlertAction(title: "Copy APNS token", style: .default, handler: { _ in
            // To copy the APNS push token to pasteboard
            let token = UserDefaults().getPushToken()
            UIPasteboard.general.string = token
        }))
        alert.addAction(UIAlertAction(title: "Disable Push Notifications", style: .default, handler: { _ in
            self.telnyxClient?.disablePushNotifications()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    func updateEnvironment() {
        DispatchQueue.main.async {
            // Update selected credentials in UI after switching environment
            let credentials = SipCredentialsManager.shared.getSelectedCredential()
            self.onSipCredentialSelected(credential: credentials)

            let sdkVersion = Bundle(for: TxClient.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

            let env = self.serverConfig?.environment == .development ? "Development" : "Production "
            self.viewModel.environment = "\(env) TelnyxSDK [v\(sdkVersion)] - App [v\(appVersion)]"
        }
    }

    func initEnvironment() {
        if userDefaults.getEnvironment() == .development {
            self.serverConfig = TxServerConfiguration(environment: .development,region: profileViewModel.selectedRegion)
        }
        updateEnvironment()
    }
}

// MARK: - Handle connection

extension HomeViewController {
    private func connectToTelnyx(sipCredential: SipCredential,
                                 deviceToken: String?) {
        guard let telnyxClient = telnyxClient else { return }

        if telnyxClient.isConnected() {
            telnyxClient.disconnect()
            return
        }

        do {
            viewModel.isLoading = true
            // Update local credential

            let isToken = sipCredential.isToken ?? false
            let txConfig = try createTxConfig(telnyxToken: isToken ? sipCredential.username : nil, sipCredential: sipCredential, deviceToken: deviceToken)

            // Start the connection timeout timer
            startConnectionTimer()

            if let serverConfig = serverConfig {
                print("Development Server ")
                try telnyxClient.connect(txConfig: txConfig, serverConfiguration: serverConfig)
            } else {
                print("Production Server ")
                try telnyxClient.connect(txConfig: txConfig,serverConfiguration: TxServerConfiguration(region:profileViewModel.selectedRegion))
            }

            // Store user / password in user defaults
            SipCredentialsManager.shared.addOrUpdateCredential(sipCredential)
            SipCredentialsManager.shared.saveSelectedCredential(sipCredential)
            // Update UI
            onSipCredentialSelected(credential: sipCredential)

        } catch let error {
            print("ViewController:: connect Error \(error)")
            self.viewModel.isLoading = false
            stopConnectionTimer()
        }
    }

    // Start the connection timeout timer
    internal func startConnectionTimer() {
        // Invalidate any existing timer first
        stopConnectionTimer()

        // Create a new timer
        connectionTimer = Timer.scheduledTimer(
            timeInterval: viewModel.connectionTimeout,
            target: self,
            selector: #selector(connectionTimedOut),
            userInfo: nil,
            repeats: false
        )
        print("Connection timer started: \(viewModel.connectionTimeout) seconds")
    }

    // Stop the connection timeout timer
    internal func stopConnectionTimer() {
        connectionTimer?.invalidate()
        connectionTimer = nil
        print("Connection timer stopped")
    }

    // Handle connection timeout
    @objc private func connectionTimedOut() {
        print("Connection timed out after \(viewModel.connectionTimeout) seconds")

        DispatchQueue.main.async {
            // Stop the loading indicator
            self.viewModel.isLoading = false

            // Disconnect the socket
            self.telnyxClient?.disconnect()

            // Show an alert to the user
            let alert = UIAlertController(
                title: "Connection Timeout",
                message: "The connection to the server timed out. Please check your internet connection and try again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

    private func createTxConfig(telnyxToken: String?,
                                sipCredential: SipCredential?,
                                deviceToken: String?) throws -> TxConfig {
        var txConfig: TxConfig?
        
        // Get the forceRelayCandidate and webrtcStats settings from UserDefaults
        let forceRelayCandidate = userDefaults.getForceRelayCandidate()
        let webrtcStats = userDefaults.getWebRTCStats()

        // Set the connection configuration object.
        // We can login with a user token: https://developers.telnyx.com/docs/v2/webrtc/quickstart
        // Or we can use SIP credentials (SIP user and password)
        if let token = telnyxToken {
            txConfig = TxConfig(token: token,
                                pushDeviceToken: deviceToken,
                                ringtone: "incoming_call.mp3",
                                ringBackTone: "ringback_tone.mp3",
                                // You can choose the appropriate verbosity level of the SDK.
                                logLevel: .all,
                                reconnectClient: true,
                                // Enable webrtc stats debug
                                debug: webrtcStats,
                                // Force relay candidate
                                forceRelayCandidate: forceRelayCandidate,
                                // Enable Call Quality Metrics
                                enableQualityMetrics: false)
        } else if let credential = sipCredential {
            // To obtain SIP credentials, please go to https://portal.telnyx.com
            txConfig = TxConfig(sipUser: credential.username,
                                password: credential.password,
                                pushDeviceToken: deviceToken,
                                ringtone: "incoming_call.mp3",
                                ringBackTone: "ringback_tone.mp3",
                                // You can choose the appropriate verbosity level of the SDK.
                                logLevel: .all,
                                reconnectClient: true,
                                // Enable webrtc stats debug
                                debug: webrtcStats,
                                // Force relay candidate.
                                forceRelayCandidate: forceRelayCandidate,
                                // Enable Call Quality Metrics
                                enableQualityMetrics: false)
        }

        guard let config = txConfig else {
            throw NSError(domain: "ViewController", code: 1, userInfo: [NSLocalizedDescriptionKey: "No valid credentials provided."])
        }

        return config
    }
}

// MARK: - Handle incoming call

extension HomeViewController {
    func onAnswerButton() {
        guard let callID = appDelegate.currentCall?.callInfo?.callId else { return }
        appDelegate.executeAnswerCallAction(uuid: callID)
    }

    func onRejectButton() {
        guard let callID = appDelegate.currentCall?.callInfo?.callId else { return }
        appDelegate.executeEndCallAction(uuid: callID)
    }
}

// MARK: - Handle call

extension HomeViewController {
    func onCallButton() {
        guard !callViewModel.sipAddress.isEmpty else {
            print("HomeViewController:: onCallButton() ERROR: destination number or SIP user should not be empty")
            return
        }

        let uuid = UUID()
        let handle = "Telnyx"

        appDelegate.executeStartCallAction(uuid: uuid, handle: handle)
    }

    func onEndCallButton() {
        guard let uuid = appDelegate.currentCall?.callInfo?.callId else { return }
        appDelegate.executeEndCallAction(uuid: uuid)
    }

    func onMuteUnmuteSwitch(mute: Bool) {
        guard let callId = appDelegate.currentCall?.callInfo?.callId else {
            return
        }
        appDelegate.executeMuteUnmuteAction(uuid: callId, mute: mute)
    }

    func onToggleSpeaker() {
        if let isSpeakerEnabled = telnyxClient?.isSpeakerEnabled {
            if isSpeakerEnabled {
                telnyxClient?.setEarpiece()
            } else {
                telnyxClient?.setSpeaker()
            }

            DispatchQueue.main.async {
                self.callViewModel.isSpeakerOn = self.telnyxClient?.isSpeakerEnabled ?? false
            }
        }
    }

    func onHoldUnholdSwitch(isOnHold: Bool) {
        if isOnHold {
            appDelegate.currentCall?.hold()
        } else {
            appDelegate.currentCall?.unhold()
        }
    }
    
    func onIceRestart() {
        guard let call = appDelegate.currentCall else {
            print("[ICE-RESTART] HomeViewController:: No active call for ICE restart")
            return
        }
        
        print("[ICE-RESTART] HomeViewController:: Starting ICE restart")
        call.iceRestart { [weak self] (success, error) in
            DispatchQueue.main.async {
                if success {
                    print("[ICE-RESTART] HomeViewController:: ICE restart completed successfully")
                    // You could show a success message to the user here if needed
                } else {
                    print("[ICE-RESTART] HomeViewController:: ICE restart failed: \(error?.localizedDescription ?? "Unknown error")")
                    // You could show an error message to the user here if needed
                }
            }
        }
    }
}
