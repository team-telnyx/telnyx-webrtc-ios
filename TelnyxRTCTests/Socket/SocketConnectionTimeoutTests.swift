//
//  SocketConnectionTimeoutTests.swift
//  TelnyxRTCTests
//
//  Created by Claude on 10/06/2026.
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

/// Tests for the unconditional connection-timeout watchdog and redial behavior.
///
/// Regression coverage for the bug where `Socket.connect()` never timed out on the
/// default prod URL (`wss://rtc.telnyx.com`): the 5s watchdog only started when a
/// region fallback was possible, and `"rtc"` is not a valid region, so a stalled
/// handshake (e.g. a lost SYN on cellular after a VoIP push) sat on the kernel's TCP
/// retransmit backoff with no redial.
class SocketConnectionTimeoutTests: XCTestCase {

    private var delegate: MockRegionSocketDelegate!

    override func setUpWithError() throws {
        delegate = MockRegionSocketDelegate()
    }

    override func tearDownWithError() throws {
        delegate = nil
    }

    /// On the default prod URL the watchdog must still fire and redial the same
    /// server (no region override), since there is no region to fall back from.
    func testConnectionTimeoutRedialsOnDefaultProdURL() {
        let socket = Socket()
        socket.delegate = delegate
        socket.signalingServer = InternalConfig.default.prodSignalingServer

        socket.handleConnectionTimeout()

        XCTAssertTrue(delegate.onSocketDisconnectedCalled, "Timeout should trigger a disconnect/redial")
        XCTAssertEqual(delegate.lastReconnectValue, true, "Timeout should request a reconnect")
        XCTAssertNil(delegate.lastRegionValue, "Default prod URL has no region to fall back from; should redial the same server (region nil)")
    }

    /// On a specific regional URL the watchdog must redial with a fallback to the
    /// auto region (preserving the original fallback behavior).
    func testConnectionTimeoutFallsBackToAutoForRegionalURL() {
        let socket = Socket()
        socket.delegate = delegate
        socket.signalingServer = URL(string: "wss://eu.rtc.telnyx.com")!

        socket.handleConnectionTimeout()

        XCTAssertTrue(delegate.onSocketDisconnectedCalled, "Timeout should trigger a disconnect/redial")
        XCTAssertEqual(delegate.lastReconnectValue, true, "Timeout should request a reconnect")
        XCTAssertEqual(delegate.lastRegionValue, .auto, "Regional URL should fall back to the auto region")
    }

    /// The watchdog timer must start for every connect, including the default prod
    /// URL where no region fallback is possible.
    func testConnectionTimeoutStartsOnDefaultProdURL() {
        let socket = Socket()
        socket.delegate = delegate
        socket.connect(signalingServer: InternalConfig.default.prodSignalingServer)

        // The timer is scheduled synchronously inside connect(), before the network
        // can respond, so it must be active immediately on return.
        XCTAssertTrue(socket.isConnectionTimeoutActive, "Watchdog timer must start unconditionally, even on the default prod URL")

        socket.disconnect(reconnect: false)
    }
}
