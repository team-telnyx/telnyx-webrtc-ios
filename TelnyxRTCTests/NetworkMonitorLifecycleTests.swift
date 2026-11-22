//
//  NetworkMonitorLifecycleTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//
//  Regression tests for VSDK-736 / GitHub issue #374.
//
//  `TxClient` instances used to share one `NetworkMonitor`. A new client replaced
//  the previous client's callback, and destroying any client cancelled the shared
//  `NWPathMonitor`, which cannot be restarted. Each client now owns its monitor.
//

import XCTest
import Network
@testable import TelnyxRTC

final class NetworkMonitorLifecycleTests: XCTestCase {

    func testCellularToCellularUpdatesAreLoggedWithoutForcingStateChange() {
        let monitor = NetworkMonitor()
        var updates: [[String: Any]] = []
        var states: [NetworkMonitor.NetworkState] = []
        monitor.onPathUpdate = { updates.append($0) }
        monitor.onNetworkStateChange = { states.append($0) }

        monitor.handlePathUpdate(cellularPath())
        monitor.handlePathUpdate(cellularPath())

        XCTAssertEqual(updates.count, 2)
        XCTAssertEqual(states, [.cellular])
        XCTAssertEqual(updates[1]["previousState"] as? String, "cellular")
        XCTAssertEqual(updates[1]["state"] as? String, "cellular")
        XCTAssertEqual(updates[1]["stateChanged"] as? Bool, false)
        XCTAssertEqual(updates[1]["status"] as? String, "satisfied")
    }

    func testCellularConnectivityLossAndReturnRemainVisible() {
        let monitor = NetworkMonitor()
        var updates: [[String: Any]] = []
        var states: [NetworkMonitor.NetworkState] = []
        monitor.onPathUpdate = { updates.append($0) }
        monitor.onNetworkStateChange = { states.append($0) }

        monitor.handlePathUpdate(cellularPath())
        monitor.handlePathUpdate(cellularPath(status: .unsatisfied))
        monitor.handlePathUpdate(cellularPath())

        XCTAssertEqual(states, [.cellular, .noConnection, .cellular])
        XCTAssertEqual(updates[1]["status"] as? String, "unsatisfied")
        XCTAssertEqual(updates[2]["previousState"] as? String, "noConnection")
        XCTAssertTrue(updates.allSatisfy { $0["stateChanged"] as? Bool == true })
    }

    func testRequiresConnectionIsNotClassifiedAsUsableCellular() {
        let monitor = NetworkMonitor()
        var update: [String: Any] = [:]
        monitor.onPathUpdate = { update = $0 }

        monitor.handlePathUpdate(cellularPath(status: .requiresConnection))

        XCTAssertEqual(monitor.currentState, .noConnection)
        XCTAssertEqual(update["status"] as? String, "requiresConnection")
        XCTAssertEqual(update["state"] as? String, "noConnection")
    }

    func testPathDiagnosticsContainOnlySafeSerializableCapabilities() {
        let monitor = NetworkMonitor()
        var update: [String: Any] = [:]
        monitor.onPathUpdate = { update = $0 }

        monitor.handlePathUpdate(cellularPath())

        XCTAssertEqual(Set(update.keys), Set([
            "observedAt", "previousState", "state", "stateChanged", "status",
            "usesWiFi", "usesCellular", "isExpensive", "supportsIPv4", "supportsIPv6", "supportsDNS"
        ]))
        XCTAssertTrue(JSONSerialization.isValidJSONObject(update))
        XCTAssertNotNil(ISO8601DateFormatter().date(from: update["observedAt"] as? String ?? ""))
    }

    private func cellularPath(status: NWPath.Status = .satisfied) -> NetworkMonitor.PathSnapshot {
        NetworkMonitor.PathSnapshot(
            status: status, usesWiFi: false, usesCellular: true, isExpensive: true,
            supportsIPv4: true, supportsIPv6: true, supportsDNS: true
        )
    }

    func testEachTxClientOwnsItsNetworkMonitor() {
        let firstClient = TxClient()
        let secondClient = TxClient()

        XCTAssertFalse(firstClient.networkMonitor === secondClient.networkMonitor,
                       "Clients must not share a monitor, since cancelling it is permanent (VSDK-736)")
    }

    /// Creating a second client must not replace the first client's callback. A
    /// client with no active calls reports network loss through its delegate.
    func testOverlappingTxClientsEachKeepTheirNetworkCallback() {
        let firstDelegate = DisconnectDelegate(description: "First client notified")
        let secondDelegate = DisconnectDelegate(description: "Second client notified")
        let firstClient = TxClient()
        firstClient.delegate = firstDelegate
        let secondClient = TxClient()
        secondClient.delegate = secondDelegate

        firstClient.networkMonitor.onNetworkStateChange?(.noConnection)
        secondClient.networkMonitor.onNetworkStateChange?(.noConnection)

        wait(for: [firstDelegate.disconnected, secondDelegate.disconnected], timeout: 2.0)
    }

    /// Destroying a client must not keep it alive or affect a client that outlives it.
    func testDestroyingTxClientDoesNotAffectAnotherClient() {
        let delegate = DisconnectDelegate(description: "Surviving client notified")
        let survivor = TxClient()
        survivor.delegate = delegate

        var destroyedClient: TxClient? = TxClient()
        weak var weakDestroyedClient = destroyedClient
        destroyedClient = nil
        XCTAssertNil(weakDestroyedClient, "The monitor must not keep a destroyed client alive")

        survivor.networkMonitor.onNetworkStateChange?(.noConnection)

        wait(for: [delegate.disconnected], timeout: 2.0)
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
