//
//  TxCodecCapabilityTests.swift
//  TelnyxRTCTests
//
//  Created by AI SWE Agent on 08/10/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class TxCodecCapabilityTests: XCTestCase {
    
    func testTxCodecCapabilityInitialization() {
        // Test basic initialization
        let codec = TxCodecCapability(
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            sdpFmtpLine: "minptime=10;useinbandfec=1"
        )
        
        XCTAssertEqual(codec.mimeType, "audio/opus")
        XCTAssertEqual(codec.clockRate, 48000)
        XCTAssertEqual(codec.channels, 2)
        XCTAssertEqual(codec.sdpFmtpLine, "minptime=10;useinbandfec=1")
    }
    
    func testTxCodecCapabilityWithoutOptionalFields() {
        // Test initialization without optional fields
        let codec = TxCodecCapability(
            mimeType: "audio/PCMA",
            clockRate: 8000
        )
        
        XCTAssertEqual(codec.mimeType, "audio/PCMA")
        XCTAssertEqual(codec.clockRate, 8000)
        XCTAssertNil(codec.channels)
        XCTAssertNil(codec.sdpFmtpLine)
    }
    
    func testTxCodecCapabilityToDictionary() {
        // Test conversion to dictionary
        let codec = TxCodecCapability(
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            sdpFmtpLine: "minptime=10;useinbandfec=1"
        )
        
        let dictionary = codec.toDictionary()
        
        XCTAssertEqual(dictionary["mimeType"] as? String, "audio/opus")
        XCTAssertEqual(dictionary["clockRate"] as? Int, 48000)
        XCTAssertEqual(dictionary["channels"] as? Int, 2)
        XCTAssertEqual(dictionary["sdpFmtpLine"] as? String, "minptime=10;useinbandfec=1")
    }
    
    func testTxCodecCapabilityToDictionaryWithoutOptionalFields() {
        // Test conversion to dictionary without optional fields
        let codec = TxCodecCapability(
            mimeType: "audio/PCMA",
            clockRate: 8000
        )
        
        let dictionary = codec.toDictionary()
        
        XCTAssertEqual(dictionary["mimeType"] as? String, "audio/PCMA")
        XCTAssertEqual(dictionary["clockRate"] as? Int, 8000)
        XCTAssertNil(dictionary["channels"])
        XCTAssertNil(dictionary["sdpFmtpLine"])
    }
    
    func testTxCodecCapabilityEquality() {
        // Test equality
        let codec1 = TxCodecCapability(
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            sdpFmtpLine: "minptime=10;useinbandfec=1"
        )
        
        let codec2 = TxCodecCapability(
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            sdpFmtpLine: "minptime=10;useinbandfec=1"
        )
        
        let codec3 = TxCodecCapability(
            mimeType: "audio/PCMA",
            clockRate: 8000
        )
        
        XCTAssertEqual(codec1, codec2)
        XCTAssertNotEqual(codec1, codec3)
    }
    
    func testTxCodecCapabilityCodable() {
        // Test Codable conformance
        let codec = TxCodecCapability(
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            sdpFmtpLine: "minptime=10;useinbandfec=1"
        )
        
        do {
            let data = try JSONEncoder().encode(codec)
            let decodedCodec = try JSONDecoder().decode(TxCodecCapability.self, from: data)
            
            XCTAssertEqual(codec, decodedCodec)
        } catch {
            XCTFail("Failed to encode/decode TxCodecCapability: \(error)")
        }
    }
}