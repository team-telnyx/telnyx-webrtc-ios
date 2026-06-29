//
//  CallReportCollectorTests.swift
//  TelnyxRTCTests
//
//  Created by Atlas on 2026-03-04.
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
import WebRTC
@testable import TelnyxRTC

class CallReportCollectorTests: XCTestCase {
    
    var collector: TelnyxCallReportCollector!
    var mockPeerConnection: RTCPeerConnection!
    private let statsWaitPollInterval: TimeInterval = 0.05
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create mock peer connection
        let configuration = RTCConfiguration()
        configuration.iceServers = []
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let factory = RTCPeerConnectionFactory()
        mockPeerConnection = factory.peerConnection(with: configuration, constraints: constraints, delegate: nil)
        
        // Create collector with short interval for faster tests
        let config = CallReportConfig(enabled: true, interval: 0.1)
        let logConfig = LogCollectorConfig(enabled: true, level: "debug", maxEntries: 100)
        collector = TelnyxCallReportCollector(config: config, logCollectorConfig: logConfig)
    }
    
    override func tearDownWithError() throws {
        collector?.stop()
        collector = nil
        mockPeerConnection?.close()
        mockPeerConnection = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testCollectorInitialization() {
        XCTAssertNotNil(collector, "Collector should initialize successfully")
        XCTAssertNotNil(collector.callStartTime, "Call start time should be set on init")
        XCTAssertNil(collector.callEndTime, "Call end time should be nil before stop")
    }
    
    func testCollectorWithDisabledConfig() {
        let disabledConfig = CallReportConfig(enabled: false, interval: 5.0)
        let disabledCollector = TelnyxCallReportCollector(config: disabledConfig)
        
        XCTAssertNotNil(disabledCollector, "Disabled collector should still initialize")
        
        // Start should not crash even when disabled
        disabledCollector.start(peerConnection: mockPeerConnection)
        disabledCollector.stop()
    }
    
    // MARK: - Start/Stop Tests
    
    func testStartStopCycle() {
        let startExpectation = expectation(description: "Collector starts")
        
        collector.start(peerConnection: mockPeerConnection)
        
        // Wait a bit to allow timer to fire at least once
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startExpectation.fulfill()
        }
        
        wait(for: [startExpectation], timeout: 1.0)
        
        collector.stop()
        
        XCTAssertNotNil(collector.callEndTime, "Call end time should be set after stop")
        XCTAssertGreaterThan(collector.callEndTime ?? Date.distantPast,
                            collector.callStartTime,
                            "End time should be after start time")
    }
    
    func testMultipleStartCallsAreSafe() {
        // Starting multiple times should not crash
        collector.start(peerConnection: mockPeerConnection)
        collector.start(peerConnection: mockPeerConnection)
        collector.stop()
        
        // No assertion needed - just ensuring no crash
    }
    
    // MARK: - Log Collection Tests
    
    func testLogEntryCollection() {
        collector.start(peerConnection: mockPeerConnection)
        
        // Add some log entries
        collector.addLogEntry(level: "info", message: "Test log 1", context: nil)
        collector.addLogEntry(level: "debug", message: "Test log 2", context: ["key": "value"])
        collector.addLogEntry(level: "error", message: "Test error", context: ["error_code": 500])
        
        collector.stop()
        
        // Logs should be collected (we can't directly access them but can verify no crash)
        XCTAssertNotNil(collector.callEndTime, "Collector should stop successfully with logs")
    }
    
    func testLogEntryWithContext() {
        collector.start(peerConnection: mockPeerConnection)
        
        let context: [String: AnyCodable] = [
            "state": AnyCodable("active"),
            "callId": AnyCodable("test-call-123"),
            "duration": AnyCodable(42.5)
        ]
        
        collector.addLogEntry(level: "info", message: "Call state changed", context: context)
        collector.stop()
        
        // Verify no crash with complex context
        XCTAssertNotNil(collector.callEndTime)
    }
    
    // MARK: - Flush Tests
    
    func testFlushCreatesSegment() {
        collector.start(peerConnection: mockPeerConnection)
        
        // Wait for some stats to accumulate
        let statsExpectation = expectation(description: "Stats accumulation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            statsExpectation.fulfill()
        }
        wait(for: [statsExpectation], timeout: 1.0)
        
        // Create a test summary
        let summary = CallReportSummary(
            callId: "test-call-123",
            state: "active",
            durationSeconds: nil,
            telnyxSessionId: "session-456",
            telnyxLegId: "leg-789",
            voiceSdkSessionId: "test-session",
            startTimestamp: ISO8601DateFormatter().string(from: collector.callStartTime),
            endTimestamp: nil
        )

        // Flush should create a payload
        let payload = collector.flush(summary: summary)
        
        XCTAssertNotNil(payload, "Flush should create a payload")
        XCTAssertEqual(payload?.segment, 0, "First segment should be 0")
        XCTAssertGreaterThan(payload?.stats.count ?? 0, 0, "Flushed payload should contain stats")
        
        collector.stop()
    }
    
    func testMultipleFlushesIncrementSegmentIndex() {
        collector.start(peerConnection: mockPeerConnection)

        let summary = CallReportSummary(
            callId: "test-call-123",
            state: "active",
            durationSeconds: nil,
            telnyxSessionId: "session-456",
            telnyxLegId: "leg-789",
            voiceSdkSessionId: "test-session",
            startTimestamp: ISO8601DateFormatter().string(from: collector.callStartTime),
            endTimestamp: nil
        )

        waitForCollectedStats(in: collector)

        // First flush
        let firstPayload = collector.flush(summary: summary)
        XCTAssertNotNil(firstPayload, "First flush should produce a payload")
        XCTAssertEqual(firstPayload?.segment, 0, "First segment should be 0")

        waitForCollectedStats(in: collector)

        // Second flush
        let secondPayload = collector.flush(summary: summary)
        XCTAssertNotNil(secondPayload, "Second flush should produce a payload")
        XCTAssertEqual(secondPayload?.segment, 1, "Second segment should be 1")

        collector.stop()
    }
    
    func testFlushWithEmptyBufferReturnsNil() {
        // Don't start the collector, so buffer remains empty
        
        let summary = CallReportSummary(
            callId: "test-call-123",
            state: "active",
            durationSeconds: nil,
            telnyxSessionId: "session-456",
            telnyxLegId: "leg-789",
            voiceSdkSessionId: "test-session",
            startTimestamp: ISO8601DateFormatter().string(from: Date()),
            endTimestamp: nil
        )
        
        let payload = collector.flush(summary: summary)
        
        XCTAssertNil(payload, "Flush with empty buffer should return nil")
    }
    
    // MARK: - Post Report Tests
    
    func testPostReportWithValidData() {
        collector.start(peerConnection: mockPeerConnection)
        
        // Wait for stats to accumulate
        let statsExpectation = expectation(description: "Stats accumulation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            statsExpectation.fulfill()
        }
        wait(for: [statsExpectation], timeout: 1.0)
        
        collector.stop()
        
        let summary = CallReportSummary(
            callId: "test-call-123",
            state: "done",
            durationSeconds: (collector.callEndTime ?? Date()).timeIntervalSince(collector.callStartTime),
            telnyxSessionId: "session-456",
            telnyxLegId: "leg-789",
            voiceSdkSessionId: "test-session",
            startTimestamp: ISO8601DateFormatter().string(from: collector.callStartTime),
            endTimestamp: ISO8601DateFormatter().string(from: collector.callEndTime ?? Date())
        )
        
        // This will attempt to post - we can't easily mock URLSession in this context
        // but we can verify it doesn't crash
        collector.postReport(
            summary: summary,
            callReportId: "report-123",
            host: "wss://rtc.telnyx.com",
            voiceSdkId: "ios-sdk-v3.0.0"
        )
        
        // Verify no crash
        XCTAssertNotNil(collector.callEndTime)
    }
    
    func testPostReportWithInvalidHostDoesNotCrash() {
        collector.start(peerConnection: mockPeerConnection)
        collector.stop()
        
        let summary = CallReportSummary(
            callId: "test-call-123",
            state: "done",
            durationSeconds: 10.0,
            telnyxSessionId: "session-456",
            telnyxLegId: "leg-789",
            voiceSdkSessionId: "test-session",
            startTimestamp: ISO8601DateFormatter().string(from: collector.callStartTime),
            endTimestamp: ISO8601DateFormatter().string(from: collector.callEndTime ?? Date())
        )
        
        // Invalid host should log error but not crash
        collector.postReport(
            summary: summary,
            callReportId: "report-123",
            host: "invalid://host",
            voiceSdkId: nil
        )
        
        // No assertion needed - just ensuring no crash
    }
    
    // MARK: - Integration Tests
    
    func testCallStateTransitionTriggersReport() {
        // This test verifies that the Call class properly triggers reports on state changes
        // We test this indirectly by ensuring the collector can handle rapid start/stop
        
        collector.start(peerConnection: mockPeerConnection)
        
        let rapidExpectation = expectation(description: "Rapid stop")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.collector.stop()
            rapidExpectation.fulfill()
        }
        
        wait(for: [rapidExpectation], timeout: 1.0)
        
        XCTAssertNotNil(collector.callEndTime, "Collector should handle rapid start/stop")
    }
    
    func testCallReportPayloadStructure() {
        collector.start(peerConnection: mockPeerConnection)
        
        // Wait for stats
        let statsExpectation = expectation(description: "Stats")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            statsExpectation.fulfill()
        }
        wait(for: [statsExpectation], timeout: 1.0)
        
        collector.stop()
        
        let summary = CallReportSummary(
            callId: "test-call-123",
            state: "done",
            durationSeconds: 5.0,
            telnyxSessionId: "session-456",
            telnyxLegId: "leg-789",
            voiceSdkSessionId: "test-session",
            startTimestamp: ISO8601DateFormatter().string(from: collector.callStartTime),
            endTimestamp: ISO8601DateFormatter().string(from: collector.callEndTime ?? Date())
        )
        
        let payload = CallReportPayload(
            summary: summary,
            stats: [],
            logs: nil,
            segment: nil
        )
        
        // Verify payload can be encoded to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(payload)
            XCTAssertNotNil(jsonData, "Payload should encode to JSON")
            
            // Verify it's valid JSON
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            XCTAssertNotNil(jsonObject, "Encoded payload should be valid JSON")
        } catch {
            XCTFail("Failed to encode payload: \(error)")
        }
    }
    
    func testCollectorHandlesLongCalls() {
        // Simulate a scenario where stats buffer could grow large
        let longCallConfig = CallReportConfig(enabled: true, interval: 0.05) // Very fast for testing
        let longCallCollector = TelnyxCallReportCollector(config: longCallConfig)
        
        longCallCollector.start(peerConnection: mockPeerConnection)
        
        waitForCollectedStats(in: longCallCollector, minimumCount: 2)
        
        longCallCollector.stop()
        
        XCTAssertNotNil(longCallCollector.callEndTime, "Collector should handle long duration calls")
    }

    private func waitForCollectedStats(
        in collector: TelnyxCallReportCollector,
        minimumCount: Int = 1,
        timeout: TimeInterval = 3.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date().addingTimeInterval(timeout)

        while collector.getStatsBuffer().count < minimumCount && Date() < deadline {
            RunLoop.current.run(
                mode: .default,
                before: Date().addingTimeInterval(statsWaitPollInterval)
            )
        }

        XCTAssertGreaterThanOrEqual(
            collector.getStatsBuffer().count,
            minimumCount,
            "Timed out waiting for collected stats",
            file: file,
            line: line
        )
    }
}
