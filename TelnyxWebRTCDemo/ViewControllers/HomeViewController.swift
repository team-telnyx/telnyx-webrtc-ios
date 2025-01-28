import UIKit
import SwiftUI
import TelnyxRTC

class HomeViewController: UIViewController {
    private var hostingController: UIHostingController<HomeView>?
    let sipCredentialsVC = SipCredentialsViewController()
    
    private var viewModel = HomeViewModel()

    var telnyxClient: TxClient?
    var userDefaults: UserDefaults = UserDefaults.init()
    var serverConfig: TxServerConfiguration?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.telnyxClient = appDelegate.telnyxClient

        let homeView = HomeView(viewModel: viewModel,
                                onAddProfile: { [weak self] in
            self?.handleAddProfile()
        },
                                onSwitchProfile: { [weak self] in
            self?.handleSwitchProfile()
        },
                                onConnect: { [weak self] in
            self?.handleConnect()
        },
                                onLongPressLogo: { [weak self] in
            self?.showHiddenOptions()
        }
        )
        
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
        self.initEnvironment()
    }
    
    private func handleAddProfile() {
        print("Add Profile tapped")
        self.present(self.sipCredentialsVC, animated: true, completion: nil)
    }
    
    private func handleSwitchProfile() {
        print("Switch Profile tapped")
        self.present(self.sipCredentialsVC, animated: true, completion: nil)
    }
    
    private func handleConnect() {
        print("Connect tapped")
    }
}

// MARK: - VIEWS
extension HomeViewController {
    func initViews() {
        self.sipCredentialsVC.delegate = self
        self.hideKeyboardWhenTappedAround()
    }
}

// MARK: - SipCredentialsViewControllerDelegate
extension HomeViewController: SipCredentialsViewControllerDelegate {
    func onNewSipCredential(credential: SipCredential?) {
        DispatchQueue.main.async {
            self.viewModel.selectedProfile = credential
        }
    }
    
    func onSipCredentialSelected(credential: SipCredential?) {
        DispatchQueue.main.async {
            self.viewModel.selectedProfile = credential
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
