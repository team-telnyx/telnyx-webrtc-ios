import UIKit
import SwiftUI

protocol SipCredentialsViewControllerDelegate: AnyObject {
    func onSipCredentialSelected(credential: SipCredential?)
}

class SipCredentialsViewController: UIViewController {
    weak var delegate: SipCredentialsViewControllerDelegate?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sipCredentialsView = SipCredentialsView { [weak self] credential in
            self?.delegate?.onSipCredentialSelected(credential: credential)
        }
        
        let hostingController = UIHostingController(rootView: sipCredentialsView)
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
