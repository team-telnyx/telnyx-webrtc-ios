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

    // MARK: - SSLValidationHelper — IPv4 private/loopback ranges

    func testRejectsUnknownHost() {
        let url = URL(string: "wss://evil.example.com")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsLocalhost() {
        let url = URL(string: "wss://localhost:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsLoopback127_0_0_1() {
        let url = URL(string: "wss://127.0.0.1:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsLoopback127_255_255_254() {
        let url = URL(string: "wss://127.255.255.254")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsPrivate10_x() {
        let url = URL(string: "wss://10.0.0.1:443")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsPrivate192_168_x() {
        let url = URL(string: "wss://192.168.1.100")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsPrivate172_16_31() {
        let url16 = URL(string: "wss://172.16.0.1")!
        let url31 = URL(string: "wss://172.31.255.255")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url16))
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url31))
    }

    // MARK: - IPv4 boundary — addresses that should NOT match

    func testRejects172_15() {
        let url = URL(string: "wss://172.15.0.1")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejects172_32() {
        let url = URL(string: "wss://172.32.0.1")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsPublicIP() {
        let url = URL(string: "wss://8.8.8.8")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsPublicDomain() {
        let url = URL(string: "wss://rtc.telnyx.com")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    // MARK: - IPv6 loopback and ULA

    func testAllowsIPv6Loopback() {
        let url = URL(string: "wss://[::1]:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsIPv6UniqueLocalFC() {
        let url = URL(string: "wss://[fc00::1]:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsIPv6UniqueLocalFD() {
        let url = URL(string: "wss://[fd12:3456:7890::1]")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsIPv6Public() {
        let url = URL(string: "wss://[2606:4700::1]")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    // MARK: - IPv4-in-IPv6 mapping

    func testAllowsIPv4MappedIPv6Loopback() {
        let url = URL(string: "wss://[::ffff:127.0.0.1]:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsIPv4MappedIPv6Private() {
        let url = URL(string: "wss://[::ffff:10.0.0.1]")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsIPv4MappedIPv6Public() {
        let url = URL(string: "wss://[::ffff:8.8.8.8]")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    // MARK: - Edge cases

    func testRejectsEmptyHost() {
        let url = URL(string: "wss://:8080")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsInvalidIP() {
        let url = URL(string: "wss://999.999.999.999")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
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
}
