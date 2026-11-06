import Network
import Foundation
import SystemConfiguration

/// Thread-safe, multi-subscriber network monitor.
///
/// `NetworkMonitor` is shared across all `TxClient` instances in the process.
/// Subscribers register a callback and receive an opaque token. The underlying
/// `NWPathMonitor` starts on the first subscription and then runs for the rest
/// of the process, because a cancelled `NWPathMonitor` cannot be restarted. This
/// avoids the previous bug where each new `TxClient` replaced the singleton's
/// `onNetworkStateChange` callback and each `deinit` cancelled the singleton
/// `NWPathMonitor` for every other live and future client.
///
/// All subscriber mutation is dispatched asynchronously onto the monitor's
/// private queue, so adding or removing an observer is safe from any thread,
/// including from inside an observer callback or a `TxClient` `deinit` running
/// on that queue. Subscriber callbacks are dispatched on the same queue —
/// callers that need main-thread behaviour must hop themselves (the legacy
/// single-callback implementation already required `TxClient` to dispatch to
/// Main inside its handler, and this implementation preserves that contract).
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    // MARK: - Public types

    /// Network connectivity classification used by subscribers.
    enum NetworkState {
        case wifi
        case cellular
        case vpn
        case noConnection
    }

    /// Opaque subscription token. Hold it until you want to unsubscribe via
    /// `removeNetworkStateObserver(_:)`.
    final class Token: Hashable {
        fileprivate let id: UUID
        fileprivate init(id: UUID) { self.id = id }

        static func == (lhs: Token, rhs: Token) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    // MARK: - Internal state

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    /// Live subscriber map. Only read or mutated on `queue`.
    private var subscribers: [Token: (NetworkState) -> Void] = [:]
    /// `true` once the underlying `NWPathMonitor` has started. It is never
    /// cancelled, so this never returns to `false`.
    private var isRunning = false

    /// Last observed network state. Treat as a snapshot from any thread.
    private(set) var currentState: NetworkState = .noConnection

    // MARK: - Init

    private init() {
        // Set up the path update handler. The handler is invoked on `queue`,
        // so it is safe to read/modify `subscribers` / `currentState` directly
        // from here without additional locking.
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

                // Check for actual internet connectivity when VPN is active.
                // Skip the request when no client is alive to act on the result.
                if newState == .vpn && !self.subscribers.isEmpty {
                    self.checkInternetAccess { hasInternet in
                        self.queue.async {
                            if !hasInternet {
                                self.updateState(.noConnection)
                            } else {
                                self.updateState(newState)
                            }
                        }
                    }
                } else {
                    // For Wi-Fi or cellular, assume internet is available.
                    // An unverified VPN state has no effect without subscribers.
                    self.updateState(newState)
                }
            } else {
                // No connection
                self.updateState(.noConnection)
            }
        }
    }

    // MARK: - Public API

    /// Register a network-state observer. Starts the underlying
    /// `NWPathMonitor` on the first subscription.
    ///
    /// - Parameter observer: Called on the monitor's private queue when the
    ///   network state changes. The observer must not retain itself through
    ///   the captured closure — `TxClient` uses `[weak self]` to break the
    ///   cycle.
    /// - Returns: A token. Hold it until you want to unsubscribe via
    ///   `removeNetworkStateObserver(_:)`.
    @discardableResult
    func addNetworkStateObserver(_ observer: @escaping (NetworkState) -> Void) -> Token {
        let token = Token(id: UUID())
        queue.async {
            self.subscribers[token] = observer
            if !self.isRunning {
                self.isRunning = true
                self.monitor.start(queue: self.queue)
            }
        }
        return token
    }

    /// Unsubscribe a previously-registered observer. Safe to call with an
    /// unknown token (no-op). The underlying `NWPathMonitor` keeps running so a
    /// later subscriber still receives network changes.
    func removeNetworkStateObserver(_ token: Token) {
        queue.async {
            self.subscribers.removeValue(forKey: token)
        }
    }

    // MARK: - Private helpers

    /// Called on `queue`.
    private func updateState(_ newState: NetworkState) {
        guard currentState != newState else { return }
        currentState = newState
        for callback in subscribers.values {
            callback(newState)
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

    // MARK: - Test hooks
    //
    // These are intentionally `internal` so the `@testable` test target can
    // drive deterministic state changes without depending on real network
    // transitions. Production callers must not use them.

    /// Synchronously drain pending work on the monitor queue. No-op in
    /// production. Used by regression tests to make subscriber dispatch
    /// deterministic without spinning the run loop.
    func _test_drainPending() {
        queue.sync { }
    }

    /// Current number of registered subscribers. Test-only.
    var _test_subscriberCount: Int {
        queue.sync { subscribers.count }
    }

    /// Deliver a state directly to observers, bypassing `NWPathMonitor` and the
    /// duplicate-state check, so delivery does not depend on the real network.
    /// Does not change `currentState`. Test-only.
    func _test_injectState(_ newState: NetworkState) {
        queue.sync {
            for callback in subscribers.values {
                callback(newState)
            }
        }
    }

    /// Whether the underlying `NWPathMonitor` has been started. Test-only.
    var _test_isRunning: Bool {
        queue.sync { isRunning }
    }
}
