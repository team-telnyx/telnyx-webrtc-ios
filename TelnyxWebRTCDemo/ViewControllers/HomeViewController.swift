import UIKit
import SwiftUI

class HomeViewController: UIViewController {
    private var hostingController: UIHostingController<HomeView>?
    
    @State private var socketState: SocketState = .disconnected
    @State private var selectedProfile: SipCredential? = nil
    @State private var sessionId: String = "-"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let homeView = HomeView(
            socketState: Binding(get: { self.socketState }, set: { self.socketState = $0 }),
            selectedProfile: Binding(get: { self.selectedProfile }, set: { self.selectedProfile = $0 }),
            sessionId: Binding(get: { self.sessionId }, set: { self.sessionId = $0 }),
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
    
    private func handleAddProfile() {
        // Implementa la lógica para agregar un perfil
        print("Add Profile tapped")
    }
    
    private func handleSwitchProfile() {
        // Implementa la lógica para cambiar de perfil
        print("Switch Profile tapped")
    }
    
    private func handleConnect() {
        // Implementa la lógica para conectar
        print("Connect tapped")
    }
}
