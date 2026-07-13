//
//  SSLValidationHelperTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class SSLValidationHelperTests: XCTestCase {

    // MARK: - Local/Loopback

    func testAllowsLocalhost() {
        let url = URL(string: "wss://localhost:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsLocalhostNoPort() {
        let url = URL(string: "wss://localhost")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsLoopback127_0_0_1() {
        let url = URL(string: "wss://127.0.0.1:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsLoopback127_255_255_255() {
        let url = URL(string: "wss://127.255.255.255:443")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    // MARK: - Private Networks

    func testAllowsPrivateNetwork10_x() {
        let url = URL(string: "wss://10.0.0.5:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsPrivateNetwork192_168_x() {
        let url = URL(string: "wss://192.168.1.100:8080")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsPrivateNetwork10_255_255_255() {
        let url = URL(string: "wss://10.255.255.255:443")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsPrivateNetwork192_168_0_0() {
        let url = URL(string: "wss://192.168.0.0:443")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsPrivateNetwork172_16_x() {
        let url = URL(string: "wss://172.16.0.1:443")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testAllowsPrivateNetwork172_31_x() {
        let url = URL(string: "wss://172.31.255.255:443")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsPrivateNetwork172_32_x() {
        let url = URL(string: "wss://172.32.0.1:443")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsPrivateNetwork172_15_x() {
        let url = URL(string: "wss://172.15.0.1:443")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    // MARK: - Non-Local Hosts

    func testRejectsUnknownHost() {
        let url = URL(string: "wss://evil.example.com")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsArbitraryPublicIP() {
        let url = URL(string: "wss://93.184.216.34:443")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsNonTelnyxDomain() {
        let url = URL(string: "wss://example.org:8080")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    // MARK: - Edge Cases

    func testRejectsMalformedURL() {
        let url = URL(string: "wss://")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsURLWithNoHost() {
        let url = URL(string: "wss:///path")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    // MARK: - Hostname Spoofing Prevention

    func testRejectsHostnameSpoof10Prefix() {
        let url = URL(string: "wss://10.evil.com:443")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsHostnameSpoof192_168Prefix() {
        let url = URL(string: "wss://192.168.attacker.com:443")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsHostnameSpoof127Prefix() {
        let url = URL(string: "wss://127.0.0.1.attacker.com:443")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testRejectsHostnameSpoof172Prefix() {
        let url = URL(string: "wss://172.16.evil.com:443")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }
}
