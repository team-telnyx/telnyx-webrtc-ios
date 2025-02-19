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
                    // If satisfied. however can be satisfied by vpn
                    if(hasInternetAccess()){
                        newState = .vpn
                    } else {
                        newState = .noConnection
                    }
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
    

    private func hasInternetAccess() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return isReachable && !needsConnection
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
