//
//  TxClientCodecTests.swift
//  TelnyxRTCTests
//
//  Created by AI SWE Agent on 08/10/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class TxClientCodecTests: XCTestCase {
    
    var txClient: TxClient!
    
    override func setUp() {
        super.setUp()
        // Initialize TxClient with test configuration
        let txConfig = TxConfig(sipUser: "testuser", 
                               sipPassword: "testpass", 
                               sipCallerIDName: "Test User", 
                               sipCallerIDNumber: "1234567890")
        txClient = TxClient(txConfig: txConfig)
    }
    
    override func tearDown() {
        txClient = nil
        super.tearDown()
    }
    
    func testGetSupportedAudioCodecs() {
        // Test that getSupportedAudioCodecs returns an array
        let supportedCodecs = txClient.getSupportedAudioCodecs()
        
        // Should return an array (may be empty in test environment)
        XCTAssertNotNil(supportedCodecs)
        XCTAssertTrue(supportedCodecs is [TxCodecCapability])
        
        // If codecs are available, verify they have valid properties
        for codec in supportedCodecs {
            XCTAssertFalse(codec.mimeType.isEmpty, "Codec mimeType should not be empty")
            XCTAssertGreaterThan(codec.clockRate, 0, "Codec clockRate should be greater than 0")
        }
    }
    
    func testNewCallWithPreferredCodecs() {
        // Test that newCall method accepts preferred codecs parameter
        let preferredCodecs = [
            TxCodecCapability(mimeType: "audio/opus", clockRate: 48000, channels: 2),
            TxCodecCapability(mimeType: "audio/PCMA", clockRate: 8000)
        ]
        
        // This test verifies the method signature accepts the parameter
        // In a real test environment, you would need to mock the socket connection
        do {
            let call = try txClient.newCall(
                callerName: "Test Caller",
                callerNumber: "1234567890",
                destinationNumber: "0987654321",
                callId: UUID(),
                preferredCodecs: preferredCodecs
            )
            
            // If we get here without throwing, the method signature is correct
            XCTAssertNotNil(call)
        } catch TxError.callFailed(let reason) {
            // Expected to fail due to missing session/socket in test environment
            XCTAssertEqual(reason, .sessionIdIsRequired)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testNewCallWithoutPreferredCodecs() {
        // Test that newCall method works without preferred codecs (backward compatibility)
        do {
            let call = try txClient.newCall(
                callerName: "Test Caller",
                callerNumber: "1234567890",
                destinationNumber: "0987654321",
                callId: UUID()
            )
            
            // If we get here without throwing, the method signature is correct
            XCTAssertNotNil(call)
        } catch TxError.callFailed(let reason) {
            // Expected to fail due to missing session/socket in test environment
            XCTAssertEqual(reason, .sessionIdIsRequired)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}