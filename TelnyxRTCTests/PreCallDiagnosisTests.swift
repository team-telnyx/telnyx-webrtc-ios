//
//  PreCallDiagnosisTests.swift
//  TelnyxRTCTests
//
//  Created by AI SWE Agent on 12/06/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class PreCallDiagnosisTests: XCTestCase {
    
    func testMetricSummaryCreation() {
        let summary = MetricSummary(min: 0.1, max: 0.5, avg: 0.3)
        
        XCTAssertEqual(summary.min, 0.1)
        XCTAssertEqual(summary.max, 0.5)
        XCTAssertEqual(summary.avg, 0.3)
    }
    
    func testMetricSummaryToDictionary() {
        let summary = MetricSummary(min: 0.1, max: 0.5, avg: 0.3)
        let dict = summary.toDictionary()
        
        XCTAssertEqual(dict["min"] as? Double, 0.1)
        XCTAssertEqual(dict["max"] as? Double, 0.5)
        XCTAssertEqual(dict["avg"] as? Double, 0.3)
    }
    
    func testICECandidateCreation() {
        let candidate = ICECandidate(
            id: "candidate-1",
            type: "host",
            protocol: "UDP",
            address: "192.168.1.100",
            port: 54400,
            priority: 2113667326
        )
        
        XCTAssertEqual(candidate.id, "candidate-1")
        XCTAssertEqual(candidate.type, "host")
        XCTAssertEqual(candidate.protocol, "UDP")
        XCTAssertEqual(candidate.address, "192.168.1.100")
        XCTAssertEqual(candidate.port, 54400)
        XCTAssertEqual(candidate.priority, 2113667326)
    }
    
    func testICECandidateToDictionary() {
        let candidate = ICECandidate(
            id: "candidate-1",
            type: "host",
            protocol: "UDP",
            address: "192.168.1.100",
            port: 54400,
            priority: 2113667326
        )
        let dict = candidate.toDictionary()
        
        XCTAssertEqual(dict["id"] as? String, "candidate-1")
        XCTAssertEqual(dict["type"] as? String, "host")
        XCTAssertEqual(dict["protocol"] as? String, "UDP")
        XCTAssertEqual(dict["address"] as? String, "192.168.1.100")
        XCTAssertEqual(dict["port"] as? Int, 54400)
        XCTAssertEqual(dict["priority"] as? Int, 2113667326)
    }
    
    func testPreCallDiagnosisCreation() {
        let jitterSummary = MetricSummary(min: 0.001, max: 0.010, avg: 0.005)
        let rttSummary = MetricSummary(min: 0.020, max: 0.100, avg: 0.060)
        let iceCandidates = [
            ICECandidate(id: "candidate-1", type: "host", protocol: "UDP", address: "192.168.1.100", port: 54400, priority: 2113667326)
        ]
        
        let diagnosis = PreCallDiagnosis(
            mos: 4.2,
            quality: .good,
            jitter: jitterSummary,
            rtt: rttSummary,
            bytesSent: 12345,
            bytesReceived: 54321,
            packetsSent: 123,
            packetsReceived: 120,
            iceCandidates: iceCandidates
        )
        
        XCTAssertEqual(diagnosis.mos, 4.2)
        XCTAssertEqual(diagnosis.quality, .good)
        XCTAssertEqual(diagnosis.jitter.avg, 0.005)
        XCTAssertEqual(diagnosis.rtt.avg, 0.060)
        XCTAssertEqual(diagnosis.bytesSent, 12345)
        XCTAssertEqual(diagnosis.bytesReceived, 54321)
        XCTAssertEqual(diagnosis.packetsSent, 123)
        XCTAssertEqual(diagnosis.packetsReceived, 120)
        XCTAssertEqual(diagnosis.iceCandidates.count, 1)
    }
    
    func testPreCallDiagnosisToDictionary() {
        let jitterSummary = MetricSummary(min: 0.001, max: 0.010, avg: 0.005)
        let rttSummary = MetricSummary(min: 0.020, max: 0.100, avg: 0.060)
        let iceCandidates = [
            ICECandidate(id: "candidate-1", type: "host", protocol: "UDP", address: "192.168.1.100", port: 54400, priority: 2113667326)
        ]
        
        let diagnosis = PreCallDiagnosis(
            mos: 4.2,
            quality: .good,
            jitter: jitterSummary,
            rtt: rttSummary,
            bytesSent: 12345,
            bytesReceived: 54321,
            packetsSent: 123,
            packetsReceived: 120,
            iceCandidates: iceCandidates
        )
        
        let dict = diagnosis.toDictionary()
        
        XCTAssertEqual(dict["mos"] as? Double, 4.2)
        XCTAssertEqual(dict["quality"] as? String, "good")
        XCTAssertEqual(dict["bytesSent"] as? Int64, 12345)
        XCTAssertEqual(dict["bytesReceived"] as? Int64, 54321)
        XCTAssertEqual(dict["packetsSent"] as? Int64, 123)
        XCTAssertEqual(dict["packetsReceived"] as? Int64, 120)
        
        let jitterDict = dict["jitter"] as? [String: Any]
        XCTAssertNotNil(jitterDict)
        XCTAssertEqual(jitterDict?["avg"] as? Double, 0.005)
        
        let rttDict = dict["rtt"] as? [String: Any]
        XCTAssertNotNil(rttDict)
        XCTAssertEqual(rttDict?["avg"] as? Double, 0.060)
        
        let candidatesArray = dict["iceCandidates"] as? [[String: Any]]
        XCTAssertNotNil(candidatesArray)
        XCTAssertEqual(candidatesArray?.count, 1)
    }
    
    func testPreCallDiagnosisStateEnum() {
        let startedState = PreCallDiagnosisState.started
        
        switch startedState {
        case .started:
            XCTAssertTrue(true, "Started state should match")
        default:
            XCTFail("Started state should match .started case")
        }
        
        let jitterSummary = MetricSummary(min: 0.001, max: 0.010, avg: 0.005)
        let rttSummary = MetricSummary(min: 0.020, max: 0.100, avg: 0.060)
        let diagnosis = PreCallDiagnosis(
            mos: 4.2,
            quality: .good,
            jitter: jitterSummary,
            rtt: rttSummary,
            bytesSent: 12345,
            bytesReceived: 54321,
            packetsSent: 123,
            packetsReceived: 120,
            iceCandidates: []
        )
        
        let completedState = PreCallDiagnosisState.completed(diagnosis)
        
        switch completedState {
        case .completed(let result):
            XCTAssertEqual(result.mos, 4.2)
        default:
            XCTFail("Completed state should match .completed case")
        }
        
        let error = TxError.callFailed(reason: .noMetricsCollected)
        let failedState = PreCallDiagnosisState.failed(error)
        
        switch failedState {
        case .failed(let err):
            XCTAssertNotNil(err)
        default:
            XCTFail("Failed state should match .failed case")
        }
    }
}