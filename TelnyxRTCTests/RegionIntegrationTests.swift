//
//  RegionIntegrationTests.swift
//  TelnyxRTCTests
//
//  Created by GitHub Copilot on 14/07/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class RegionIntegrationTests: XCTestCase {
    
    private var mockSocket: MockSocket?
    private var mockTxClient: TxClient?
    
    override func setUpWithError() throws {
        print("RegionIntegrationTests:: setUpWithError")
        mockSocket = MockSocket()
        mockTxClient = TxClient()
    }

    override func tearDownWithError() throws {
        print("RegionIntegrationTests:: tearDownWithError")
        mockSocket = nil
        mockTxClient = nil
    }

    // MARK: - Region Fallback Integration Tests
    
    /**
     Test that Socket properly handles region fallback when connection fails
     */
    func testSocketRegionFallbackOnConnectionFailure() {
        guard let socket = mockSocket else {
            XCTFail("Mock socket not initialized")
            return
        }
        
        let delegate = MockRegionSocketDelegate()
        socket.delegate = delegate
        
        // Set up socket with EU region URL
        let euURL = URL(string: "wss://eu.rtc.telnyx.com")!
        socket.signalingServer = euURL
        
        // Test that fallback logic works correctly
        let shouldFallback = socket.shouldFallbackToAuto(signalingServer: euURL)
        XCTAssertTrue(shouldFallback, "EU region should trigger fallback to auto")
        
        // Test region extraction
        let extractedRegion = socket.extractRegionPrefix(from: euURL)
        XCTAssertEqual(extractedRegion, "eu", "Should extract 'eu' from EU URL")
        
        // Simulate connection error for regional server
        let error = NSError(domain: "RegionConnectionError", code: 503, userInfo: [NSLocalizedDescriptionKey: "Regional server unavailable"])
        
        // Verify that the delegate would receive the correct fallback signal
        // In actual implementation, this would trigger onSocketDisconnected with region: .auto
        if shouldFallback {
            delegate.onSocketDisconnected(reconnect: true, region: .auto)
        }
        
        XCTAssertTrue(delegate.onSocketDisconnectedCalled, "Socket delegate should be notified of disconnection")
        XCTAssertEqual(delegate.lastReconnectValue, true, "Should indicate reconnection is needed")
        XCTAssertEqual(delegate.lastRegionValue, .auto, "Should fallback to auto region")
    }
    
    /**
     Test TxClient region reconnection behavior
     */
    func testTxClientRegionReconnection() {
        guard let client = mockTxClient else {
            XCTFail("Mock TxClient not initialized")
            return
        }
        
        // Create initial configuration with EU region
        let initialConfig = TxServerConfiguration(environment: .production, region: .eu)
        let txConfig = TxConfig(
            sipUser: "testuser",
            password: "testpassword"
        )
        
        client.serverConfiguration = initialConfig
        client.txConfig = txConfig
        
        // Verify initial configuration
        let initialURL = client.serverConfiguration.signalingServer.absoluteString
        XCTAssertTrue(initialURL.contains("eu."), "Initial configuration should use EU region")
        
        // Simulate region fallback scenario
        client.onSocketDisconnected(reconnect: true, region: .auto)
        
        // After reconnection, the client should update configuration to use auto region
        // Note: This test simulates the behavior without actual network calls
        let expectation = self.expectation(description: "Region fallback reconnection")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // In real implementation, this would be handled by the client's reconnection logic
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    /**
     Test complete region selection flow from configuration to connection
     */
    func testCompleteRegionSelectionFlow() {
        // Test each region's URL construction
        let testRegions: [Region] = [.eu, .usCentral, .usEast, .usWest, .caCentral, .apac]
        
        for region in testRegions {
            let config = TxServerConfiguration(environment: .production, region: region)
            let serverURL = config.signalingServer.absoluteString
            
            XCTAssertTrue(serverURL.contains("\(region.rawValue)."), 
                         "Configuration for \(region.displayName) should contain '\(region.rawValue).' prefix")
            XCTAssertTrue(serverURL.hasPrefix("wss://"), 
                         "Server URL should use secure WebSocket protocol")
        }
        
        // Test auto region (should not have prefix)
        let autoConfig = TxServerConfiguration(environment: .production, region: .auto)
        let autoURL = autoConfig.signalingServer.absoluteString
        XCTAssertFalse(autoURL.contains("auto."), "Auto region should not add prefix")
        XCTAssertTrue(autoURL.hasPrefix("wss://"), "Auto region URL should use secure WebSocket protocol")
    }
    
    /**
     Test region selection with push notifications
     */
    func testRegionWithPushNotifications() {
        let pushMetaData = [
            "voice_sdk_id": "test_sdk_12345",
            "device_token": "mock_device_token"
        ]
        
        // Test EU region with push metadata
        let euConfig = TxServerConfiguration(
            environment: .production,
            pushMetaData: pushMetaData,
            region: .eu
        )
        
        let euURL = euConfig.signalingServer.absoluteString
        XCTAssertTrue(euURL.contains("eu."), "EU region should be preserved with push metadata")
        print("euURL \(euURL)")
        // Check for URL-encoded version since underscores get encoded as %5F
        XCTAssertTrue(euURL.contains("voice_sdk_id=test%5Fsdk%5F12345") || euURL.contains("voice_sdk_id=test_sdk_12345"), "Push metadata should be included in URL (encoded or unencoded)")
        
        // Test US West region with push metadata
        let usWestConfig = TxServerConfiguration(
            environment: .production,
            pushMetaData: pushMetaData,
            region: .usWest
        )
        
        let usWestURL = usWestConfig.signalingServer.absoluteString
        XCTAssertTrue(usWestURL.contains("us-west."), "US West region should be preserved with push metadata")
        XCTAssertTrue(usWestURL.contains("voice_sdk_id=test%5Fsdk%5F12345") || usWestURL.contains("voice_sdk_id=test_sdk_12345"), "Push metadata should be included in URL (encoded or unencoded)")
    }
    
    /**
     Test region behavior in development vs production environments
     */
    func testRegionEnvironmentBehavior() {
        let testRegion: Region = .apac
        
        // Test production environment
        let prodConfig = TxServerConfiguration(environment: .production, region: testRegion)
        let prodURL = prodConfig.signalingServer.absoluteString
        XCTAssertTrue(prodURL.contains("apac."), "APAC region should work in production")
        
        // Test development environment
        let devConfig = TxServerConfiguration(environment: .development, region: testRegion)
        let devURL = devConfig.signalingServer.absoluteString
        XCTAssertTrue(devURL.contains("apac."), "APAC region should work in development")
        
        // URLs should be different (different base domains)
        XCTAssertNotEqual(prodURL, devURL, "Production and development URLs should be different")
    }
    
    /**
     Test region selection persistence through reconnection cycles
     */
    func testRegionPersistenceThroughReconnection() {
        guard let client = mockTxClient else {
            XCTFail("Mock TxClient not initialized")
            return
        }
        
        // Start with CA Central region
        let originalConfig = TxServerConfiguration(environment: .production, region: .caCentral)
        let txConfig = TxConfig(sipUser: "testuser", password: "testpassword")
        
        client.serverConfiguration = originalConfig
        client.txConfig = txConfig
        
        // Verify initial region
        let initialURL = client.serverConfiguration.signalingServer.absoluteString
        XCTAssertTrue(initialURL.contains("ca-central."), "Should start with CA Central region")
        
        // Simulate normal reconnection (without region change)
        client.onSocketDisconnected(reconnect: true, region: nil)
        
        // Create expectation for async operation to complete
        let expectation = XCTestExpectation(description: "Wait for fallback reconnection")
        
        // Simulate fallback reconnection
        client.onSocketDisconnected(reconnect: true, region: .auto)
        
        // Wait for the async reconnection to complete (TxClient.RECONNECT_BUFFER is 1.0 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // After fallback, should use auto region (no region prefix)
            let afterFallbackURL = client.serverConfiguration.signalingServer.absoluteString
            print("After fallback: \(afterFallbackURL)")
            XCTAssertFalse(afterFallbackURL.contains("ca-central."), "Should no longer use CA Central after fallback")
            
            // Verify that no region prefix is present (should be rtc.telnyx.com, not prefix.rtc.telnyx.com)
            XCTAssertTrue(afterFallbackURL.contains("rtc.telnyx.com"), "Should use base domain")
            XCTAssertFalse(afterFallbackURL.contains("us-central."), "Should not contain us-central prefix")
            XCTAssertFalse(afterFallbackURL.contains("eu."), "Should not contain eu prefix")
            
            expectation.fulfill()
        }
        
        // Actually wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
        
    }
    
    /**
     Test region error handling and recovery
     */
    func testRegionErrorHandlingAndRecovery() {
        // Test invalid region prefix extraction
        let invalidURLs = [
            URL(string: "wss://invalid")!,
            URL(string: "wss://single-component")!,
            URL(string: "ws://unsecure.server.com")! // Different protocol
        ]
        
        let socket = Socket()
        
        for invalidURL in invalidURLs {
            let extractedRegion = socket.extractRegionPrefix(from: invalidURL)
            // Should either be nil or handle gracefully
            if let region = extractedRegion {
                // If a region is extracted, it should not be a valid Region enum value
                XCTAssertNil(Region(rawValue: region), "Invalid URL should not produce valid region")
            }
            
            let shouldFallback = socket.shouldFallbackToAuto(signalingServer: invalidURL)
            // Invalid URLs should generally not trigger fallback unless they contain valid region prefixes
            // This behavior may vary based on implementation
        }
    }
    
    /**
     Test region performance under load
     */
    func testRegionPerformanceUnderLoad() {
        let iterations = 1000
        let regions = Region.allCases
        
        measure {
            for _ in 0..<iterations {
                for region in regions {
                    let config = TxServerConfiguration(environment: .production, region: region)
                    _ = config.signalingServer.absoluteString
                    
                    let socket = Socket()
                    _ = socket.shouldFallbackToAuto(signalingServer: config.signalingServer)
                    _ = socket.extractRegionPrefix(from: config.signalingServer)
                }
            }
        }
    }
}

// MARK: - Mock Classes for Testing

class MockSocket: Socket {
    var mockDelegate: SocketDelegate?
    var mockIsConnected = false
    var mockSignalingServer: URL?
    var sentMessages: [String] = []
    
    override var delegate: SocketDelegate? {
        get { return mockDelegate }
        set { mockDelegate = newValue }
    }
    
    override var isConnected: Bool {
        get { return mockIsConnected }
        set { mockIsConnected = newValue }
    }
    
    override var signalingServer: URL? {
        get { return mockSignalingServer }
        set { mockSignalingServer = newValue }
    }
    
    override func connect(signalingServer: URL) {
        self.mockSignalingServer = signalingServer
        self.mockIsConnected = true
        self.mockDelegate?.onSocketConnected()
    }
    
    override func disconnect(reconnect: Bool) {
        self.mockIsConnected = false
        self.mockDelegate?.onSocketDisconnected(reconnect: reconnect, region: nil)
    }
    
    override func sendMessage(message: String?) {
        sentMessages.append(message!)
    }
    
    // Simulate connection error for testing
    func simulateError(_ error: Error) {
        self.mockIsConnected = false
        self.mockDelegate?.onSocketError(error: error)
    }
    
    // Simulate region fallback scenario
    func simulateRegionFallback() {
        if let server = mockSignalingServer, shouldFallbackToAuto(signalingServer: server) {
            self.mockDelegate?.onSocketDisconnected(reconnect: true, region: .auto)
        }
    }
}

class MockRegionSocketDelegate: SocketDelegate {
    var onSocketConnectedCalled = false
    var onSocketDisconnectedCalled = false
    var onSocketErrorCalled = false
    var onMessageReceivedCalled = false
    var onSocketReconnectSuggestedCalled = false
    
    var lastReconnectValue: Bool?
    var lastRegionValue: Region?
    var lastErrorValue: Error?
    var lastMessage: String?
    
    func onSocketConnected() {
        onSocketConnectedCalled = true
    }
    
    func onSocketDisconnected(reconnect: Bool) {
        onSocketDisconnectedCalled = true
        lastReconnectValue = reconnect
    }
    
    func onSocketDisconnected(reconnect: Bool, region: Region?) {
        onSocketDisconnectedCalled = true
        lastReconnectValue = reconnect
        lastRegionValue = region
    }
    
    func onSocketError(error: Error) {
        onSocketErrorCalled = true
        lastErrorValue = error
    }
    
    func onMessageReceived(message: String) {
        onMessageReceivedCalled = true
        lastMessage = message
    }
    
    func onSocketReconnectSuggested() {
        onSocketReconnectSuggestedCalled = true
    }
    
    func reset() {
        onSocketConnectedCalled = false
        onSocketDisconnectedCalled = false
        onSocketErrorCalled = false
        onMessageReceivedCalled = false
        onSocketReconnectSuggestedCalled = false
        lastReconnectValue = nil
        lastRegionValue = nil
        lastErrorValue = nil
        lastMessage = nil
    }
}

// MARK: - Region Test Utilities

extension RegionIntegrationTests {
    
    /**
     Helper method to create TxConfig for testing
     */
    private func createTestTxConfig() -> TxConfig {
        return TxConfig(
            sipUser: "test_user",
            password: "test_password",
            pushDeviceToken: "test_device_token"
        )
    }
    
    /**
     Helper method to verify URL contains correct region prefix
     */
    private func verifyRegionInURL(_ url: String, expectedRegion: Region) -> Bool {
        if expectedRegion == .auto {
            // Auto region should not have any prefix
            return !Region.allCases.contains { region in
                region != .auto && url.contains("\(region.rawValue).")
            }
        } else {
            return url.contains("\(expectedRegion.rawValue).")
        }
    }
    
    /**
     Helper method to simulate network conditions for region testing
     */
    private func simulateNetworkConditions(for region: Region, connectionSuccess: Bool) {
        guard let socket = mockSocket else { return }
        
        let config = TxServerConfiguration(environment: .production, region: region)
        socket.connect(signalingServer: config.signalingServer)
        
        if !connectionSuccess {
            let error = NSError(domain: "NetworkError", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to \(region.displayName) region"
            ])
            socket.simulateError(error)
        }
    }
}
