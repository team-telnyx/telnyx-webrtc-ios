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
//       other live client, and a cancelled `NWPathMonitor` cannot be restarted,
//       so replacement clients silently stopped receiving network changes.
//
//  The fix replaces the single-callback API with a multi-subscriber model:
//  subscribers register a closure and receive an opaque token. The underlying
//  `NWPathMonitor` starts on the first subscription and is never cancelled.
//
//  `NetworkMonitor.shared` is a process-wide singleton that also receives real
//  path updates during tests, and clients from other suites may still be
//  subscribed. These tests therefore inject `.cellular` for observer delivery,
//  which a simulator never reports by itself, and never assert an absolute
//  subscriber count.
//

import XCTest
@testable import TelnyxRTC

final class NetworkMonitorLifecycleTests: XCTestCase {

    // MARK: - Multi-subscriber dispatch

    /// Two overlapping observers must each receive every injected state. The
    /// previous single-callback API silently dropped callbacks for any client
    /// that registered before the most recent `init`.
    func testMultipleObserversEachReceiveStateChanges() {
        let monitor = NetworkMonitor.shared
        let first = StateRecorder()
        let second = StateRecorder()

        let tokenA = monitor.addNetworkStateObserver(first.record)
        let tokenB = monitor.addNetworkStateObserver(second.record)
        defer {
            monitor.removeNetworkStateObserver(tokenA)
            monitor.removeNetworkStateObserver(tokenB)
        }

        monitor.injectStateForTesting(.cellular)
        monitor.injectStateForTesting(.cellular)

        XCTAssertEqual(first.cellularCount, 2, "Observer A must receive every state (VSDK-736)")
        XCTAssertEqual(second.cellularCount, 2, "Observer B must receive every state (VSDK-736)")
    }

    /// Removing one observer must not affect delivery to the remaining observer.
    func testRemovingOneObserverLeavesOthersIntact() {
        let monitor = NetworkMonitor.shared
        let survivor = StateRecorder()
        let removed = StateRecorder()

        let survivorToken = monitor.addNetworkStateObserver(survivor.record)
        let removedToken = monitor.addNetworkStateObserver(removed.record)
        defer { monitor.removeNetworkStateObserver(survivorToken) }

        monitor.injectStateForTesting(.cellular)
        monitor.removeNetworkStateObserver(removedToken)
        monitor.injectStateForTesting(.cellular)

        XCTAssertEqual(survivor.cellularCount, 2,
                       "Surviving observer must keep receiving after the other is removed (VSDK-736)")
        XCTAssertEqual(removed.cellularCount, 1,
                       "Removed observer must not receive further callbacks (VSDK-736)")
    }

    /// Removing a token that is already gone is a no-op and must not affect
    /// other subscribers.
    func testRemovingStaleTokenLeavesOtherObserversIntact() {
        let monitor = NetworkMonitor.shared
        let survivor = StateRecorder()

        let survivorToken = monitor.addNetworkStateObserver(survivor.record)
        defer { monitor.removeNetworkStateObserver(survivorToken) }
        let staleToken = monitor.addNetworkStateObserver { _ in }

        monitor.removeNetworkStateObserver(staleToken)
        let countAfterFirstRemoval = monitor.subscriberCountForTesting
        monitor.removeNetworkStateObserver(staleToken)

        XCTAssertEqual(monitor.subscriberCountForTesting, countAfterFirstRemoval,
                       "Removing a stale token must not remove another subscriber (VSDK-736)")
        monitor.injectStateForTesting(.cellular)
        XCTAssertEqual(survivor.cellularCount, 1)
    }

    // MARK: - Native monitor lifetime

    /// A cancelled `NWPathMonitor` cannot be restarted, so removing the last
    /// observer must never cancel it. Otherwise a replacement client would
    /// never receive another real network change.
    func testRemovingLastObserverDoesNotStopNativeMonitor() {
        let monitor = NetworkMonitor.shared

        let token = monitor.addNetworkStateObserver { _ in }
        XCTAssertTrue(monitor.isRunningForTesting, "Monitor must start on the first subscription")

        monitor.removeNetworkStateObserver(token)
        monitor.drainPendingForTesting()

        XCTAssertTrue(monitor.isRunningForTesting,
                      "Monitor must keep running with no subscribers (VSDK-736)")
    }

    // MARK: - Re-entrancy

    /// An observer unsubscribing itself runs on the monitor queue, the same
    /// context as a `TxClient` `deinit` that ends up on that queue. It must not
    /// trap on a synchronous dispatch to the queue it is already running on.
    func testObserverCanRemoveItselfFromCallback() {
        let monitor = NetworkMonitor.shared
        let recorder = StateRecorder()
        var token: NetworkMonitor.Token?

        token = monitor.addNetworkStateObserver { state in
            recorder.record(state)
            if state == .cellular, let token = token {
                monitor.removeNetworkStateObserver(token)
            }
        }

        monitor.injectStateForTesting(.cellular)
        monitor.drainPendingForTesting()
        monitor.injectStateForTesting(.cellular)

        XCTAssertEqual(recorder.cellularCount, 1,
                       "Observer must stop receiving after removing itself (VSDK-736)")
    }

    /// An observer may also register another observer from its callback. The
    /// new observer starts with the next state, not the one being delivered.
    func testObserverCanAddObserverFromCallback() {
        let monitor = NetworkMonitor.shared
        let added = StateRecorder()
        var addedToken: NetworkMonitor.Token?

        let token = monitor.addNetworkStateObserver { state in
            if state == .cellular, addedToken == nil {
                addedToken = monitor.addNetworkStateObserver(added.record)
            }
        }
        defer {
            monitor.removeNetworkStateObserver(token)
            if let addedToken = addedToken {
                monitor.removeNetworkStateObserver(addedToken)
            }
        }

        monitor.injectStateForTesting(.cellular)
        monitor.drainPendingForTesting()
        XCTAssertEqual(added.cellularCount, 0)

        monitor.injectStateForTesting(.cellular)
        XCTAssertEqual(added.cellularCount, 1,
                       "Observer added from a callback must receive the next state (VSDK-736)")
    }

    // MARK: - TxClient integration

    /// Two overlapping `TxClient`s must each act on a network change. The
    /// previous API replaced the first client's callback when the second was
    /// created. A client with no active calls reports loss through its delegate.
    func testOverlappingTxClientsBothReceiveNetworkLoss() {
        let firstDelegate = DisconnectDelegate(description: "First client notified")
        let secondDelegate = DisconnectDelegate(description: "Second client notified")
        let firstClient = TxClient()
        firstClient.delegate = firstDelegate
        let secondClient = TxClient()
        secondClient.delegate = secondDelegate

        NetworkMonitor.shared.injectStateForTesting(.noConnection)

        wait(for: [firstDelegate.disconnected, secondDelegate.disconnected], timeout: 2.0)
        withExtendedLifetime((firstClient, secondClient, firstDelegate, secondDelegate)) {}
    }

    /// Destroying a client must remove only its own subscription and leave a
    /// replacement client working. The previous API cancelled the singleton
    /// `NWPathMonitor` on every `deinit`.
    func testReplacementTxClientReceivesNetworkLossAfterPreviousClientIsDestroyed() {
        let monitor = NetworkMonitor.shared
        monitor.drainPendingForTesting()
        let subscribersBeforeClient = monitor.subscriberCountForTesting

        var firstClient: TxClient? = TxClient()
        weak var weakFirstClient = firstClient
        firstClient = nil

        XCTAssertNil(weakFirstClient, "The monitor must not keep a destroyed client alive")
        XCTAssertLessThanOrEqual(monitor.subscriberCountForTesting, subscribersBeforeClient,
                                 "Destroying a client must remove its subscription (VSDK-736)")
        XCTAssertTrue(monitor.isRunningForTesting,
                      "Destroying a client must not stop the native monitor (VSDK-736)")

        let delegate = DisconnectDelegate(description: "Replacement client notified")
        let replacement = TxClient()
        replacement.delegate = delegate

        monitor.injectStateForTesting(.noConnection)

        wait(for: [delegate.disconnected], timeout: 2.0)
        withExtendedLifetime((replacement, delegate)) {}
    }
}

// MARK: - Helpers

/// Records states on the monitor queue. Reading a count drains that queue, so
/// the test thread only reads after every queued delivery has finished.
private final class StateRecorder {
    private var states: [NetworkMonitor.NetworkState] = []

    func record(_ state: NetworkMonitor.NetworkState) {
        states.append(state)
    }

    /// Ignores states from real path updates, which can arrive at any time.
    var cellularCount: Int {
        NetworkMonitor.shared.drainPendingForTesting()
        return states.filter { $0 == .cellular }.count
    }
}

private final class DisconnectDelegate: MockTxClientDelegate {
    let disconnected: XCTestExpectation

    init(description: String) {
        disconnected = XCTestExpectation(description: description)
        // A real network drop during the test may also notify this delegate.
        disconnected.assertForOverFulfill = false
    }

    override func onSocketDisconnected() {
        disconnected.fulfill()
    }
}
