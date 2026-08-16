import XCTest
@testable import TelnyxRTC

final class SignalingHealthMonitorTests: XCTestCase {
    func testPeerAndIceFailuresStartOnlyOneIceRestart() {
        let call = makeActiveCall()
        var restartCount = 0
        var reattachCount = 0
        let monitor = SignalingHealthMonitor(
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in restartCount += 1 },
            requestReattach: { reattachCount += 1 }
        )

        monitor.iceConnectionStateDidChange(call, state: .failed)
        monitor.peerConnectionStateDidChange(call, state: .failed)

        XCTAssertEqual(restartCount, 1)
        XCTAssertEqual(reattachCount, 0)
    }

    func testPeerFailureWithUnavailableSignalingUsesReattach() {
        let call = makeActiveCall()
        var restartCount = 0
        var reattachCount = 0
        let monitor = SignalingHealthMonitor(
            isSignalingAvailable: { false },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in restartCount += 1 },
            requestReattach: { reattachCount += 1 }
        )

        monitor.peerConnectionStateDidChange(call, state: .failed)

        XCTAssertEqual(restartCount, 0)
        XCTAssertEqual(reattachCount, 1)
    }

    func testIceRestartTimeoutFallsBackToReattach() {
        let call = makeActiveCall()
        let reattachExpectation = expectation(description: "ICE restart timeout requests reattach")
        let monitor = SignalingHealthMonitor(
            iceRestartTimeout: 0.01,
            isSignalingAvailable: { true },
            sendSignalingProbe: { "probe-id" },
            startIceRestart: { _ in },
            requestReattach: { reattachExpectation.fulfill() }
        )

        monitor.peerConnectionStateDidChange(call, state: .failed)

        wait(for: [reattachExpectation], timeout: 1)
    }

    func testStaleSignalingDefersIceRestartUntilMatchingProbeResponse() {
        let call = makeActiveCall()
        var restartCount = 0
        var probeCount = 0
        let monitor = SignalingHealthMonitor(
            signalingProbeTimeout: 1,
            recentInboundActivityThreshold: 0.01,
            isSignalingAvailable: { true },
            sendSignalingProbe: {
                probeCount += 1
                return "expected-probe-id"
            },
            startIceRestart: { _ in restartCount += 1 },
            requestReattach: { XCTFail("Should not reattach") }
        )

        // Let the initial freshness window expire before the failure.
        let staleExpectation = expectation(description: "signaling becomes stale")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { staleExpectation.fulfill() }
        wait(for: [staleExpectation], timeout: 1)
        monitor.peerConnectionStateDidChange(call, state: .failed)

        XCTAssertEqual(probeCount, 1)
        XCTAssertEqual(restartCount, 0)

        monitor.signalingMessageReceived(makeResponse(id: "unrelated-id"))
        XCTAssertEqual(restartCount, 0)

        monitor.signalingMessageReceived(makeResponse(id: "expected-probe-id"))
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
            requestReattach: { reattachExpectation.fulfill() }
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
            requestReattach: { XCTFail("Should not reattach before probe timeout") }
        )

        monitor.callStateDidChange(call)

        wait(for: [probeExpectation], timeout: 1)
    }

    func testSuccessfulActiveCallHealthProbeDoesNotRestartICE() {
        let call = makeActiveCall()
        let probeExpectation = expectation(description: "active call sends signaling probe")
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
            requestReattach: { reattachCount += 1 }
        )

        monitor.callStateDidChange(call)
        wait(for: [probeExpectation], timeout: 1)
        monitor.signalingMessageReceived(makeResponse(id: "health-probe-id"))

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
            requestReattach: { reattachExpectation.fulfill() }
        )

        monitor.callStateDidChange(call)

        wait(for: [reattachExpectation], timeout: 1)
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
