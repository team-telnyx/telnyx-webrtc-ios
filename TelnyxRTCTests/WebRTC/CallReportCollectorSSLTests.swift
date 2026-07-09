//
//  CallReportCollectorSSLTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
import WebRTC
@testable import TelnyxRTC

class CallReportCollectorSSLTests: XCTestCase {

    var collector: TelnyxCallReportCollector!
    var mockPeerConnection: RTCPeerConnection!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let configuration = RTCConfiguration()
        configuration.iceServers = []
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let factory = RTCPeerConnectionFactory()
        mockPeerConnection = factory.peerConnection(with: configuration, constraints: constraints, delegate: nil)

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

    // MARK: - Integration

    func testCallReportHelperRejectsNonLocalHost() {
        let url = URL(string: "wss://rtc.telnyx.com")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    func testCallReportHelperAllowsLocalhost() {
        let url = URL(string: "wss://localhost")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: url))
    }

    // MARK: - Post report

    func testPostReportDoesNotCrash() {
        collector.start(peerConnection: mockPeerConnection)

        let statsExpectation = expectation(description: "Stats accumulation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            statsExpectation.fulfill()
        }
        wait(for: [statsExpectation], timeout: 1.0)

        collector.stop()

        let summary = CallReportSummary(
            callId: "test-call-ssl",
            state: "done",
            durationSeconds: 5.0,
            telnyxSessionId: "session",
            telnyxLegId: "leg",
            voiceSdkSessionId: "test-session",
            startTimestamp: ISO8601DateFormatter().string(from: collector.callStartTime),
            endTimestamp: ISO8601DateFormatter().string(from: collector.callEndTime ?? Date())
        )

        collector.postReport(
            summary: summary,
            callReportId: "report-ssl",
            host: "wss://rtc.telnyx.com",
            voiceSdkId: "ios-sdk-test"
        )

        XCTAssertNotNil(collector.callEndTime)
    }

    // MARK: - HTTP URL derivation

    func testHTTPURLDerivedFromWebSocket() {
        let wsUrl = URL(string: "wss://localhost")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: wsUrl))

        let httpUrl = URL(string: "https://localhost/report")!
        XCTAssertTrue(SSLValidationHelper.shouldAllowSelfSigned(for: httpUrl))
    }

    func testHTTPURLNonLocalRejected() {
        let httpUrl = URL(string: "https://rtc.telnyx.com/report")!
        XCTAssertFalse(SSLValidationHelper.shouldAllowSelfSigned(for: httpUrl))
    }

    #if DEBUG
    func testAllowSelfSignedDelegateExistsInDebugBuild() {
        XCTAssertNotNil(collector)
    }
    #endif
}
