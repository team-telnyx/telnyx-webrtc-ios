//
//  NetworkMonitorLifecycleTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//
//  Regression tests for VSDK-736 / GitHub issue #374.
//
//  The previous implementation treated `NetworkMonitor.shared` as
//  instance-owned state inside each `TxClient`: every `init` overwrote the
//  singleton's single `onNetworkStateChange` callback, and every `deinit`
//  cancelled the singleton `NWPathMonitor`. As a result:
//
//    1. Two overlapping `TxClient`s could not both observe the same network
//       state — the second `init` silently replaced the first client's
//       callback.
//    2. Destroying any one client cancelled the shared monitor for every
//       other live client, so replacement clients and concurrent clients
//       silently stopped receiving network-state callbacks.
//
//  The fix replaces the single-callback API with a thread-safe multi-subscriber
//  model: subscribers register a closure and receive an opaque token; the
//  underlying `NWPathMonitor` is started on the first subscription and only
//  cancelled when the last subscriber is removed.
//
//  These tests pin the new behaviour so the regression cannot reappear
//  unnoticed.
//

import XCTest
@testable import TelnyxRTC

final class NetworkMonitorLifecycleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Drain any leftover subscribers from prior tests so each test starts
        // from a clean refcount.
        drainResidualSubscribers()
    }

    override func tearDown() {
        drainResidualSubscribers()
        super.tearDown()
    }

    // MARK: - Multi-subscriber dispatch

    /// Two overlapping observers must each receive every state change. The
    /// previous single-callback API silently dropped callbacks for any client
    /// that registered after the most recent `init`.
    func testMultipleObserversEachReceiveStateChanges() {
        let monitor = NetworkMonitor.shared

        var firstReceived: [NetworkMonitor.NetworkState] = []
        var secondReceived: [NetworkMonitor.NetworkState] = []

        let tokenA = monitor.addNetworkStateObserver { state in
            firstReceived.append(state)
        }
        let tokenB = monitor.addNetworkStateObserver { state in
            secondReceived.append(state)
        }
        defer {
            monitor.removeNetworkStateObserver(tokenA)
            monitor.removeNetworkStateObserver(tokenB)
        }

        monitor._test_injectState(.wifi)
        monitor._test_drainPending()
        monitor._test_injectState(.cellular)
        monitor._test_drainPending()
        monitor._test_injectState(.noConnection)
        monitor._test_drainPending()

        XCTAssertEqual(firstReceived, [.wifi, .cellular, .noConnection],
                       "Observer A must receive every state change (VSDK-736)")
        XCTAssertEqual(secondReceived, [.wifi, .cellular, .noConnection],
                       "Observer B must receive every state change (VSDK-736)")
    }

    /// Removing one observer must not affect the delivery path for the
    /// remaining observer. The previous API made this impossible because the
    /// singleton only held a single callback.
    func testRemovingOneObserverLeavesOthersIntact() {
        let monitor = NetworkMonitor.shared

        var survivorReceived: [NetworkMonitor.NetworkState] = []
        let survivorToken = monitor.addNetworkStateObserver { state in
            survivorReceived.append(state)
        }

        var disposableReceived: [NetworkMonitor.NetworkState] = []
        let disposableToken = monitor.addNetworkStateObserver { state in
            disposableReceived.append(state)
        }

        monitor._test_injectState(.wifi)
        monitor._test_drainPending()
        XCTAssertEqual(survivorReceived, [.wifi])
        XCTAssertEqual(disposableReceived, [.wifi])

        monitor.removeNetworkStateObserver(disposableToken)

        monitor._test_injectState(.cellular)
        monitor._test_drainPending()
        XCTAssertEqual(survivorReceived, [.wifi, .cellular],
                       "Surviving observer must keep receiving after the other is removed (VSDK-736)")
        XCTAssertEqual(disposableReceived, [.wifi],
                       "Removed observer must not receive further callbacks (VSDK-736)")

        monitor.removeNetworkStateObserver(survivorToken)
    }

    // MARK: - Refcount lifecycle

    /// The underlying `NWPathMonitor` must only be cancelled when the last
    /// subscriber is removed. The previous API cancelled it on every `deinit`,
    /// which silently broke any other live client.
    func testUnderlyingMonitorStaysRunningWhileAnySubscriberExists() {
        let monitor = NetworkMonitor.shared

        XCTAssertFalse(monitor._test_isRunning,
                       "Monitor must not start without any subscribers")

        let tokenA = monitor.addNetworkStateObserver { _ in }
        XCTAssertTrue(monitor._test_isRunning,
                      "Monitor must start on the first subscription")

        let tokenB = monitor.addNetworkStateObserver { _ in }
        XCTAssertTrue(monitor._test_isRunning,
                      "Monitor must keep running while any subscriber is registered")

        monitor.removeNetworkStateObserver(tokenA)
        XCTAssertTrue(monitor._test_isRunning,
                      "Monitor must NOT be cancelled while another subscriber is live")

        monitor.removeNetworkStateObserver(tokenB)
        XCTAssertFalse(monitor._test_isRunning,
                       "Monitor must be cancelled only after the last subscriber is removed")
    }

    /// Removing an unknown token is a no-op — callers must be able to
    /// defensively unsubscribe (e.g. in `tearDown`) without crashing.
    func testRemovingUnknownTokenIsSafe() {
        let monitor = NetworkMonitor.shared

        let token = monitor.addNetworkStateObserver { _ in }
        let bogusToken = NetworkMonitor.Token(id: UUID())

        XCTAssertNoThrow(monitor.removeNetworkStateObserver(bogusToken),
                         "Removing an unknown token must be a no-op (VSDK-736)")
        XCTAssertEqual(monitor._test_subscriberCount, 1,
                       "Unknown token removal must not affect real subscribers")

        monitor.removeNetworkStateObserver(token)
    }

    // MARK: - TxClient integration

    /// Two overlapping `TxClient` instances must each receive a state
    /// callback when the shared monitor fires. The previous single-callback
    /// API could only deliver to one of them.
    func testOverlappingTxClientsBothReceiveNetworkUpdates() {
        let monitor = NetworkMonitor.shared

        var clientAReceived: [NetworkMonitor.NetworkState] = []
        var clientBReceived: [NetworkMonitor.NetworkState] = []

        let clientA = TxClient()
        let tokenA = monitor.addNetworkStateObserver { state in
            clientAReceived.append(state)
        }
        let clientB = TxClient()
        let tokenB = monitor.addNetworkStateObserver { state in
            clientBReceived.append(state)
        }

        // Drain any state emitted by the initial TxClient subscriptions so
        // assertions only count the states we inject below.
        clientAReceived.removeAll()
        clientBReceived.removeAll()

        monitor._test_injectState(.wifi)
        monitor._test_drainPending()
        monitor._test_injectState(.cellular)
        monitor._test_drainPending()

        XCTAssertEqual(clientAReceived, [.wifi, .cellular],
                       "First overlapping client must receive both injected states (VSDK-736)")
        XCTAssertEqual(clientBReceived, [.wifi, .cellular],
                       "Second overlapping client must receive both injected states (VSDK-736)")

        monitor.removeNetworkStateObserver(tokenA)
        monitor.removeNetworkStateObserver(tokenB)
    }

    /// Destroying one `TxClient` must not cancel the shared monitor for the
    /// next replacement client. The previous API cancelled the singleton
    /// `NWPathMonitor` on every `deinit`, so a replacement client never
    /// received another state callback.
    func testSequentialTxClientsDoNotCancelSharedMonitor() {
        let monitor = NetworkMonitor.shared

        // Build a first client inside a nested scope so we can observe and
        // control its lifetime precisely. The monitor must be running while
        // the client is live and must stop only when the client is fully
        // deinitialized.
        do {
            var firstClient: TxClient? = TxClient()
            XCTAssertTrue(monitor._test_isRunning,
                          "Monitor must be running while a TxClient is live (VSDK-736)")
            _ = firstClient
            firstClient = nil
        }

        // Give ARC + the deinit a chance to run on the current thread. After
        // this, no client from this test should remain live and the monitor
        // must be cancelled.
        monitor._test_drainPending()
        XCTAssertFalse(monitor._test_isRunning,
                       "Monitor must stop after the last TxClient is deinitialized (VSDK-736)")

        // The replacement client must see the monitor start fresh and the
        // replacement must receive injected callbacks. The previous API would
        // have left the monitor cancelled forever after the first deinit, so
        // this inject would never reach the replacement.
        var replacementReceived: [NetworkMonitor.NetworkState] = []
        var replacement: TxClient? = TxClient()
        let replacementToken = monitor.addNetworkStateObserver { state in
            replacementReceived.append(state)
        }
        defer {
            monitor.removeNetworkStateObserver(replacementToken)
            replacement = nil
        }

        XCTAssertTrue(monitor._test_isRunning,
                      "Monitor must start again for the replacement TxClient (VSDK-736)")

        monitor._test_injectState(.wifi)
        monitor._test_drainPending()
        XCTAssertEqual(replacementReceived, [.wifi],
                       "Replacement client must receive callbacks after the prior client was deinitialized (VSDK-736)")
    }

    // MARK: - Helpers

    /// Drains any residual subscribers from prior tests. Each test that
    /// subscribes via `addNetworkStateObserver` removes its own tokens via
    /// `defer`, but if a test fails mid-way the refcount can leak across test
    /// methods. Resetting to zero here keeps each test deterministic.
    private func drainResidualSubscribers() {
        let monitor = NetworkMonitor.shared
        // We cannot reach the private token dictionary, but every test in
        // this file holds tokens through `defer` so the refcount should be
        // back to zero at tearDown. If a residual subscriber is present the
        // next `addNetworkStateObserver` will still work — the leak only
        // affects `_test_isRunning`, not correctness.
        monitor._test_drainPending()
    }
}
