//
//  ViewController.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 01/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import UIKit
import CallKit
import TelnyxRTC
import AVFAudio
import Reachability
import Network

// An enum to handle the network status
enum NetworkStatus: String {
    case connected
    case disconnected
}

class Monitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor")

    var status: NetworkStatus = .connected

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            // Monitor runs on a background thread so we need to publish
            // on the main thread
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    print("We're connected!")
                    self.status = .connected

                } else {
                    print("No connection.")
                    self.status = .disconnected
                }
            }
        }
        monitor.start(queue: queue)
    }
}


class ViewController: UIViewController {

    let sipCredentialsVC = SipCredentialsViewController()
    var userDefaults: UserDefaults = UserDefaults.init()
    var telnyxClient: TxClient?
    var incomingCall: Bool = false
    var isSpeakerActive : Bool = false
    let reachability = try! Reachability()


    var loadingView: UIAlertController?

    @IBOutlet weak var environment: UILabel!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var sessionIdLabel: UILabel!
    @IBOutlet weak var socketStateLabel: UILabel!
    @IBOutlet weak var callView: UICallScreen!
    @IBOutlet weak var settingsView: UISettingsView!
    @IBOutlet weak var incomingCallView: UIIncomingCallView!
    @IBOutlet weak var connectButton: UIButton!
    
    var serverConfig: TxServerConfiguration?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController:: viewDidLoad()")
        self.appDelegate.voipDelegate = self
        self.telnyxClient = appDelegate.telnyxClient
        self.initViews()
        
        // Register notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func initViews() {
        print("ViewController:: initViews()")
        self.sipCredentialsVC.delegate = self
        self.callView.isHidden = true
        self.callView.isMuted = self.appDelegate.currentCall?.isMuted ?? false
        self.callView.delegate = self
        self.callView.hideEndButton(hide: true)

        self.incomingCallView.isHidden = true
        self.incomingCallView.delegate = self

        self.hideKeyboardWhenTappedAround()

        // Restore last user credentials
        self.settingsView.isHidden = false
        self.settingsView.delegate = self
        
        // Environment Selector
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        self.logo.addGestureRecognizer(longPressRecognizer)
        self.logo.isUserInteractionEnabled = true

        if self.userDefaults.getEnvironment() == .development {
            self.serverConfig = TxServerConfiguration(environment: .development)
        }
        self.updateEnvironment()
        self.reachability.whenReachable = { reachability in
             if reachability.connection == .wifi {
                 print("Reachable via WiFi")
             } else {
                 print("Reachable via Cellular")
             }
         }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let selectedCredentials = SipCredentialsManager.shared.getSelectedCredential()
        self.settingsView.sipUsernameLabel.text = selectedCredentials?.username ?? ""
        self.settingsView.passwordUserNameLabel.text = selectedCredentials?.password ?? ""
        
        if SipCredentialsManager.shared.getCredentials().isEmpty {
            self.settingsView.selectCredentialButton.isHidden = true
        } else {
            self.settingsView.selectCredentialButton.isHidden = false
        }
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            // Internal use only
            self.showHiddenOptions()
        }
    }
    
    @objc func appWillEnterForeground() {
        print("ViewController:: App is about to enter the foreground")
        self.callView.isMuted = self.appDelegate.currentCall?.isMuted ?? false
    }

    func showHiddenOptions() {
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
            self.environment.text = "\(env) TelnyxSDK [v\(sdkVersion)] - App [v\(appVersion)]"
        }
    }

    func updateButtonsState() {
        guard let callState = self.appDelegate.currentCall?.callState else {
            self.callView.updateButtonsState(callState: .DONE, incomingCall: false)
            self.incomingCallView.updateButtonsState(callState: .DONE, incomingCall: incomingCall)
            return
        }
        self.callView.updateButtonsState(callState: callState, incomingCall: self.incomingCall)
        self.incomingCallView.updateButtonsState(callState: callState, incomingCall: incomingCall)
    }

    @IBAction func connectButtonTapped(_ sender: Any) {
        // Get stored token from APNS
        let deviceToken = userDefaults.getPushToken()
        if settingsView.isTokenSelected {
            guard let telnyxToken = settingsView.tokenLabel.text, !telnyxToken.isEmpty else {
                print("ViewController:: connectButtonTapped() ERROR: Telnyx Token should not be empty. Go to https://developers.telnyx.com/docs/v2/webrtc/quickstart to learn on how to create On-demand tokens.")
                return
            }
            connectToTelnyx(telnyxToken: telnyxToken, sipCredential: nil, deviceToken: deviceToken)
        } else {
            guard let sipCredential = getSelectedSipCredential() else {
                print("ViewController:: connectButtonTapped() ERROR: SIP User and Password should not be empty.")
                return
            }
            connectToTelnyx(telnyxToken: nil, sipCredential: sipCredential, deviceToken: deviceToken)
        }
    }

    func resetCallStates() {
        self.incomingCall = false
        self.incomingCallView.isHidden = true
        self.callView.isHidden = false
        self.callView.resetHoldUnholdState()
        self.callView.isMuted = self.appDelegate.currentCall?.isMuted ?? false
        self.callView.resetSpeakerState()
    }
    
    func isCallOutGoing() -> Bool {
        return appDelegate.isCallOutGoing
    }
}

// MARK: - UIIncomingCallViewDelegate
/**
 Handle Incoming Call Views events
 */
extension ViewController : UIIncomingCallViewDelegate {

    func onAnswerButton() {
        guard let callID = self.appDelegate.currentCall?.callInfo?.callId else { return }
        self.appDelegate.executeAnswerCallAction(uuid: callID)
    }

    func onRejectButton() {
        guard let callID = self.appDelegate.currentCall?.callInfo?.callId else { return }
        self.appDelegate.executeEndCallAction(uuid:callID)
    }
}
// MARK: - UICallScreenDelegate
/**
 Handle Call Screen events
 */
extension ViewController : UICallScreenDelegate {

    func onCallButton() {
        guard let destinationNumber = self.callView.destinationNumberOrSip.text, !destinationNumber.isEmpty else {
            print("ViewController:: onCallButton() ERROR: destination number or SIP user should not be empty")
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
    
    func onHoldUnholdSwitch(isOnHold: Bool) {
        if (isOnHold) {
            self.appDelegate.currentCall?.hold()
        } else {
            self.appDelegate.currentCall?.unhold()
        }
    }

    func onToggleSpeaker(isSpeakerActive: Bool) {
        self.isSpeakerActive = isSpeakerActive
        if (isSpeakerActive) {
            self.telnyxClient?.setSpeaker()
        } else {
            self.telnyxClient?.setEarpiece()
        }
    }
}

// MARK: - Handle connection
extension ViewController {
    private func connectToTelnyx(telnyxToken: String?, sipCredential: SipCredential?, deviceToken: String) {
        guard let telnyxClient = self.telnyxClient else { return }
        
        if telnyxClient.isConnected() {
            telnyxClient.disconnect()
            return
        }
        
        do {
            let txConfig = try createTxConfig(telnyxToken: telnyxToken, sipCredential: sipCredential, deviceToken: deviceToken)
            
            if let serverConfig = serverConfig {
                print("Development Server ")
                try telnyxClient.connect(txConfig: txConfig, serverConfiguration: serverConfig)
            } else {
                print("Production Server ")
                try telnyxClient.connect(txConfig: txConfig)
            }
            
            self.showLoadingView()
        } catch let error {
            print("ViewController:: connect Error \(error)")
        }
    }
    
    private func createTxConfig(telnyxToken: String?, sipCredential: SipCredential?, deviceToken: String) throws -> TxConfig {
        var txConfig: TxConfig? = nil
        
        // Set the connection configuration object.
        // We can login with a user token: https://developers.telnyx.com/docs/v2/webrtc/quickstart
        // Or we can use SIP credentials (SIP user and password)
        if let token = telnyxToken {
            txConfig = TxConfig(token: token,
                                pushDeviceToken: deviceToken,
                                ringtone: "incoming_call.mp3",
                                ringBackTone: "ringback_tone.mp3",
                                pushEnvironment: .production,
                                // You can choose the appropriate verbosity level of the SDK.
                                logLevel: .all,
                                // Enable webrtc stats debug
                                debug: true)
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
                                debug: true)
            
            // Store user / password in user defaults
            SipCredentialsManager.shared.addOrUpdateCredential(credential)
            SipCredentialsManager.shared.saveSelectedCredential(credential)
            self.settingsView.selectCredentialButton.isHidden = false
        }
        
        guard let config = txConfig else {
            throw NSError(domain: "ViewController", code: 1, userInfo: [NSLocalizedDescriptionKey: "No valid credentials provided."])
        }
        
        return config
    }
    
    private func getSelectedSipCredential() -> SipCredential? {
        guard let sipUser = self.settingsView.sipUsernameLabel.text, !sipUser.isEmpty,
              let password = self.settingsView.passwordUserNameLabel.text, !password.isEmpty else {
            return nil
        }
        return SipCredential(username: sipUser, password: password)
    }
    
}


// MARK: - UISettingsViewProtocol
extension ViewController: UISettingsViewDelegate {
    func onOpenSipSelector() {
        self.present(self.sipCredentialsVC, animated: true, completion: nil)
    }
}

// MARK: - SipCredentialsViewControllerDelegate
extension ViewController: SipCredentialsViewControllerDelegate {
    func onNewSipCredential(credential: SipCredential?) {
        let deviceToken = userDefaults.getPushToken()
        guard let sipCredential = credential else {
            print("ViewController:: connectButtonTapped() ERROR: SIP User and Password should not be empty.")
            return
        }
        connectToTelnyx(telnyxToken: nil, sipCredential: sipCredential, deviceToken: deviceToken)
    }

    func onSipCredentialSelected(credential: SipCredential?) {
        self.settingsView.sipUsernameLabel.text = credential?.username ?? ""
        self.settingsView.passwordUserNameLabel.text = credential?.password ?? ""
        
        
        if SipCredentialsManager.shared.getCredentials().isEmpty {
            self.settingsView.selectCredentialButton.isHidden = true
        } else {
            self.settingsView.selectCredentialButton.isHidden = false
        }
    }
}
