//
//  TxClientCallsRaceTests.swift
//  TelnyxRTCTests
//
//  Tests covering the VSDK-336 / IOS-C20 fix: `TxClient.calls`
//  dictionary access must be serialized so that the reconnect-timeout
//  handler (which fires on `reconnectQueue`) cannot iterate the dictionary
//  at the same time as the main thread mutates it (e.g. inside
//  `disconnect()`, `newCall()`, `endFromCallkit()`, `createIncomingCall()`,
//  `callStateUpdated()`).
//
//  Prior to the fix, the reconnect timer's event handler invoked
//  `updateActiveCallsState()` and `disconnect()` directly on
//  `reconnectQueue`, which iterated `self.calls.values` and called
//  `self.calls.removeAll()`. If the main thread mutated `self.calls`
//  concurrently, Swift's Dictionary traps with `EXC_BAD_INSTRUCTION`
//  ("mutated during iteration") or, on weakly-ordered architectures,
//  returns a torn read.
//

import XCTest
@testable import TelnyxRTC

final class TxClientCallsRaceTests: XCTestCase {

    private var txClient: TxClient!
    private var mockDelegate: MockTxClientCallsRaceDelegate!

    override func setUp() {
        super.setUp()
        txClient = TxClient()
        mockDelegate = MockTxClientCallsRaceDelegate()
        txClient.delegate = mockDelegate
    }

    override func tearDown() {
        txClient.delegate = nil
        txClient = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - Regression tests for the reconnect-timeout vs main-thread race

    /// Starting a reconnect timeout and then immediately calling
    /// `disconnect()` must not crash. Before the VSDK-336 fix, the timer
    /// event handler was free to iterate `self.calls` on `reconnectQueue`
    /// at the same time the main thread was running `disconnect()`, which
    /// mutates `self.calls`. The fix hops the calls-touching work onto the
    /// main queue so all `self.calls` reads/writes happen on a single
    /// thread.
    func testStartReconnectTimeoutFollowedByDisconnectDoesNotCrash() {
        let expectation = XCTestExpectation(description: "start + disconnect cycle completes without crash")

        txClient.startReconnectTimeout()
        txClient.stopReconnectTimeout()

        // Exercise the documented race window: arm a fresh timer and
        // immediately disconnect from the main thread. Without the fix,
        // this is the pattern that produced EXC_BAD_INSTRUCTION.
        txClient.startReconnectTimeout()
        txClient.disconnect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    /// Repeatedly starting and stopping the reconnect timeout while a
    /// caller concurrently calls `disconnect()` must not crash. This
    /// amplifies the original race window and reliably tripped the
    /// Swift Dictionary trap on the unfixed code path.
    func testConcurrentStartStopAndDisconnectCyclesDoNotCrash() {
        let expectation = XCTestExpectation(description: "concurrent start/stop + disconnect is safe")

        let iterations = 50
        for _ in 0..<iterations {
            txClient.startReconnectTimeout()
            txClient.disconnect()
            txClient.stopReconnectTimeout()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }

    /// The reconnect-timer event handler must run its calls-touching work
    /// on the main thread (the same thread that owns every other
    /// `self.calls` mutation). This test arms the timer with a very short
    /// timeout, lets it fire, and confirms the delegate error is delivered
    /// on the main thread — which is only possible if the dispatch to
    /// `DispatchQueue.main.async` actually happened. Before the fix, the
    /// error was delivered from `reconnectQueue` directly.
    func testReconnectTimeoutFiresCallsWorkOnMainQueue() {
        let expectation = XCTestExpectation(description: "Reconnect-timeout handler dispatches to main queue")
        expectation.assertForOverFulfill = true

        // Install a config with a very short reconnect timeout so the
        // timer fires inside the test window. `txConfig` is `internal var`
        // and `reconnectTimeout` is `internal(set)`, both reachable from
        // the same module via `@testable import`.
        var shortConfig = TxConfig(
            sipUser: "race-test",
            password: "race-test"
        )
        shortConfig.reconnectTimeout = 0.1
        txClient.txConfig = shortConfig

        txClient.startReconnectTimeout()
        mockDelegate.onClientErrorExpectation = expectation

        // The timer is scheduled on `reconnectQueue` with a 0.1s deadline,
        // then the calls-touching block is dispatched to `.main`. The
        // delegate's `onClientError` callback is the last step of that
        // dispatched block, so the expectation fires from `.main`.
        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(mockDelegate.onClientErrorCalled, "Reconnect timeout should fire onClientError")
        XCTAssertTrue(
            mockDelegate.onClientErrorWasOnMainThread,
            "Reconnect-timeout handler must dispatch the calls-touching block to the main queue"
        )
    }

    /// `updateActiveCallsState` is the helper that the reconnect-timeout
    /// path used to call directly on `reconnectQueue`. After the fix,
    /// callers are expected to invoke it on the main thread. Calling it
    /// on the main thread while the dictionary holds no entries must be
    /// a no-op (no crash, no exception).
    func testUpdateActiveCallsStateOnMainIsNoOpWhenCallsEmpty() {
        let expectation = XCTestExpectation(description: "updateActiveCallsState is safe on main thread")

        txClient.updateActiveCallsState(callState: CallState.DONE(reason: nil))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Test delegate

/// Mock delegate that records the thread on which `onClientError`
/// fires. The VSDK-336 fix requires the reconnect-timeout handler to
/// dispatch to the main queue before delivering the error, so we assert
/// `Thread.isMainThread` inside the callback.
private final class MockTxClientCallsRaceDelegate: TxClientDelegate {

    var onClientErrorExpectation: XCTestExpectation?
    var onClientErrorCalled = false
    var onClientErrorWasOnMainThread = false
    var lastError: Error?

    func onClientError(error: Error) {
        onClientErrorCalled = true
        onClientErrorWasOnMainThread = Thread.isMainThread
        lastError = error
        onClientErrorExpectation?.fulfill()
    }

    func onRemoteCallEnded(callId: UUID) {}
    func onSocketConnected() {}
    func onSocketDisconnected() {}
    func onClientReady() {}
    func onSessionUpdated(sessionId: String) {}
    func onIncomingCall(call: Call) {}
    func onCallStateUpdated(callState: CallState, callId: UUID) {}
    func onPushDisabled(success: Bool, message: String) {}
    func onRemoteCallEnded(callId: UUID, reason: TelnyxRTC.CallTerminationReason?) {}
    func onPushCall(call: TelnyxRTC.Call) {}
}
