import UIKit
import SwiftUI
import TelnyxRTC
import Reachability

class HomeViewController: UIViewController {
    private var hostingController: UIHostingController<HomeView>?
    let sipCredentialsVC = SipCredentialsViewController()
    
    var viewModel = HomeViewModel()
    var profileViewModel = ProfileViewModel()
    var callViewModel = CallViewModel()
    
    var telnyxClient: TxClient?
    var userDefaults: UserDefaults = UserDefaults.init()
    var serverConfig: TxServerConfiguration?
    
    var incomingCall: Bool = false
    var isSpeakerActive : Bool = false
    let reachability = try! Reachability()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.appDelegate.voipDelegate = self
        self.telnyxClient = self.appDelegate.telnyxClient
        
        let profileView = ProfileView(
            viewModel: profileViewModel,
            onAddProfile: { [weak self] in
                self?.handleAddProfile()
            },
            onSwitchProfile: { [weak self] in
                self?.handleSwitchProfile()
            })
        
        let callView = CallView(
            viewModel: callViewModel,
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
            }
        )
        
        let homeView = HomeView(
            viewModel: viewModel,
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
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        
        self.initViews()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func appWillEnterForeground() {
        print("HomeViewController:: App is about to enter the foreground")
        DispatchQueue.main.async {
            self.callViewModel.isMuted = self.appDelegate.currentCall?.isMuted ?? false
            self.callViewModel.isSpeakerOn = self.telnyxClient?.isSpeakerEnabled ?? false
            self.profileViewModel.selectedProfile = SipCredentialsManager.shared.getSelectedCredential()
        }
    }
    
    private func handleAddProfile() {
        print("Add Profile tapped")
        self.present(self.sipCredentialsVC, animated: true, completion: nil)
    }
    
    private func handleSwitchProfile() {
        print("Switch Profile tapped")
        self.present(self.sipCredentialsVC, animated: true, completion: nil)
    }
    
    func handleConnect() {
        print("Connect tapped")
        let deviceToken = userDefaults.getPushToken()
        if let selectedProfile = profileViewModel.selectedProfile {
            connectToTelnyx(sipCredential: selectedProfile, deviceToken: deviceToken)
        }
    }
    
    func handleDisconnect() {
        print("Disconnect tapped")
        if self.telnyxClient?.isConnected() ?? false {
            self.telnyxClient?.disconnect()
        }
    }
}

// MARK: - VIEWS
extension HomeViewController {
    func initViews() {
        self.sipCredentialsVC.delegate = self
        self.hideKeyboardWhenTappedAround()
        self.reachability.whenReachable = { reachability in
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
            self.viewModel.callState = self.appDelegate.currentCall?.callState ?? .DONE
            self.callViewModel.callState = self.appDelegate.currentCall?.callState ?? .DONE
            self.callViewModel.isMuted = self.appDelegate.currentCall?.isMuted ?? false
            self.callViewModel.isSpeakerOn = self.telnyxClient?.isSpeakerEnabled ?? false
        }
        

        self.initEnvironment()
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
            self.profileViewModel.selectedProfile = credential
        }
    }
}

// MARK: - Environment selector
extension HomeViewController {
    private func showHiddenOptions() {
        let alert = UIAlertController(title: "Options", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Development Environment", style: .default , handler:{ (UIAlertAction)in
            self.serverConfig = TxServerConfiguration(environment: .development)
            self.userDefaults.saveEnvironment(.development)
            self.updateEnvironment()
        }))
        
        alert.addAction(UIAlertAction(title: "Production Environment", style: .default , handler:{ (UIAlertAction)in
            self.serverConfig = nil
            self.userDefaults.saveEnvironment(.production)
            self.updateEnvironment()
        }))
        
        alert.addAction(UIAlertAction(title: "Copy APNS token", style: .default , handler:{ (UIAlertAction)in
            // To copy the APNS push token to pasteboard
            let token = UserDefaults.init().getPushToken()
            UIPasteboard.general.string = token
        }))
        alert.addAction(UIAlertAction(title: "Disable Push Notifications", style: .default , handler:{ (UIAlertAction)in
            self.telnyxClient?.disablePushNotifications()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
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
        if self.userDefaults.getEnvironment() == .development {
            self.serverConfig = TxServerConfiguration(environment: .development)
        }
        self.updateEnvironment()
    }
    
}

// MARK: - Handle connection
extension HomeViewController {
    private func connectToTelnyx(sipCredential: SipCredential,
                                 deviceToken: String?) {
        guard let telnyxClient = self.telnyxClient else { return }
        
        if telnyxClient.isConnected() {
            telnyxClient.disconnect()
            return
        }
        
        do {
            self.viewModel.isLoading = true
            // Update local credential

            let isToken = sipCredential.isToken ?? false
            let txConfig = try createTxConfig(telnyxToken: isToken ? sipCredential.username : nil, sipCredential: sipCredential, deviceToken: deviceToken)
            
            if let serverConfig = serverConfig {
                print("Development Server ")
                try telnyxClient.connect(txConfig: txConfig, serverConfiguration: serverConfig)
            } else {
                print("Production Server ")
                try telnyxClient.connect(txConfig: txConfig)
            }
            
            // Store user / password in user defaults
            SipCredentialsManager.shared.addOrUpdateCredential(sipCredential)
            SipCredentialsManager.shared.saveSelectedCredential(sipCredential)
            // Update UI
            self.onSipCredentialSelected(credential: sipCredential)

        } catch let error {
            print("ViewController:: connect Error \(error)")
            self.viewModel.isLoading = false
        }
    }
    
    private func createTxConfig(telnyxToken: String?,
                                sipCredential: SipCredential?,
                                deviceToken: String?) throws -> TxConfig {
        var txConfig: TxConfig? = nil
        
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
                                debug: true,
                                // Force relay candidate
                                forceRelayCandidate: false)
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
                                debug: true,
                                // Force relay candidate.
                                forceRelayCandidate: false)
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
        guard let callID = self.appDelegate.currentCall?.callInfo?.callId else { return }
        self.appDelegate.executeAnswerCallAction(uuid: callID)
    }
    
    func onRejectButton() {
        guard let callID = self.appDelegate.currentCall?.callInfo?.callId else { return }
        self.appDelegate.executeEndCallAction(uuid:callID)
    }
}
// MARK: - Handle call
extension HomeViewController {
    
    func onCallButton() {
        guard !self.callViewModel.sipAddress.isEmpty else {
            print("HomeViewController:: onCallButton() ERROR: destination number or SIP user should not be empty")
            return
        }
        
        let uuid = UUID()
        let handle = "Telnyx"
        
        appDelegate.executeStartCallAction(uuid: uuid, handle: handle)
    }
    
    func onEndCallButton() {
        guard let uuid = self.appDelegate.currentCall?.callInfo?.callId else { return }
        appDelegate.executeEndCallAction(uuid: uuid)
    }
    
    func onMuteUnmuteSwitch(mute: Bool) {
        guard let callId = self.appDelegate.currentCall?.callInfo?.callId else {
            return
        }
        self.appDelegate.executeMuteUnmuteAction(uuid: callId, mute: mute)
    }
    
    func onToggleSpeaker() {
        if let isSpeakerEnabled = self.telnyxClient?.isSpeakerEnabled {
            if isSpeakerEnabled {
                self.telnyxClient?.setEarpiece()
            } else {
                self.telnyxClient?.setSpeaker()
            }
            
            DispatchQueue.main.async {
                self.callViewModel.isSpeakerOn = self.telnyxClient?.isSpeakerEnabled ?? false
            }
        }
    }
    
    func onHoldUnholdSwitch(isOnHold: Bool) {
        if isOnHold {
            self.appDelegate.currentCall?.hold()
        } else {
            self.appDelegate.currentCall?.unhold()
        }
    }
}
