import Network
import Foundation
import SystemConfiguration

class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    enum NetworkState: String {
        case wifi
        case cellular
        case vpn
        case noConnection
    }

    /// Only path capabilities are recorded: no addresses, interface names or
    /// cellular radio technology. NWPath does not identify an SA/NSA handover.
    struct PathSnapshot {
        let status: NWPath.Status
        let usesWiFi: Bool
        let usesCellular: Bool
        let isExpensive: Bool
        let supportsIPv4: Bool
        let supportsIPv6: Bool
        let supportsDNS: Bool

        var state: NetworkState {
            guard status == .satisfied else { return .noConnection }
            if usesWiFi { return .wifi }
            if usesCellular { return .cellular }
            return .vpn
        }

        var statusDescription: String {
            switch status {
            case .satisfied: return "satisfied"
            case .unsatisfied: return "unsatisfied"
            case .requiresConnection: return "requiresConnection"
            @unknown default: return "unknown"
            }
        }
    }

    private(set) var currentState: NetworkState = .noConnection

    var onNetworkStateChange: ((NetworkState) -> Void)?
    /// Every OS path update, including updates suppressed by coarse state deduplication.
    var onPathUpdate: (([String: Any]) -> Void)?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(PathSnapshot(
                status: path.status,
                usesWiFi: path.usesInterfaceType(.wifi),
                usesCellular: path.usesInterfaceType(.cellular),
                isExpensive: path.isExpensive,
                supportsIPv4: path.supportsIPv4,
                supportsIPv6: path.supportsIPv6,
                supportsDNS: path.supportsDNS
            ))
        }
    }

    /// Kept separate from NWPath construction so diagnostics and callback policy
    /// can be tested without depending on the host's actual network interface.
    func handlePathUpdate(_ snapshot: PathSnapshot) {
        let newState = snapshot.state
        let context: [String: Any] = [
            "observedAt": ISO8601DateFormatter().string(from: Date()),
            "previousState": currentState.rawValue,
            "state": newState.rawValue,
            "stateChanged": currentState != newState,
            "status": snapshot.statusDescription,
            "usesWiFi": snapshot.usesWiFi,
            "usesCellular": snapshot.usesCellular,
            "isExpensive": snapshot.isExpensive,
            "supportsIPv4": snapshot.supportsIPv4,
            "supportsIPv6": snapshot.supportsIPv6,
            "supportsDNS": snapshot.supportsDNS
        ]
        Logger.log.i(message: "[NETWORK-PATH] \(context)")
        onPathUpdate?(context)

        // Preserve the existing recovery policy: observing another cellular
        // path update is diagnostic evidence, not a reason to force reattach.
        if newState == .vpn {
            checkInternetAccess { [weak self] hasInternet in
                self?.updateState(hasInternet ? newState : .noConnection)
            }
        } else {
            updateState(newState)
        }
    }

    private func updateState(_ newState: NetworkState) {
        if currentState != newState {
            currentState = newState
            onNetworkStateChange?(currentState)
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

    func startMonitoring() {
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
