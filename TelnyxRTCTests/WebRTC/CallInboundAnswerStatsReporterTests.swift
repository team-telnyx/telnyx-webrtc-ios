//
//  CallInboundAnswerStatsReporterTests.swift
//  TelnyxRTCTests
//
//  Created by [afk-bot] for VSUP-269 / GH #378.
//  Regression coverage for the inbound `Call.answer(debug:)` stats-reporter fix.
//

import XCTest
import WebRTC
@testable import TelnyxRTC

/// [VSUP-269] Regression tests for the bug where `Call.answer(debug: true)` on an
/// inbound call left `statsReporter` nil, so `onCallQualityChange` never fired.
///
/// **Bug.** Before the fix, `Call.answer(customHeaders:debug:completion:)` invoked
/// `configureStatsReporter()` *before* assigning `self.enableQualityMetrics = debug`
/// and `self.debug = debug`. Because `configureStatsReporter()` is gated on
/// `if (debug || enableQualityMetrics), let socket = self.socket`, the condition was
/// false at the moment of the call, so `statsReporter` stayed nil for inbound calls
/// answered with `debug: true`. The trailing `self.enableQualityMetrics = debug`
/// line ran too late to recover.
///
/// **Fix.** Reorder the assignments so `self.debug = debug` and
/// `self.enableQualityMetrics = debug` happen *before* `configureStatsReporter()`,
/// matching the working attach path (`Call.acceptReAttach`) and the outbound
/// `Call.newCall(...)` path. The `self.enableQualityMetrics = debug` line that ran
/// after the reporter was configured is now redundant and removed.
final class CallInboundAnswerStatsReporterTests: XCTestCase {

    private var socket: Socket?

    override func setUpWithError() throws {
        // Socket is constructed but does not need to be connected for these
        // assertions — `configureStatsReporter()` only checks that `self.socket`
        // is non-nil before creating the WebRTCStatsReporter.
        let s = Socket()
        self.socket = s
    }

    override func tearDownWithError() throws {
        self.socket = nil
    }

    /// [VSUP-269] `Call.answer(debug: true)` on an inbound call must create the stats
    /// reporter so `onCallQualityChange` can fire. This is the regression assertion:
    /// it fails on the unfixed code (statsReporter remains nil) and passes on the
    /// fixed code (statsReporter is set inside `configureStatsReporter()`).
    func testInboundAnswerWithDebugTrueCreatesStatsReporter() {
        guard let socket = self.socket else {
            XCTFail("Socket should be created")
            return
        }

        let call = Call(
            callId: UUID(),
            signalingCallId: UUID(),
            remoteSdp: "v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\n",
            sessionId: "<sessionId>",
            socket: socket,
            delegate: self,
            iceServers: InternalConfig.default.prodWebRTCIceServers,
            debug: false,
            enableQualityMetrics: false
        )

        // Inbound calls are constructed with debug=false / enableQualityMetrics=false
        // by default; the user enables metrics through the `answer(debug:)` parameter.
        XCTAssertFalse(call.debug)
        XCTAssertFalse(call.enableQualityMetrics)
        XCTAssertNil(call.statsReporter)

        call.answer(debug: true)

        // After the synchronous portion of `answer()` runs, `configureStatsReporter()`
        // must have created the reporter — it is gated on `enableQualityMetrics` or
        // `debug` being true. The asynchronous SDP handshake that follows does not
        // affect this assertion.
        XCTAssertTrue(call.enableQualityMetrics,
                      "answer(debug: true) must enable quality metrics")
        XCTAssertTrue(call.debug,
                      "answer(debug: true) must enable debug mode")
        XCTAssertNotNil(call.statsReporter,
                        "answer(debug: true) on an inbound call must create the stats reporter so onCallQualityChange can fire")
    }

    /// [VSUP-269] `Call.answer(debug: false)` on an inbound call must NOT create the
    /// stats reporter — the disabled path should remain a no-op for quality metrics.
    func testInboundAnswerWithDebugFalseDoesNotCreateStatsReporter() {
        guard let socket = self.socket else {
            XCTFail("Socket should be created")
            return
        }

        let call = Call(
            callId: UUID(),
            signalingCallId: UUID(),
            remoteSdp: "v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\n",
            sessionId: "<sessionId>",
            socket: socket,
            delegate: self,
            iceServers: InternalConfig.default.prodWebRTCIceServers,
            debug: false,
            enableQualityMetrics: false
        )

        XCTAssertFalse(call.debug)
        XCTAssertFalse(call.enableQualityMetrics)
        XCTAssertNil(call.statsReporter)

        call.answer(debug: false)

        XCTAssertFalse(call.enableQualityMetrics,
                       "answer(debug: false) must leave quality metrics disabled")
        XCTAssertFalse(call.debug,
                       "answer(debug: false) must leave debug mode disabled")
        XCTAssertNil(call.statsReporter,
                     "answer(debug: false) must not create the stats reporter")
    }
}

// MARK: - CallProtocol

extension CallInboundAnswerStatsReporterTests: CallProtocol {
    func callStateUpdated(call: Call) {
        // No-op for these assertions.
    }
}
