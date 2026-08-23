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

    func testClientSummaryEncodesSanitizedIceServerConfiguration() throws {
        let summary = CallReportSummary(
            callId: "call-id",
            clientSummary: CallReportClientSummary(
                connection: CallReportConnectionSummary(host: "wss://rtc.telnyx.com"),
                media: CallReportMediaSummary(
                    audio: true,
                    video: false,
                    forceRelayCandidate: false,
                    trickleIce: true,
                    iceServers: [
                        CallReportIceServerSummary(
                            urls: ["turns:turn.telnyx.com:443"],
                            hasUsername: true,
                            hasCredential: true
                        )
                    ]
                ),
                callReports: CallReportSettingsSummary(
                    enabled: true,
                    intervalMs: 5000,
                    debugLogLevel: "debug",
                    debugLogMaxEntries: 1000
                )
            )
        )

        let data = try JSONEncoder().encode(summary)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let clientSummary = try XCTUnwrap(json["clientSummary"] as? [String: Any])
        let media = try XCTUnwrap(clientSummary["media"] as? [String: Any])
        let iceServer = try XCTUnwrap((media["iceServers"] as? [[String: Any]])?.first)

        XCTAssertEqual(iceServer["urls"] as? [String], ["turns:turn.telnyx.com:443"])
        XCTAssertEqual(iceServer["hasUsername"] as? Bool, true)
        XCTAssertEqual(iceServer["hasCredential"] as? Bool, true)
        XCTAssertNil(iceServer["username"])
        XCTAssertNil(iceServer["credential"])
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

    func testLargePayloadSplitsStatsIntoSafeChunks() throws {
        let summary = CallReportSummary(callId: "call-id")
        let largeCandidateAddress = String(repeating: "a", count: 50_000)
        let localCandidate = ICECandidateStats(address: largeCandidateAddress)
        let stats = (0..<50).map { index in
            CallReportInterval(
                intervalStartUtc: "2026-08-23T10:00:\(index).000Z",
                intervalEndUtc: "2026-08-23T10:00:\(index + 1).000Z",
                ice: ICECandidatePairStats(local: localCandidate)
            )
        }
        let payload = CallReportPayload(summary: summary, stats: stats)

        let chunks = try TelnyxCallReportCollector.chunkedPayloadData(for: payload)

        XCTAssertGreaterThan(chunks.count, 1)
        XCTAssertTrue(chunks.allSatisfy {
            $0.count <= TelnyxCallReportCollector.safePayloadSizeBytes
        })

        let decodedStats = try chunks.flatMap {
            try JSONDecoder().decode(CallReportPayload.self, from: $0).stats
        }
        XCTAssertEqual(decodedStats.count, stats.count)
        XCTAssertEqual(decodedStats.map(\.intervalStartUtc), stats.map(\.intervalStartUtc))
    }

    func testIntervalEncodesJSCompatibleIceAndTransportStats() throws {
        let local = ICECandidateStats(
            id: "local-candidate",
            address: "10.0.0.2",
            port: 54543,
            candidateType: "relay",
            protocolType: "udp",
            networkType: "wifi",
            url: "turn:turn.telnyx.com:3478",
            relayProtocol: "udp"
        )
        let ice = ICECandidatePairStats(
            id: "candidate-pair",
            localCandidateId: "local-candidate",
            remoteCandidateId: "remote-candidate",
            state: "succeeded",
            nominated: true,
            writable: true,
            currentRoundTripTime: 0.125,
            requestsSent: 7,
            responsesReceived: 7,
            local: local
        )
        let transport = TransportStats(
            iceState: "connected",
            dtlsState: "connected",
            srtpCipher: "AES_CM_128_HMAC_SHA1_80",
            tlsVersion: "FEFD",
            selectedCandidatePairChanges: 1,
            selectedCandidatePairId: "candidate-pair"
        )
        let interval = CallReportInterval(
            intervalStartUtc: "2026-08-19T10:00:00.000Z",
            intervalEndUtc: "2026-08-19T10:00:05.000Z",
            ice: ice,
            transport: transport
        )

        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(interval)) as? [String: Any]
        let encodedIce = try XCTUnwrap(json?["ice"] as? [String: Any])
        let encodedLocal = try XCTUnwrap(encodedIce["local"] as? [String: Any])
        let encodedTransport = try XCTUnwrap(json?["transport"] as? [String: Any])

        XCTAssertEqual(encodedIce["localCandidateId"] as? String, "local-candidate")
        XCTAssertEqual(encodedLocal["protocol"] as? String, "udp")
        XCTAssertEqual(encodedTransport["selectedCandidatePairId"] as? String, "candidate-pair")
        XCTAssertEqual(encodedTransport["iceState"] as? String, "connected")
    }

    func testParserMapsRepresentativeRTCStatisticsFixture() {
        let snapshot = collector.parsedStatisticsSnapshot([
            CallReportStatisticsFixture(
                id: "inbound-audio",
                type: "inbound-rtp",
                timestampMs: 5_000,
                values: [
                    "kind": "audio",
                    "packetsReceived": 42,
                    "bytesReceived": 8_192,
                    "jitter": 0.012
                ]
            ),
            CallReportStatisticsFixture(
                id: "outbound-audio",
                type: "outbound-rtp",
                values: [
                    "kind": "audio",
                    "packetsSent": 24,
                    "bytesSent": 4_096,
                    "codecId": "opus-codec",
                    "mediaSourceId": "mic-source"
                ]
            ),
            CallReportStatisticsFixture(
                id: "opus-codec",
                type: "codec",
                values: [
                    "mimeType": "audio/opus",
                    "payloadType": 111,
                    "clockRate": 48_000,
                    "channels": 2
                ]
            ),
            CallReportStatisticsFixture(
                id: "mic-source",
                type: "media-source",
                values: [
                    "kind": "audio",
                    "audioLevel": 0.125,
                    "totalAudioEnergy": 42.5
                ]
            ),
            CallReportStatisticsFixture(
                id: "selected-pair",
                type: "candidate-pair",
                values: [
                    "state": "succeeded",
                    "nominated": true,
                    "localCandidateId": "local-relay",
                    "remoteCandidateId": "remote-host"
                ]
            ),
            CallReportStatisticsFixture(
                id: "local-relay",
                type: "local-candidate",
                values: ["candidateType": "relay", "protocol": "tcp"]
            ),
            CallReportStatisticsFixture(
                id: "remote-host",
                type: "remote-candidate",
                values: ["candidateType": "host"]
            ),
            CallReportStatisticsFixture(
                id: "transport",
                type: "transport",
                values: [
                    "selectedCandidatePairId": "selected-pair",
                    "iceState": "connected",
                    "dtlsState": "connected"
                ]
            )
        ])

        XCTAssertEqual(snapshot.inboundPacketsReceived, 42)
        XCTAssertEqual(snapshot.inboundBytesReceived, 8_192)
        XCTAssertEqual(snapshot.selectedCandidatePairId, "selected-pair")
        XCTAssertEqual(snapshot.localCandidateType, "relay")
        XCTAssertEqual(snapshot.localCandidateProtocol, "tcp")
        XCTAssertEqual(snapshot.remoteCandidateType, "host")
        XCTAssertEqual(snapshot.iceState, "connected")
        XCTAssertEqual(snapshot.dtlsState, "connected")
        XCTAssertEqual(snapshot.outboundCodecMimeType, "audio/opus")
        XCTAssertEqual(snapshot.outboundMediaSourceAudioLevel, 0.125)
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
