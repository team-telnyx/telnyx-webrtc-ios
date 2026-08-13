//
//  TurnServerConfigurationTests.swift
//  TelnyxRTCTests
//
//  Created by AI Agent on 2026/02/13.
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
import WebRTC
@testable import TelnyxRTC

/// Tests for TURN server configuration to ensure UDP is used as default with TCP as fallback
/// This matches the JS SDK behavior from commit b39750a
class TurnServerConfigurationTests: XCTestCase {
    
    // MARK: - Production ICE Server Tests
    
    /// Test that production ICE servers include both UDP and TCP TURN servers
    func testProdIceServersContainBothTransports() {
        let config = InternalConfig.default
        let iceServers = config.prodWebRTCIceServers
        
        // Should have at least 3 servers: STUN, TURN UDP, TURN TCP
        XCTAssertGreaterThanOrEqual(iceServers.count, 3, "Production should have at least 3 ICE servers (STUN, TURN UDP, TURN TCP)")
        
        // Collect all URL strings from all ICE servers
        let allUrls = iceServers.flatMap { $0.urlStrings }
        
        // Check for UDP TURN server
        let hasUdpTurn = allUrls.contains { $0.contains("turn:") && $0.contains("transport=udp") }
        XCTAssertTrue(hasUdpTurn, "Production ICE servers should include UDP TURN server")
        
        // Check for TCP TURN server
        let hasTcpTurn = allUrls.contains { $0.contains("turn:") && $0.contains("transport=tcp") }
        XCTAssertTrue(hasTcpTurn, "Production ICE servers should include TCP TURN server")
        
        // Check for STUN server
        let hasStun = allUrls.contains { $0.contains("stun:") }
        XCTAssertTrue(hasStun, "Production ICE servers should include STUN server")
    }
    
    /// Test that production UDP TURN server comes before TCP TURN server (UDP is preferred)
    func testProdUdpTurnComesBeforeTcpTurn() {
        let config = InternalConfig.default
        let iceServers = config.prodWebRTCIceServers
        
        var udpTurnIndex: Int?
        var tcpTurnIndex: Int?
        
        for (index, server) in iceServers.enumerated() {
            for url in server.urlStrings {
                if url.contains("turn:") && url.contains("transport=udp") && udpTurnIndex == nil {
                    udpTurnIndex = index
                }
                if url.contains("turn:") && url.contains("transport=tcp") && tcpTurnIndex == nil {
                    tcpTurnIndex = index
                }
            }
        }
        
        guard let udpIndex = udpTurnIndex, let tcpIndex = tcpTurnIndex else {
            XCTFail("Both UDP and TCP TURN servers should be present")
            return
        }
        
        XCTAssertLessThan(udpIndex, tcpIndex, "UDP TURN server should come before TCP TURN server (UDP is preferred for lower latency)")
    }
    
    /// Test production TURN server URLs are correctly formatted
    func testProdTurnServerUrls() {
        XCTAssertTrue(InternalConfig.prodTurnServer.contains("turn:turn.telnyx.com:3478"), "Production TURN server should use turn.telnyx.com:3478")
        XCTAssertTrue(InternalConfig.prodTurnServer.contains("transport=udp"), "Production primary TURN server should use UDP transport")
        XCTAssertTrue(InternalConfig.prodTurnServerTcp.contains("transport=tcp"), "Production fallback TURN server should use TCP transport")
    }
    
    // MARK: - Development ICE Server Tests
    
    /// Test that development ICE servers include both UDP and TCP TURN servers
    func testDevIceServersContainBothTransports() {
        let config = InternalConfig.default
        let iceServers = config.devWebRTCIceServers
        
        // Should have at least 3 servers: STUN, TURN UDP, TURN TCP
        XCTAssertGreaterThanOrEqual(iceServers.count, 3, "Development should have at least 3 ICE servers (STUN, TURN UDP, TURN TCP)")
        
        // Collect all URL strings from all ICE servers
        let allUrls = iceServers.flatMap { $0.urlStrings }
        
        // Check for UDP TURN server
        let hasUdpTurn = allUrls.contains { $0.contains("turn:") && $0.contains("transport=udp") }
        XCTAssertTrue(hasUdpTurn, "Development ICE servers should include UDP TURN server")
        
        // Check for TCP TURN server
        let hasTcpTurn = allUrls.contains { $0.contains("turn:") && $0.contains("transport=tcp") }
        XCTAssertTrue(hasTcpTurn, "Development ICE servers should include TCP TURN server")
        
        // Check for STUN server
        let hasStun = allUrls.contains { $0.contains("stun:") }
        XCTAssertTrue(hasStun, "Development ICE servers should include STUN server")
    }
    
    /// Test that development UDP TURN server comes before TCP TURN server (UDP is preferred)
    func testDevUdpTurnComesBeforeTcpTurn() {
        let config = InternalConfig.default
        let iceServers = config.devWebRTCIceServers
        
        var udpTurnIndex: Int?
        var tcpTurnIndex: Int?
        
        for (index, server) in iceServers.enumerated() {
            for url in server.urlStrings {
                if url.contains("turn:") && url.contains("transport=udp") && udpTurnIndex == nil {
                    udpTurnIndex = index
                }
                if url.contains("turn:") && url.contains("transport=tcp") && tcpTurnIndex == nil {
                    tcpTurnIndex = index
                }
            }
        }
        
        guard let udpIndex = udpTurnIndex, let tcpIndex = tcpTurnIndex else {
            XCTFail("Both UDP and TCP TURN servers should be present")
            return
        }
        
        XCTAssertLessThan(udpIndex, tcpIndex, "UDP TURN server should come before TCP TURN server (UDP is preferred for lower latency)")
    }
    
    /// Test development TURN server URLs are correctly formatted
    func testDevTurnServerUrls() {
        XCTAssertTrue(InternalConfig.devTurnServer.contains("turn:turndev.telnyx.com:3478"), "Development TURN server should use turndev.telnyx.com:3478")
        XCTAssertTrue(InternalConfig.devTurnServer.contains("transport=udp"), "Development primary TURN server should use UDP transport")
        XCTAssertTrue(InternalConfig.devTurnServerTcp.contains("transport=tcp"), "Development fallback TURN server should use TCP transport")
    }

    // MARK: - TURNS 443 Server Tests (VSDK-503)

    /// Test that production ICE servers contain exactly 5 servers including TURNS 443
    func testProdIceServersCountIsFive() {
        let config = InternalConfig.default
        let iceServers = config.prodWebRTCIceServers

        XCTAssertEqual(iceServers.count, 5, "Production should have exactly 5 ICE servers: STUN, Google STUN, TURN UDP, TURN TCP, TURNS 443")
    }

    /// Test that development ICE servers contain exactly 5 servers including TURNS 443
    func testDevIceServersCountIsFive() {
        let config = InternalConfig.default
        let iceServers = config.devWebRTCIceServers

        XCTAssertEqual(iceServers.count, 5, "Development should have exactly 5 ICE servers: STUN, Google STUN, TURN UDP, TURN TCP, TURNS 443")
    }

    /// Test that the 5th production ICE server is TURNS 443
    func testProdTurns443IsPresent() {
        let config = InternalConfig.default
        let iceServers = config.prodWebRTCIceServers

        guard iceServers.count >= 5 else {
            XCTFail("Production should have at least 5 ICE servers")
            return
        }

        let turns443 = iceServers[4]
        let urls = turns443.urlStrings

        XCTAssertTrue(urls.contains("turns:turn.telnyx.com:443?transport=tcp"),
                      "5th production ICE server should be TURNS 443 with turns:turn.telnyx.com:443?transport=tcp")
        XCTAssertEqual(turns443.username, "testuser", "TURNS 443 server should have username 'testuser'")
        XCTAssertNotNil(turns443.credential, "TURNS 443 server should have a credential set")
        XCTAssertEqual(turns443.credential, "testpassword", "TURNS 443 server should have credential 'testpassword'")
    }

    /// Test that the 5th development ICE server is TURNS 443
    func testDevTurns443IsPresent() {
        let config = InternalConfig.default
        let iceServers = config.devWebRTCIceServers

        guard iceServers.count >= 5 else {
            XCTFail("Development should have at least 5 ICE servers")
            return
        }

        let turns443 = iceServers[4]
        let urls = turns443.urlStrings

        XCTAssertTrue(urls.contains("turns:turndev.telnyx.com:443?transport=tcp"),
                      "5th development ICE server should be TURNS 443 with turns:turndev.telnyx.com:443?transport=tcp")
        XCTAssertEqual(turns443.username, "testuser", "TURNS 443 server should have username 'testuser'")
        XCTAssertNotNil(turns443.credential, "TURNS 443 server should have a credential set")
        XCTAssertEqual(turns443.credential, "testpassword", "TURNS 443 server should have credential 'testpassword'")
    }

    /// Test that TURNS 443 is the last entry in both prod and dev arrays
    func testTurns443IsLastInBothArrays() {
        let config = InternalConfig.default
        let prodServers = config.prodWebRTCIceServers
        let devServers = config.devWebRTCIceServers

        XCTAssertFalse(prodServers.isEmpty, "Production ICE servers should not be empty")
        XCTAssertFalse(devServers.isEmpty, "Development ICE servers should not be empty")

        let lastProd = prodServers[prodServers.count - 1]
        let lastDev = devServers[devServers.count - 1]

        XCTAssertTrue(lastProd.urlStrings.contains { $0.contains("turns:") && $0.contains("443") },
                      "Last production ICE server should be TURNS 443")
        XCTAssertTrue(lastDev.urlStrings.contains { $0.contains("turns:") && $0.contains("443") },
                      "Last development ICE server should be TURNS 443")
    }

    /// Test that the full production ICE server ordering is preserved:
    /// STUN → Google STUN → TURN UDP → TURN TCP → TURNS 443
    func testProdIceServerOrdering() {
        let config = InternalConfig.default
        let iceServers = config.prodWebRTCIceServers

        guard iceServers.count == 5 else {
            XCTFail("Production should have exactly 5 ICE servers")
            return
        }

        // Index 0: Telnyx STUN
        XCTAssertTrue(iceServers[0].urlStrings.contains { $0.contains("stun:stun.telnyx.com") },
                      "Index 0 should be Telnyx STUN server")

        // Index 1: Google STUN
        XCTAssertTrue(iceServers[1].urlStrings.contains { $0.contains("stun:stun.l.google.com") },
                      "Index 1 should be Google STUN server")

        // Index 2: TURN UDP
        XCTAssertTrue(iceServers[2].urlStrings.contains { $0.contains("turn:") && $0.contains("transport=udp") },
                      "Index 2 should be TURN UDP server")

        // Index 3: TURN TCP (not TURNS)
        XCTAssertTrue(iceServers[3].urlStrings.contains { $0.contains("turn:") && $0.contains("transport=tcp") && !$0.contains("turns:") },
                      "Index 3 should be TURN TCP server")

        // Index 4: TURNS 443
        XCTAssertTrue(iceServers[4].urlStrings.contains { $0.contains("turns:") && $0.contains("443") },
                      "Index 4 should be TURNS 443 server")
    }

    /// Test that the full development ICE server ordering is preserved:
    /// STUN → Google STUN → TURN UDP → TURN TCP → TURNS 443
    func testDevIceServerOrdering() {
        let config = InternalConfig.default
        let iceServers = config.devWebRTCIceServers

        guard iceServers.count == 5 else {
            XCTFail("Development should have exactly 5 ICE servers")
            return
        }

        // Index 0: Telnyx STUN
        XCTAssertTrue(iceServers[0].urlStrings.contains { $0.contains("stun:stundev.telnyx.com") },
                      "Index 0 should be Telnyx dev STUN server")

        // Index 1: Google STUN
        XCTAssertTrue(iceServers[1].urlStrings.contains { $0.contains("stun:stun.l.google.com") },
                      "Index 1 should be Google STUN server")

        // Index 2: TURN UDP
        XCTAssertTrue(iceServers[2].urlStrings.contains { $0.contains("turn:") && $0.contains("transport=udp") },
                      "Index 2 should be TURN UDP server")

        // Index 3: TURN TCP (not TURNS)
        XCTAssertTrue(iceServers[3].urlStrings.contains { $0.contains("turn:") && $0.contains("transport=tcp") && !$0.contains("turns:") },
                      "Index 3 should be TURN TCP server")

        // Index 4: TURNS 443
        XCTAssertTrue(iceServers[4].urlStrings.contains { $0.contains("turns:") && $0.contains("443") },
                      "Index 4 should be TURNS 443 server")
    }

    // MARK: - STUN Server Tests
    
    /// Test that STUN servers are correctly configured
    func testStunServerConfiguration() {
        XCTAssertEqual(InternalConfig.prodStunServer, "stun:stun.telnyx.com:3478", "Production STUN server should be stun.telnyx.com:3478")
        XCTAssertEqual(InternalConfig.devStunServer, "stun:stundev.telnyx.com:3478", "Development STUN server should be stundev.telnyx.com:3478")
    }
    
    // MARK: - TxServerConfiguration Tests
    
    /// Test that TxServerConfiguration uses the correct ICE servers for production environment
    func testTxServerConfigurationProdEnvironment() {
        let serverConfig = TxServerConfiguration(environment: .production)
        let iceServers = serverConfig.webRTCIceServers
        
        // Should have at least 3 servers
        XCTAssertGreaterThanOrEqual(iceServers.count, 3, "Production TxServerConfiguration should have at least 3 ICE servers")
        
        // Verify UDP and TCP TURN servers are present
        let allUrls = iceServers.flatMap { $0.urlStrings }
        let hasUdpTurn = allUrls.contains { $0.contains("transport=udp") }
        let hasTcpTurn = allUrls.contains { $0.contains("transport=tcp") }
        
        XCTAssertTrue(hasUdpTurn, "Production TxServerConfiguration should include UDP TURN server")
        XCTAssertTrue(hasTcpTurn, "Production TxServerConfiguration should include TCP TURN server")
    }
    
    /// Test that TxServerConfiguration uses the correct ICE servers for development environment
    func testTxServerConfigurationDevEnvironment() {
        let serverConfig = TxServerConfiguration(environment: .development)
        let iceServers = serverConfig.webRTCIceServers
        
        // Should have at least 3 servers
        XCTAssertGreaterThanOrEqual(iceServers.count, 3, "Development TxServerConfiguration should have at least 3 ICE servers")
        
        // Verify UDP and TCP TURN servers are present
        let allUrls = iceServers.flatMap { $0.urlStrings }
        let hasUdpTurn = allUrls.contains { $0.contains("transport=udp") }
        let hasTcpTurn = allUrls.contains { $0.contains("transport=tcp") }
        
        XCTAssertTrue(hasUdpTurn, "Development TxServerConfiguration should include UDP TURN server")
        XCTAssertTrue(hasTcpTurn, "Development TxServerConfiguration should include TCP TURN server")
    }
}
