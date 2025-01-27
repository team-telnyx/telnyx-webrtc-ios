import UIKit
import SwiftUI

class HomeViewController: UIViewController {
    private var hostingController: UIHostingController<HomeView>?
    let sipCredentialsVC = SipCredentialsViewController()
    
    // ✅ Usamos un ObservableObject para manejar el estado
    private var viewModel = HomeViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let homeView = HomeView(viewModel: viewModel,
                                onAddProfile: { [weak self] in
            self?.handleAddProfile()
        },
                                onSwitchProfile: { [weak self] in
            self?.handleSwitchProfile()
        },
                                onConnect: { [weak self] in
            self?.handleConnect()
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
