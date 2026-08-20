import XCTest
@testable import TelnyxRTC

final class SignalingHealthMonitorTests: XCTestCase {
    func testPeerAndIceFailuresStartOnlyOneIceRestart() {
        let call = makeActiveCall()
        var restartCount = 0
        var reattachCount = 0
        let monitor = SignalingHealthMonitor(
            isSignalingAvailable: { true },
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
            startIceRestart: { _ in },
            requestReattach: { reattachExpectation.fulfill() }
        )

        monitor.peerConnectionStateDidChange(call, state: .failed)

        wait(for: [reattachExpectation], timeout: 1)
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
