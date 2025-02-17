import Network
import Foundation

class NetworkMonitor {
    static let shared = NetworkMonitor() // Singleton instance
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    // Enum to represent network state
    enum NetworkState {
        case wifi
        case cellular
        case noConnection
    }
    
    private(set) var currentState: NetworkState = .noConnection
    
    // Closure to notify when network state changes
    var onNetworkStateChange: ((NetworkState) -> Void)?
    
    private init() {
        // Set up the path update handler
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            let newState: NetworkState
            
            if path.status == .satisfied {
                if path.usesInterfaceType(.wifi) {
                    newState = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    newState = .cellular
                } else {
                    // If satisfied but no specific interface, assume Wi-Fi (or handle as needed)
                    newState = .wifi
                }
            } else if !path.usesInterfaceType(.wifi) && !path.usesInterfaceType(.cellular) {
                // Airplane mode or no interfaces available
                newState = .noConnection
            } else {
                // No connection
                newState = .noConnection
            }
            
            // Check if the state has changed
            if self.currentState != newState {
                self.currentState = newState
                
                // Notify the listener
                self.onNetworkStateChange?(self.currentState)
            }
        }
    }
    
    // Start monitoring
    func startMonitoring() {
        monitor.start(queue: queue)
    }
    
    // Stop monitoring
    func stopMonitoring() {
        monitor.cancel()
    }
}
