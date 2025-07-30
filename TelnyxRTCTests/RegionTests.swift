//
//  RegionTests.swift
//  TelnyxRTCTests
//
//  Created by GitHub Copilot on 14/07/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class RegionTests: XCTestCase {
    
    override func setUpWithError() throws {
        print("RegionTests:: setUpWithError")
    }

    override func tearDownWithError() throws {
        print("RegionTests:: tearDownWithError")
    }

    // MARK: - Basic Region Tests
    
    /**
     Test that all Region cases are available and have correct raw values
     */
    func testRegionCases() {
        XCTAssertEqual(Region.auto.rawValue, "auto")
        XCTAssertEqual(Region.eu.rawValue, "eu")
        XCTAssertEqual(Region.usCentral.rawValue, "us-central")
        XCTAssertEqual(Region.usEast.rawValue, "us-east")
        XCTAssertEqual(Region.usWest.rawValue, "us-west")
        XCTAssertEqual(Region.caCentral.rawValue, "ca-central")
        XCTAssertEqual(Region.apac.rawValue, "apac")
    }
    
    /**
     Test that Region is CaseIterable and contains all expected cases
     */
    func testRegionCaseIterable() {
        let allRegions = Region.allCases
        XCTAssertEqual(allRegions.count, 7)
        XCTAssertTrue(allRegions.contains(.auto))
        XCTAssertTrue(allRegions.contains(.eu))
        XCTAssertTrue(allRegions.contains(.usCentral))
        XCTAssertTrue(allRegions.contains(.usEast))
        XCTAssertTrue(allRegions.contains(.usWest))
        XCTAssertTrue(allRegions.contains(.caCentral))
        XCTAssertTrue(allRegions.contains(.apac))
    }
    
    /**
     Test Region display names
     */
    func testRegionDisplayNames() {
        XCTAssertEqual(Region.auto.displayName, "AUTO")
        XCTAssertEqual(Region.eu.displayName, "EU")
        XCTAssertEqual(Region.usCentral.displayName, "US-CENTRAL")
        XCTAssertEqual(Region.usEast.displayName, "US-EAST")
        XCTAssertEqual(Region.usWest.displayName, "US-WEST")
        XCTAssertEqual(Region.caCentral.displayName, "CA-CENTRAL")
        XCTAssertEqual(Region.apac.displayName, "APAC")
    }
    
    // MARK: - Region Factory Methods Tests
    
    /**
     Test creating Region from display name - valid cases
     */
    func testRegionFromDisplayNameValid() {
        XCTAssertEqual(Region.fromDisplayName("AUTO"), .auto)
        XCTAssertEqual(Region.fromDisplayName("EU"), .eu)
        XCTAssertEqual(Region.fromDisplayName("US-CENTRAL"), .usCentral)
        XCTAssertEqual(Region.fromDisplayName("US-EAST"), .usEast)
        XCTAssertEqual(Region.fromDisplayName("US-WEST"), .usWest)
        XCTAssertEqual(Region.fromDisplayName("CA-CENTRAL"), .caCentral)
        XCTAssertEqual(Region.fromDisplayName("APAC"), .apac)
    }
    
    /**
     Test creating Region from display name - case insensitive
     */
    func testRegionFromDisplayNameCaseInsensitive() {
        XCTAssertEqual(Region.fromDisplayName("auto"), .auto)
        XCTAssertEqual(Region.fromDisplayName("eu"), .eu)
        XCTAssertEqual(Region.fromDisplayName("us-central"), .usCentral)
        XCTAssertEqual(Region.fromDisplayName("us-east"), .usEast)
        XCTAssertEqual(Region.fromDisplayName("us-west"), .usWest)
        XCTAssertEqual(Region.fromDisplayName("ca-central"), .caCentral)
        XCTAssertEqual(Region.fromDisplayName("apac"), .apac)
        
        // Mixed case
        XCTAssertEqual(Region.fromDisplayName("Auto"), .auto)
        XCTAssertEqual(Region.fromDisplayName("Us-Central"), .usCentral)
        XCTAssertEqual(Region.fromDisplayName("Apac"), .apac)
    }
    
    /**
     Test creating Region from display name - invalid cases
     */
    func testRegionFromDisplayNameInvalid() {
        XCTAssertNil(Region.fromDisplayName("INVALID"))
        XCTAssertNil(Region.fromDisplayName(""))
        XCTAssertNil(Region.fromDisplayName("US-SOUTH"))
        XCTAssertNil(Region.fromDisplayName("EUROPE"))
        XCTAssertNil(Region.fromDisplayName("ASIA"))
    }
    
    /**
     Test creating Region from raw value - valid cases
     */
    func testRegionFromValueValid() {
        XCTAssertEqual(Region.fromValue("auto"), .auto)
        XCTAssertEqual(Region.fromValue("eu"), .eu)
        XCTAssertEqual(Region.fromValue("us-central"), .usCentral)
        XCTAssertEqual(Region.fromValue("us-east"), .usEast)
        XCTAssertEqual(Region.fromValue("us-west"), .usWest)
        XCTAssertEqual(Region.fromValue("ca-central"), .caCentral)
        XCTAssertEqual(Region.fromValue("apac"), .apac)
    }
    
    /**
     Test creating Region from raw value - invalid cases
     */
    func testRegionFromValueInvalid() {
        XCTAssertNil(Region.fromValue("invalid"))
        XCTAssertNil(Region.fromValue(""))
        XCTAssertNil(Region.fromValue("US-CENTRAL")) // Case sensitive
        XCTAssertNil(Region.fromValue("us-south"))
        XCTAssertNil(Region.fromValue("AUTO")) // Case sensitive
    }
    
    // MARK: - Region Codable Tests
    
    /**
     Test Region Codable encoding
     */
    func testRegionEncoding() throws {
        let regions: [Region] = [.auto, .eu, .usCentral, .usEast, .usWest, .caCentral, .apac]
        let encoder = JSONEncoder()
        
        for region in regions {
            let data = try encoder.encode(region)
            let jsonString = String(data: data, encoding: .utf8)
            XCTAssertEqual(jsonString, "\"\(region.rawValue)\"")
        }
    }
    
    /**
     Test Region Codable decoding
     */
    func testRegionDecoding() throws {
        let decoder = JSONDecoder()
        
        let autoData = "\"auto\"".data(using: .utf8)!
        let autoRegion = try decoder.decode(Region.self, from: autoData)
        XCTAssertEqual(autoRegion, .auto)
        
        let euData = "\"eu\"".data(using: .utf8)!
        let euRegion = try decoder.decode(Region.self, from: euData)
        XCTAssertEqual(euRegion, .eu)
        
        let usCentralData = "\"us-central\"".data(using: .utf8)!
        let usCentralRegion = try decoder.decode(Region.self, from: usCentralData)
        XCTAssertEqual(usCentralRegion, .usCentral)
    }
    
    /**
     Test Region Codable decoding with invalid data
     */
    func testRegionDecodingInvalid() {
        let decoder = JSONDecoder()
        
        let invalidData = "\"invalid\"".data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(Region.self, from: invalidData))
        
        let emptyData = "\"\"".data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(Region.self, from: emptyData))
    }
    
    // MARK: - Region Equality Tests
    
    /**
     Test Region equality
     */
    func testRegionEquality() {
        XCTAssertEqual(Region.auto, Region.auto)
        XCTAssertEqual(Region.eu, Region.eu)
        XCTAssertNotEqual(Region.auto, Region.eu)
        XCTAssertNotEqual(Region.usCentral, Region.usEast)
        XCTAssertNotEqual(Region.usWest, Region.caCentral)
    }
    
    // MARK: - Region Integration with TxServerConfiguration Tests
    
    /**
     Test TxServerConfiguration with different regions in production environment
     */
    func testTxServerConfigurationWithRegions() {
        // Test with auto region (default)
        let autoConfig = TxServerConfiguration(environment: .production, region: .auto)
        let autoURL = autoConfig.signalingServer.absoluteString
        XCTAssertFalse(autoURL.contains("auto."), "Auto region should not add prefix to URL")
        
        // Test with EU region
        let euConfig = TxServerConfiguration(environment: .production, region: .eu)
        let euURL = euConfig.signalingServer.absoluteString
        XCTAssertTrue(euURL.contains("eu."), "EU region should add 'eu.' prefix to URL")
        
        // Test with US Central region
        let usCentralConfig = TxServerConfiguration(environment: .production, region: .usCentral)
        let usCentralURL = usCentralConfig.signalingServer.absoluteString
        XCTAssertTrue(usCentralURL.contains("us-central."), "US Central region should add 'us-central.' prefix to URL")
        
        // Test with US East region
        let usEastConfig = TxServerConfiguration(environment: .production, region: .usEast)
        let usEastURL = usEastConfig.signalingServer.absoluteString
        XCTAssertTrue(usEastURL.contains("us-east."), "US East region should add 'us-east.' prefix to URL")
        
        // Test with US West region
        let usWestConfig = TxServerConfiguration(environment: .production, region: .usWest)
        let usWestURL = usWestConfig.signalingServer.absoluteString
        XCTAssertTrue(usWestURL.contains("us-west."), "US West region should add 'us-west.' prefix to URL")
        
        // Test with CA Central region
        let caCentralConfig = TxServerConfiguration(environment: .production, region: .caCentral)
        let caCentralURL = caCentralConfig.signalingServer.absoluteString
        XCTAssertTrue(caCentralURL.contains("ca-central."), "CA Central region should add 'ca-central.' prefix to URL")
        
        // Test with APAC region
        let apacConfig = TxServerConfiguration(environment: .production, region: .apac)
        let apacURL = apacConfig.signalingServer.absoluteString
        XCTAssertTrue(apacURL.contains("apac."), "APAC region should add 'apac.' prefix to URL")
    }
    
    /**
     Test TxServerConfiguration with regions in development environment
     */
    func testTxServerConfigurationWithRegionsInDevelopment() {
        // Test with auto region in development
        let autoConfig = TxServerConfiguration(environment: .development, region: .auto)
        let autoURL = autoConfig.signalingServer.absoluteString
        XCTAssertFalse(autoURL.contains("auto."), "Auto region should not add prefix to URL in development")
        
        // Test with EU region in development
        let euConfig = TxServerConfiguration(environment: .development, region: .eu)
        let euURL = euConfig.signalingServer.absoluteString
        XCTAssertTrue(euURL.contains("eu."), "EU region should add 'eu.' prefix to URL in development")
    }
    
    
    /**
     Test TxServerConfiguration with push metadata and regions
     */
    func testTxServerConfigurationWithPushMetaDataAndRegions() {
        let pushMetaData = ["voice_sdk_id": "test_sdk_id_123"]
        
        // Test with EU region and push metadata
        let euConfig = TxServerConfiguration(environment: .production, pushMetaData: pushMetaData, region: .eu)
        let euURL = euConfig.signalingServer.absoluteString
        XCTAssertTrue(euURL.contains("eu."), "EU region should add prefix even with push metadata")
        // Check for URL-encoded version of underscores (%5F)
        XCTAssertTrue(euURL.contains("voice_sdk_id=test%5Fsdk%5Fid%5F123"), "URL should contain URL-encoded SDK ID")
        
        // Test with US West region and push metadata
        let usWestConfig = TxServerConfiguration(environment: .production, pushMetaData: pushMetaData, region: .usWest)
        let usWestURL = usWestConfig.signalingServer.absoluteString
        XCTAssertTrue(usWestURL.contains("us-west."), "US West region should add prefix even with push metadata")
        // Check for URL-encoded version of underscores (%5F)
        XCTAssertTrue(usWestURL.contains("voice_sdk_id=test%5Fsdk%5Fid%5F123"), "URL should contain URL-encoded SDK ID")
    }
    
    // MARK: - Socket Region Extraction Tests
    
    /**
     Test Socket region extraction functionality
     */
    func testSocketRegionExtraction() {
        let socket = Socket()
        
        // Test extracting region from EU URL
        let euURL = URL(string: "wss://eu.rtc.telnyx.com")!
        let euRegion = socket.extractRegionPrefix(from: euURL)
        XCTAssertEqual(euRegion, "eu")
        
        // Test extracting region from US Central URL
        let usCentralURL = URL(string: "wss://us-central.rtc.telnyx.com")!
        let usCentralRegion = socket.extractRegionPrefix(from: usCentralURL)
        XCTAssertEqual(usCentralRegion, "us-central")
        
        // Test extracting region from US East URL
        let usEastURL = URL(string: "wss://us-east.rtc.telnyx.com")!
        let usEastRegion = socket.extractRegionPrefix(from: usEastURL)
        XCTAssertEqual(usEastRegion, "us-east")
        
        // Test extracting region from APAC URL
        let apacURL = URL(string: "wss://apac.rtc.telnyx.com")!
        let apacRegion = socket.extractRegionPrefix(from: apacURL)
        XCTAssertEqual(apacRegion, "apac")
        
        // Test with auto region (no prefix)
        let autoURL = URL(string: "wss://rtc.telnyx.com")!
        let autoRegion = socket.extractRegionPrefix(from: autoURL)
        XCTAssertEqual(autoRegion, "rtc") // Will extract "rtc" as the first component
        
        // Test with invalid URL format
        let invalidURL = URL(string: "wss://invalid")!
        let invalidRegion = socket.extractRegionPrefix(from: invalidURL)
        XCTAssertNil(invalidRegion)
    }
    
    /**
     Test Socket shouldFallbackToAuto functionality
     */
    func testSocketShouldFallbackToAuto() {
        let socket = Socket()
        
        // Test with EU region URL - should fallback to auto
        let euURL = URL(string: "wss://eu.rtc.telnyx.com")!
        XCTAssertTrue(socket.shouldFallbackToAuto(signalingServer: euURL))
        
        // Test with US Central region URL - should fallback to auto
        let usCentralURL = URL(string: "wss://us-central.rtc.telnyx.com")!
        XCTAssertTrue(socket.shouldFallbackToAuto(signalingServer: usCentralURL))
        
        // Test with auto region URL - should NOT fallback
        let autoURL = URL(string: "wss://rtc.telnyx.com")!
        XCTAssertFalse(socket.shouldFallbackToAuto(signalingServer: autoURL))
        
        // Test with nil URL
        XCTAssertFalse(socket.shouldFallbackToAuto(signalingServer: nil))
        
        // Test with invalid region URL
        let invalidURL = URL(string: "wss://invalid.domain.com")!
        XCTAssertFalse(socket.shouldFallbackToAuto(signalingServer: invalidURL))
    }
}

// MARK: - Mock Socket Delegate for Region Testing

class MockSocketDelegateForRegionTesting: SocketDelegate {
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

// MARK: - Region Integration Tests Extension

extension RegionTests {
    
    /**
     Test region fallback behavior with mock socket delegate
     */
    func testRegionFallbackBehavior() {
        let socket = Socket()
        let mockDelegate = MockSocketDelegateForRegionTesting()
        socket.delegate = mockDelegate
        
        // Test fallback scenario with EU region
        let euURL = URL(string: "wss://eu.rtc.telnyx.com")!
        socket.signalingServer = euURL
        
        // Simulate an error that should trigger fallback
        let error = NSError(domain: "TestError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
        
        // This would normally be called internally when WebSocket fails
        // We're testing the logic that determines if fallback should occur
        let shouldFallback = socket.shouldFallbackToAuto(signalingServer: euURL)
        XCTAssertTrue(shouldFallback, "EU region should trigger fallback to auto")
        
        // Reset mock
        mockDelegate.reset()
        
        // Test with auto region - should not fallback
        let autoURL = URL(string: "wss://rtc.telnyx.com")!
        let shouldNotFallback = socket.shouldFallbackToAuto(signalingServer: autoURL)
        XCTAssertFalse(shouldNotFallback, "Auto region should not trigger fallback")
    }
    
    /**
     Test region selection persistence
     */
    func testRegionSelectionPersistence() {
        // Test that region selection is properly maintained throughout configuration
        let selectedRegion: Region = .caCentral
        let config = TxServerConfiguration(environment: .production, region: selectedRegion)
        
        // Verify that the region choice affects the URL construction
        let url = config.signalingServer.absoluteString
        XCTAssertTrue(url.contains("ca-central."), "Selected region should be reflected in server URL")
        
        // Test with multiple different regions
        let allRegions = Region.allCases
        for region in allRegions {
            let regionConfig = TxServerConfiguration(environment: .production, region: region)
            let regionURL = regionConfig.signalingServer.absoluteString
            
            if region == .auto {
                XCTAssertFalse(regionURL.contains("auto."), "Auto region should not add prefix")
            } else {
                XCTAssertTrue(regionURL.contains("\(region.rawValue)."), "Region \(region.rawValue) should add appropriate prefix")
            }
        }
    }
}
