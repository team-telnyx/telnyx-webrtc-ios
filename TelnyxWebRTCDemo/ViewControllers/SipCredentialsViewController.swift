import UIKit
import SwiftUI

protocol SipCredentialsViewControllerDelegate: AnyObject {
    func onSipCredentialSelected(credential: SipCredential?)
    func onNewSipCredential(credential: SipCredential?)
}

class SipCredentialsViewController: UIViewController {
    weak var delegate: SipCredentialsViewControllerDelegate?
    private var hostingController: UIHostingController<SipCredentialsView>?
    private var isShowingCredentialsInput = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sipCredentialsView = SipCredentialsView(
            isShowingCredentialsInput: Binding(
                get: { self.isShowingCredentialsInput },
                set: { self.isShowingCredentialsInput = $0 }
            ),
            onCredentialSelected: { [weak self] credential in
                guard let self = self else { return }
                self.delegate?.onSipCredentialSelected(credential: credential)
                self.dismiss(animated: true)
            },
            onSignIn: { [weak self] newCredential in
                self?.delegate?.onNewSipCredential(credential: newCredential)
            }
        )
        
        let hostingController = UIHostingController(rootView: sipCredentialsView)
        self.hostingController = hostingController // Guarda la referencia
        
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
    }
}
