import XCTest
@testable import TelnyxRTC

final class SignalingHealthMonitorTests: XCTestCase {
    func testPeerAndIceFailuresStartOnlyOneIceRestart() {
        let call = makeActiveCall()
        var restartCount = 0
        var reattachCount = 0
        let restartExpectation = expectation(description: "starts one ICE restart")
        let monitor = SignalingHealthMonitor(
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in
                restartCount += 1
                restartExpectation.fulfill()
            },
            requestReattach: { _ in reattachCount += 1 }
        )

        monitor.iceConnectionStateDidChange(call, state: .failed)
        monitor.peerConnectionStateDidChange(call, state: .failed)

        wait(for: [restartExpectation], timeout: 1)
        XCTAssertEqual(restartCount, 1)
        XCTAssertEqual(reattachCount, 0)
    }

    func testSustainedPeerDisconnectionStartsIceRestartWhenSignalingIsHealthy() {
        let call = makeActiveCall()
        let restartExpectation = expectation(description: "starts ICE restart after sustained peer disconnection")
        let monitor = SignalingHealthMonitor(
            peerDisconnectedRecoveryDelay: 0.01,
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in restartExpectation.fulfill() },
            requestReattach: { _ in XCTFail("Should not reattach while signaling is healthy") }
        )

        monitor.peerConnectionStateDidChange(call, state: .disconnected)

        wait(for: [restartExpectation], timeout: 1)
    }

    func testPeerReconnectCancelsDisconnectedRecoveryDelay() {
        let call = makeActiveCall()
        let noRestartExpectation = expectation(description: "does not restart after transient peer disconnection")
        noRestartExpectation.isInverted = true
        let monitor = SignalingHealthMonitor(
            peerDisconnectedRecoveryDelay: 0.02,
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in noRestartExpectation.fulfill() },
            requestReattach: { XCTFail("Should not reattach after peer reconnects") }
        )

        monitor.peerConnectionStateDidChange(call, state: .disconnected)
        monitor.peerConnectionStateDidChange(call, state: .connected)

        wait(for: [noRestartExpectation], timeout: 0.1)
    }

    func testPeerFailureWithUnavailableSignalingUsesReattach() {
        let call = makeActiveCall()
        var restartCount = 0
        var reattachCount = 0
        let reattachExpectation = expectation(description: "requests reattach")
        let monitor = SignalingHealthMonitor(
            isSignalingAvailable: { false },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in restartCount += 1 },
            requestReattach: { _ in
                reattachCount += 1
                reattachExpectation.fulfill()
            }
        )

        monitor.peerConnectionStateDidChange(call, state: .failed)

        wait(for: [reattachExpectation], timeout: 1)
        XCTAssertEqual(restartCount, 0)
        XCTAssertEqual(reattachCount, 1)
    }

    func testPeerFailureForProvenVPNDirectPathForcesRelayOnReattach() {
        let call = makeActiveCall()
        var reattachForceRelay: Bool?
        let reattachExpectation = expectation(description: "reattaches with forced relay")
        let monitor = SignalingHealthMonitor(
            isSignalingAvailable: { false },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in XCTFail("Should not restart ICE") },
            shouldForceRelayForRecovery: { _, completion in completion(true) },
            requestReattach: { forceRelay in
                reattachForceRelay = forceRelay
                reattachExpectation.fulfill()
            }
        )

        monitor.peerConnectionStateDidChange(call, state: .failed)

        wait(for: [reattachExpectation], timeout: 1)
        XCTAssertEqual(reattachForceRelay, true)
    }

    func testIceRestartTimeoutFallsBackToReattach() {
        let call = makeActiveCall()
        let reattachExpectation = expectation(description: "ICE restart timeout requests reattach")
        let monitor = SignalingHealthMonitor(
            iceRestartTimeout: 0.01,
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in },
            requestReattach: { _ in reattachExpectation.fulfill() }
        )

        monitor.peerConnectionStateDidChange(call, state: .failed)

        wait(for: [reattachExpectation], timeout: 1)
    }

    func testStaleSignalingDefersIceRestartUntilMatchingProbeResponse() {
        let call = makeActiveCall()
        var restartCount = 0
        var probeCount = 0
        let probeExpectation = expectation(description: "sends a recovery probe")
        let restartExpectation = expectation(description: "starts ICE restart after matching response")
        let monitor = SignalingHealthMonitor(
            signalingProbeTimeout: 1,
            recentInboundActivityThreshold: 0.01,
            isSignalingAvailable: { true },
            sendSignalingProbe: {
                probeCount += 1
                probeExpectation.fulfill()
                return "expected-probe-id"
            },
            startIceRestart: { _ in
                restartCount += 1
                restartExpectation.fulfill()
            },
            requestReattach: { _ in XCTFail("Should not reattach") }
        )

        // Let the initial freshness window expire before the failure.
        let staleExpectation = expectation(description: "signaling becomes stale")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { staleExpectation.fulfill() }
        wait(for: [staleExpectation], timeout: 1)
        monitor.peerConnectionStateDidChange(call, state: .failed)

        wait(for: [probeExpectation], timeout: 1)
        XCTAssertEqual(probeCount, 1)

        monitor.signalingMessageReceived(makeResponse(id: "unrelated-id"))
        monitor.signalingMessageReceived(makeResponse(id: "expected-probe-id"))

        wait(for: [restartExpectation], timeout: 1)
        XCTAssertEqual(restartCount, 1)
    }

    func testSignalingProbeTimeoutFallsBackToReattach() {
        let call = makeActiveCall()
        let reattachExpectation = expectation(description: "probe timeout requests reattach")
        let monitor = SignalingHealthMonitor(
            signalingProbeTimeout: 0.01,
            recentInboundActivityThreshold: 0.01,
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in XCTFail("Should not restart ICE") },
            requestReattach: { _ in reattachExpectation.fulfill() }
        )

        let staleExpectation = expectation(description: "signaling becomes stale")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { staleExpectation.fulfill() }
        wait(for: [staleExpectation], timeout: 1)
        monitor.iceConnectionStateDidChange(call, state: .failed)

        wait(for: [reattachExpectation], timeout: 1)
    }

    func testActiveCallProbesAfterSustainedSignalingSilence() {
        let call = makeActiveCall()
        let probeExpectation = expectation(description: "active call sends signaling probe")
        probeExpectation.assertForOverFulfill = false
        let monitor = SignalingHealthMonitor(
            signalingProbeTimeout: 1,
            staleInboundActivityThreshold: 0.01,
            signalingHealthCheckInterval: 0.01,
            isSignalingAvailable: { true },
            sendSignalingProbe: {
                probeExpectation.fulfill()
                return "probe-id"
            },
            startIceRestart: { _ in XCTFail("Should not restart ICE") },
            requestReattach: { _ in XCTFail("Should not reattach before probe timeout") }
        )

        monitor.callStateDidChange(call)

        wait(for: [probeExpectation], timeout: 1)
    }

    func testSuccessfulActiveCallHealthProbeDoesNotRestartICE() {
        let call = makeActiveCall()
        let probeExpectation = expectation(description: "active call sends signaling probe")
        probeExpectation.assertForOverFulfill = false
        var restartCount = 0
        var reattachCount = 0
        let monitor = SignalingHealthMonitor(
            signalingProbeTimeout: 1,
            staleInboundActivityThreshold: 0.01,
            signalingHealthCheckInterval: 0.01,
            isSignalingAvailable: { true },
            sendSignalingProbe: {
                probeExpectation.fulfill()
                return "health-probe-id"
            },
            startIceRestart: { _ in restartCount += 1 },
            requestReattach: { _ in reattachCount += 1 }
        )

        monitor.callStateDidChange(call)
        wait(for: [probeExpectation], timeout: 1)
        monitor.signalingMessageReceived(makeResponse(id: "health-probe-id"))

        let settledExpectation = expectation(description: "processes matching health probe response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { settledExpectation.fulfill() }
        wait(for: [settledExpectation], timeout: 1)
        XCTAssertEqual(restartCount, 0)
        XCTAssertEqual(reattachCount, 0)
    }

    func testActiveCallReattachesWhenSignalingProbeTimesOut() {
        let call = makeActiveCall()
        let reattachExpectation = expectation(description: "active call reattaches after probe timeout")
        let monitor = SignalingHealthMonitor(
            signalingProbeTimeout: 0.01,
            staleInboundActivityThreshold: 0.01,
            signalingHealthCheckInterval: 0.01,
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in XCTFail("Should not restart ICE") },
            requestReattach: { _ in reattachExpectation.fulfill() }
        )

        monitor.callStateDidChange(call)

        wait(for: [reattachExpectation], timeout: 1)
    }

    func testInboundRtpStallStartsIceRestartAfterThreeSecondThreshold() {
        let call = makeActiveCall()
        let restartExpectation = expectation(description: "inbound RTP stall starts ICE restart")
        let monitor = SignalingHealthMonitor(
            inboundRtpStallTimeout: 0.02,
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in restartExpectation.fulfill() },
            requestReattach: { _ in XCTFail("Should restart ICE before reattaching") }
        )

        monitor.callStateDidChange(call)
        monitor.inboundRtpSampleReceived(100, for: call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            monitor.inboundRtpSampleReceived(100, for: call)
        }

        wait(for: [restartExpectation], timeout: 1)
    }

    func testRestartAnswerWithoutInboundRtpFallsBackToReattach() {
        let call = makeActiveCall()
        let restartExpectation = expectation(description: "starts ICE restart")
        let reattachExpectation = expectation(description: "reattaches after media verification timeout")
        let monitor = SignalingHealthMonitor(
            postIceRestartMediaTimeout: 0.02,
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in restartExpectation.fulfill() },
            requestReattach: { _ in reattachExpectation.fulfill() }
        )

        monitor.callStateDidChange(call)
        monitor.peerConnectionStateDidChange(call, state: .failed)
        wait(for: [restartExpectation], timeout: 1)
        monitor.iceRestartDidComplete(for: call)

        wait(for: [reattachExpectation], timeout: 1)
    }

    func testInboundRtpGrowthAfterRestartAnswerCompletesRecovery() {
        let call = makeActiveCall()
        let restartExpectation = expectation(description: "starts ICE restart")
        var reattachCount = 0
        let monitor = SignalingHealthMonitor(
            postIceRestartMediaTimeout: 0.1,
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in restartExpectation.fulfill() },
            requestReattach: { _ in reattachCount += 1 }
        )

        monitor.callStateDidChange(call)
        monitor.inboundRtpSampleReceived(100, for: call)
        monitor.peerConnectionStateDidChange(call, state: .failed)
        wait(for: [restartExpectation], timeout: 1)
        monitor.iceRestartDidComplete(for: call)
        monitor.inboundRtpSampleReceived(101, for: call)
        let settledExpectation = expectation(description: "media verification window expires")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { settledExpectation.fulfill() }
        wait(for: [settledExpectation], timeout: 1)
        XCTAssertEqual(reattachCount, 0)
    }

    private func makeResponse(id: String) -> Message {
        Message().decode(message: "{\"jsonrpc\":\"2.0\",\"id\":\"\(id)\",\"result\":{}}")!
    }

    private func makeActiveCall() -> Call {
        let delegate = NoopCallDelegate()
        let call = Call(
            callId: UUID(),
            remoteSdp: "",
            sessionId: "test-session",
            socket: Socket(),
            delegate: delegate,
            iceServers: []
        )
        call.callState = .ACTIVE
        return call
    }
}

private final class NoopCallDelegate: CallProtocol {
    func callStateUpdated(call: Call) {}
}
