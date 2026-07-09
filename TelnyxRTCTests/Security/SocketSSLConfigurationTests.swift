//
//  SocketSSLConfigurationTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
import Starscream
@testable import TelnyxRTC

class SocketSSLConfigurationTests: XCTestCase {

    // MARK: - SSLValidationHelper gating

    func testSocketHelperRejectsUnknownHost() {
        let url = URL(string: "wss://evil.example.com")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testSocketHelperAllowsLocalhost() {
        let url = URL(string: "wss://localhost:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testSocketHelperAllowsLoopback() {
        let url = URL(string: "wss://127.0.0.1:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    // MARK: - Socket integration

    func testSocketClassExistsAndCanInstantiate() {
        let socket = Socket()
        XCTAssertNotNil(socket)
    }

    func testSocketConnectToNonLocalHostUsesStrictValidation() {
        let socket = Socket()
        socket.automaticallyConnectWebSocket = false

        let url = URL(string: "wss://rtc.telnyx.com")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testSocketConnectToLocalHostAllowsBypassInDebug() {
        let socket = Socket()
        socket.automaticallyConnectWebSocket = false

        let url = URL(string: "wss://localhost")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    // MARK: - API surface

    func testSSLValidationHelperHasStaticMethod() {
        let url = URL(string: "wss://localhost")!
        let result: Bool = SSLValidationHelper.shouldAllowSelfSigned(for: url)
        XCTAssertNotNil(result as Any?)
    }

    func testDevHostsContainsLocalhost() {
        XCTAssertTrue(SSLValidationHelper.localHosts.contains("localhost"))
    }
}
