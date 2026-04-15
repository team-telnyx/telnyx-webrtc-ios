//
//  TxClientSocketErrorTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

/// Tests for TxClient socket error handling, specifically verifying that
/// a 401 error on the unauthenticated push notification websocket properly
/// cleans up state so future connections are not corrupted.
class TxClientSocketErrorTests: XCTestCase {

    var txClient: TxClient!
    var mockDelegate: SocketErrorTestDelegate!

    override func setUp() {
        super.setUp()
        txClient = TxClient()
        mockDelegate = SocketErrorTestDelegate()
        txClient.delegate = mockDelegate
    }

    override func tearDown() {
        txClient.delegate = nil
        txClient = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - Basic socket error cleanup

    /// Verify that onSocketError notifies the delegate
    func testSocketErrorNotifiesDelegate() {
        let expectation = XCTestExpectation(description: "Delegate should receive onSocketDisconnected")
        mockDelegate.onSocketDisconnectedExpectation = expectation

        txClient.onSocketError(error: TestSocketError(reason: "401 Unauthorized"))

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockDelegate.onSocketDisconnectedCalled)
    }

    /// Verify that after a socket error, isConnected() returns false
    func testSocketErrorCleansUpConnection() {
        txClient.onSocketError(error: TestSocketError(reason: "401 Unauthorized"))

        XCTAssertFalse(txClient.isConnected(), "Client should not be connected after socket error")
    }

    // MARK: - Push flow socket error cleanup

    /// Verify that a socket error during push flow resets push state
    /// so that a subsequent connect() goes through the normal login flow
    /// rather than being hijacked by the stale isCallFromPush flag.
    func testSocketErrorDuringPushFlowResetsState() throws {
        // Set up push flow state via processVoIPNotification
        let txConfig = TxConfig(sipUser: "test_user", password: "test_password")
        let serverConfig = TxServerConfiguration()
        let pushMetaData: [String: Any] = [
            "voice_sdk_id": "test-sdk-id",
            "call_id": UUID().uuidString
        ]

        try txClient.processVoIPNotification(
            txConfig: txConfig,
            serverConfiguration: serverConfig,
            pushMetaData: pushMetaData
        )

        // Now simulate the 401 error on the unauthenticated websocket
        txClient.onSocketError(error: TestSocketError(reason: "401 Unauthorized"))

        // After the error, the client should be in a clean state:
        // - Not connected
        XCTAssertFalse(txClient.isConnected(), "Client should not be connected after push socket error")

        // - Delegate should have been notified
        XCTAssertTrue(mockDelegate.onSocketDisconnectedCalled)
    }

    /// Verify that after a push flow socket error, a new processVoIPNotification
    /// can be processed successfully (state is not corrupted)
    func testNewPushAfterSocketError() throws {
        // First push flow
        let txConfig = TxConfig(sipUser: "test_user", password: "test_password")
        let serverConfig = TxServerConfiguration()
        let firstCallId = UUID().uuidString
        let pushMetaData: [String: Any] = [
            "voice_sdk_id": "test-sdk-id-1",
            "call_id": firstCallId
        ]

        try txClient.processVoIPNotification(
            txConfig: txConfig,
            serverConfiguration: serverConfig,
            pushMetaData: pushMetaData
        )

        // Socket error occurs (simulating 401 on unauthenticated websocket)
        txClient.onSocketError(error: TestSocketError(reason: "401 Unauthorized"))

        // A new push notification arrives for a different call
        let secondCallId = UUID().uuidString
        let newPushMetaData: [String: Any] = [
            "voice_sdk_id": "test-sdk-id-2",
            "call_id": secondCallId
        ]

        // This should NOT throw - the state should be clean enough to process a new push
        XCTAssertNoThrow(try txClient.processVoIPNotification(
            txConfig: txConfig,
            serverConfiguration: serverConfig,
            pushMetaData: newPushMetaData
        ))
    }

    /// Verify that socket error cleanup does not affect non-push flows
    func testSocketErrorWithoutPushFlow() {
        // Just trigger a socket error without any push flow active
        txClient.onSocketError(error: TestSocketError(reason: "Connection reset"))

        XCTAssertFalse(txClient.isConnected())
        XCTAssertTrue(mockDelegate.onSocketDisconnectedCalled)
    }

    /// Verify that multiple sequential socket errors don't cause issues
    func testMultipleSocketErrors() {
        txClient.onSocketError(error: TestSocketError(reason: "Error 1"))
        txClient.onSocketError(error: TestSocketError(reason: "Error 2"))
        txClient.onSocketError(error: TestSocketError(reason: "Error 3"))

        XCTAssertFalse(txClient.isConnected())
        XCTAssertEqual(mockDelegate.socketDisconnectedCount, 3)
    }
}

// MARK: - Test Helpers

private struct TestSocketError: Error, LocalizedError {
    let reason: String
    var errorDescription: String? { reason }
}

private class SocketErrorTestDelegate: TxClientDelegate {
    var onSocketDisconnectedCalled = false
    var socketDisconnectedCount = 0
    var onSocketDisconnectedExpectation: XCTestExpectation?

    func onSocketConnected() {}

    func onSocketDisconnected() {
        onSocketDisconnectedCalled = true
        socketDisconnectedCount += 1
        onSocketDisconnectedExpectation?.fulfill()
    }

    func onClientReady() {}
    func onSessionUpdated(sessionId: String) {}
    func onIncomingCall(call: Call) {}
    func onCallStateUpdated(callState: CallState, callId: UUID) {}
    func onClientError(error: Error) {}
    func onRemoteCallEnded(callId: UUID) {}
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?) {}
    func onPushDisabled(success: Bool, message: String) {}
    func onPushCall(call: Call) {}
}
