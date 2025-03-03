import Network
import Foundation
import SystemConfiguration

class NetworkMonitor {
    static let shared = NetworkMonitor() // Singleton instance
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    // Enum to represent network state
    enum NetworkState {
        case wifi
        case cellular
        case vpn
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
                    // If satisfied but no specific interface, assume VPN
                    newState = .vpn
                }
                
                // Check for actual internet connectivity when VPN is active
                if newState == .vpn {
                    self.checkInternetAccess { hasInternet in
                        if !hasInternet {
                            // No internet despite VPN being active
                            self.updateState(.noConnection)
                        } else {
                            // Internet is available
                            self.updateState(newState)
                        }
                    }
                } else {
                    // For Wi-Fi or cellular, assume internet is available
                    self.updateState(newState)
                }
            } else {
                // No connection
                self.updateState(.noConnection)
            }
        }
        
    }



    private func updateState(_ newState: NetworkState) {
        if self.currentState != newState {
            self.currentState = newState
            self.onNetworkStateChange?(self.currentState)
        }
    }
    


    private func checkInternetAccess(completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://www.google.com")! // Use a reliable server
        let request = URLRequest(url: url, timeoutInterval: 1) // Set a timeout

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Internet is reachable
                completion(true)
            } else {
                // No internet
                completion(false)
            }
        }
        task.resume()
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
